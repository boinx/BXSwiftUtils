//
//  BXConcurrencyLimiterTests.swift
//  BXSwiftUtils
//
//  Copyright © 2026 Boinx Software Ltd. & Imagine GbR. All rights reserved.
//

import Testing
import Foundation
@testable import BXSwiftUtils


//----------------------------------------------------------------------------------------------------------------------


/// BXConcurrencyLimiter makes two promises, and a test suite that only covers one of them is worse than useless.
///
/// The ceiling is the obvious one: no more than `limit` operations run at once. The floor matters just as much - a
/// limiter that quietly serialized everything would satisfy every ceiling assertion perfectly while destroying the
/// throughput it exists to manage. So both directions are asserted, and the floor is measured across code that never
/// suspends: awaits let callers interleave for reasons that have nothing to do with this class (actor reentrancy,
/// the generic executor), so an overlap observed only at suspension points would prove nothing about the limiter.
///
/// Every test that could deadlock on a regression carries its own bounded watchdog, because a broken limiter fails by
/// hanging - and a hang that reports a failed expectation is far more useful than one that wedges the whole run.
/// (.timeLimit would be the natural tool, but it needs macOS 13 and this test target still deploys to macOS 12.)
///
/// SERIALIZED because these tests deliberately saturate a limiter and one of them abandons a stuck task on purpose.

@Suite("BXConcurrencyLimiter", .serialized)

struct BXConcurrencyLimiterTests
{
	private enum TestError : Error
	{
		case expected
	}


//----------------------------------------------------------------------------------------------------------------------


	// MARK: - Helpers

	/// Counts how many operations are inside the limiter at any moment, and remembers the high water mark

	private actor ConcurrencyGauge
	{
		private var currentCount = 0
		private(set) var peakCount = 0


		func enter()
		{
			self.currentCount += 1
			self.peakCount = max(self.peakCount, self.currentCount)
		}


		func leave()
		{
			self.currentCount -= 1
		}
	}


	/// Counts overlapping operations WITHOUT suspending, so it can observe synchronous stretches of work.
	///
	/// ConcurrencyGauge above is an actor, so every enter()/leave() is an await - and an await is a suspension point
	/// at which callers interleave regardless of how many slots the limiter handed out. Measuring real overlap means
	/// measuring it across code that never suspends, which rules out an actor and calls for a plain lock.

	private final class SynchronousGauge : @unchecked Sendable
	{
		private let lock = NSLock()
		private var currentCount = 0
		private var peak = 0


		func enter()
		{
			self.lock.lock()
			defer { self.lock.unlock() }

			self.currentCount += 1
			self.peak = max(self.peak, self.currentCount)
		}


		func leave()
		{
			self.lock.lock()
			defer { self.lock.unlock() }

			self.currentCount -= 1
		}


		var peakCount:Int
		{
			self.lock.lock()
			defer { self.lock.unlock() }

			return self.peak
		}
	}


	/// A one-shot flag that can be set from another task

	private actor Gate
	{
		private(set) var isSignaled = false


		func signal()
		{
			self.isSignaled = true
		}
	}


	/// Runs the operation in its own task and waits up to `seconds` for it to finish.
	///
	/// Returns false on timeout, leaving the stuck task suspended rather than hanging the suite - which is exactly
	/// what a limiter that lost a slot would do.

	private func didComplete(within seconds:Double, _ operation:@escaping @Sendable () async -> Void) async -> Bool
	{
		let gate = Gate()

		Task
		{
			await operation()
			await gate.signal()
		}

		let deadline = Date(timeIntervalSinceNow:seconds)

		while Date() < deadline
		{
			if await gate.isSignaled { return true }
			try? await Task.sleep(nanoseconds:10_000_000)
		}

		return await gate.isSignaled
	}


//----------------------------------------------------------------------------------------------------------------------


	// MARK: - Tests

	/// The ceiling: with a limit of 3, a burst of 60 operations must never put more than 3 inside at once

	@Test("Never lets more operations run than the limit allows")

	func neverExceedsLimit() async
	{
		let limit = 3
		let limiter = BXConcurrencyLimiter(limit:limit)
		let gauge = ConcurrencyGauge()

		await withTaskGroup(of:Void.self)
		{
			group in

			for _ in 0 ..< 60
			{
				group.addTask
				{
					await limiter.perform
					{
						await gauge.enter()
						await Task.yield()
						await gauge.leave()
					}
				}
			}
		}

		let peak = await gauge.peakCount
		#expect(peak <= limit, "\(peak) operations ran at once, but the limit was \(limit)")
	}


	/// The floor: `limit` operations must be able to run at the SAME time, including across code that does not
	/// suspend.
	///
	/// The payload is a short synchronous busy stretch rather than a Task.sleep on purpose. Sleeping callers
	/// interleave whether or not the limiter hands out more than one slot, so a "concurrency" test built out of
	/// awaits would pass even against an implementation that serialized everything. Real payloads look like the
	/// synchronous one anyway - ImageIO thumbnail decoding, the case this class was written for, never suspends.
	/// Bounded either way: ~150ms overlapped, ~300ms serialized, never a hang.
	///
	/// A limit of 2 keeps this honest on a two-core CI machine.

	@Test("Lets `limit` operations run truly concurrently")

	func runsOperationsConcurrently() async
	{
		let limit = 2
		let limiter = BXConcurrencyLimiter(limit:limit)
		let gauge = SynchronousGauge()

		await withTaskGroup(of:Void.self)
		{
			group in

			for _ in 0 ..< limit
			{
				group.addTask
				{
					await limiter.perform
					{
						gauge.enter()

						// Deliberately synchronous - a Task.sleep here would hand the actor back and hide the bug

						let deadline = Date(timeIntervalSinceNow:0.15)
						while Date() < deadline { }

						gauge.leave()
					}
				}
			}
		}

		let peak = gauge.peakCount
		#expect(peak == limit, "only \(peak) of \(limit) operations ever overlapped, so perform() is serializing")
	}


	/// A thrown error must not swallow the slot - otherwise the limiter silently strangles itself over time

	@Test("Gives its slot back when the operation throws")

	func releasesSlotWhenOperationThrows() async
	{
		let limiter = BXConcurrencyLimiter(limit:1)
		let counter = SynchronousGauge()

		// The whole sequence has to sit inside the watchdog, not just the final call: with a limit of 1 the very
		// first leaked slot stalls the SECOND throwing operation, long before we would get to a closing assertion.

		let didFinish = await self.didComplete(within:5.0)
		{
			for _ in 0 ..< 10
			{
				do
				{
					try await limiter.perform { throw TestError.expected }
				}
				catch
				{
					// expected
				}
			}

			await limiter.perform
			{
				counter.enter()
				counter.leave()
			}
		}

		#expect(didFinish, "the limiter lost its only slot to a thrown error")
		#expect(counter.peakCount == 1)
	}


	/// The result is the caller's, not the limiter's - perform() must pass value and error through untouched

	@Test("Propagates the operation's return value and error")

	func propagatesResultAndError() async
	{
		let limiter = BXConcurrencyLimiter(limit:2)

		let value = await limiter.perform { 42 }
		#expect(value == 42)

		await #expect(throws:TestError.expected)
		{
			try await limiter.perform { throw TestError.expected }
		}
	}


	/// A nonsensical limit must be clamped, not turned into a limiter that never runs anything

	@Test("Clamps a limit below 1 instead of deadlocking", arguments:[0,-5])

	func clampsInvalidLimit(_ limit:Int) async
	{
		let limiter = BXConcurrencyLimiter(limit:limit)
		let gauge = ConcurrencyGauge()

		let didRun = await self.didComplete(within:5.0)
		{
			for _ in 0 ..< 5
			{
				await limiter.perform
				{
					await gauge.enter()
					await gauge.leave()
				}
			}
		}

		#expect(didRun, "a limit of \(limit) was not clamped, so nothing ever ran")
	}
}


//----------------------------------------------------------------------------------------------------------------------
