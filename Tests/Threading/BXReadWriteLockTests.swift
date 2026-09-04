//
//  BXReadWriteLockTests.swift
//  BXSwiftUtils
//
//  Copyright © 2026 Boinx Software Ltd. & Imagine GbR. All rights reserved.
//

import Testing
import Foundation
@testable import BXSwiftUtils


//----------------------------------------------------------------------------------------------------------------------


/// A read-write lock is worth having only if reads really do run CONCURRENTLY and writes really do exclude them, so
/// those two facts are the whole product - and neither was covered. The original suite asserted that `read { 1 }`
/// returns 1 and that `write { 1 }` returns 1, and its one real test was DISABLED by an early `return`, left in place
/// with a note that it "sometimes fails with a timeout".
///
/// It failed because it was built out of sleeps: a hundred readers napping for random intervals against a writer
/// napping for 50ms, the whole thing under a 10 second expectation. Everything here is built out of RENDEZVOUS
/// instead - semaphores that can only be satisfied if the lock behaves as claimed - so a passing run proves something
/// and a broken lock fails in bounded time rather than eventually.

/// SERIALIZED, and it has to be. Every test here deliberately blocks threads, and one of them abandons a deadlocked
/// thread on purpose - running them concurrently with each other multiplies that by seven and takes the test process
/// down. Each passes in isolation and the suite crashed only in parallel, which is what that failure looks like.

@Suite("BXReadWriteLock", .serialized)

struct BXReadWriteLockTests
{
	/// Runs the body on its own thread and reports whether it finished in time.
	///
	/// ASYNC, and that is not cosmetic. Swift Testing runs test functions as tasks on the cooperative pool, which has
	/// roughly as many threads as the machine has cores - so a test that blocks one with a semaphore takes a thread
	/// out of circulation, and a handful at once wedges every other suite in the bundle. An earlier version of this
	/// file did exactly that and hung the entire run. Awaiting a continuation releases the thread instead.
	///
	/// The body runs on a dedicated Thread rather than a dispatch queue for the same class of reason: a body that
	/// deadlocks never returns, and a queue block that never returns holds a pool thread for the rest of the process.
	/// A leaked Thread costs a stack and nothing that anyone else is waiting on.

	static func completes(within seconds:Double = 2.0, _ body:@escaping @Sendable () -> Void) async -> Bool
	{
		await withCheckedContinuation
		{
			continuation in

			let finished = DispatchSemaphore(value:0)

			// Both sides run at the QoS the test itself does. Thread.detachNewThread starts at DEFAULT, and a test
			// body - which Swift Testing runs at user-initiated - waiting on that is a priority inversion: a high
			// priority thread blocked on a low priority one. Note the queue's own qos argument does not settle it,
			// because libdispatch OVERRIDES a block upward to the QoS of whoever submitted it - so the waiter is
			// user-initiated whatever this asks for, and it is the worker that has to be raised to match.
			//
			// One inversion remains that no test can remove: BXReadWriteLock creates its queue with no QoS, so a
			// raised thread blocking in `concurrentQueue.sync` is waiting on an unspecified-QoS queue. Fixing that
			// means giving the production queue a QoS, which is a decision about the lock rather than about a test.

			let worker = Thread
			{
				body()
				finished.signal()
			}

			worker.qualityOfService = .userInitiated
			worker.start()

			DispatchQueue.global(qos:.userInitiated).async
			{
				continuation.resume(returning:finished.wait(timeout:.now() + seconds) == .success)
			}
		}
	}


	final class Counter : @unchecked Sendable
	{
		private var value = 0
		private let lock = NSLock()

		func increment() { self.lock.lock() ; self.value += 1 ; self.lock.unlock() }
		var count:Int { self.lock.lock() ; defer { self.lock.unlock() } ; return self.value }
	}


//----------------------------------------------------------------------------------------------------------------------


	// MARK: - Passing values and errors through


	@Test("A closure's result is returned")

	func testReturnValues()
	{
		let lock = BXReadWriteLock(label:"test")

		#expect(lock.read { 1 } == 1)
		#expect(lock.write { "two" } == "two")
	}


	/// Both methods are `rethrows`, so an error from the closure reaches the caller unchanged rather than being
	/// swallowed by the queue. Untested before, and it is the reason neither signature is simply `-> T`.

	@Test("An error thrown inside the lock is rethrown")

	func testRethrows() async
	{
		struct Failure : Error, Equatable { let id:Int }

		let lock = BXReadWriteLock(label:"test")

		#expect(throws:Failure(id:1)) { try lock.read { throw Failure(id:1) } }
		#expect(throws:Failure(id:2)) { try lock.write { throw Failure(id:2) } }

		// ...and the lock is still usable afterwards, so the error did not leave it held

		let usable = await Self.completes { lock.write { } }

		#expect(usable, "the lock stayed held after a throwing closure")
	}


	@Test("A nested call still returns its value")

	func testNestedReturnValue()
	{
		let lock = BXReadWriteLock(label:"test")

		let result = lock.write { lock.read { 42 } }

		#expect(result == 42)
	}


//----------------------------------------------------------------------------------------------------------------------


	// MARK: - What the lock is for


	/// THE WHOLE POINT OF THE CLASS. Readers must be able to run at the same time - if they were serialised, this
	/// would just be a serial queue with extra steps.
	///
	/// Proved by RENDEZVOUS rather than by timing: each reader announces its arrival and then waits to be released,
	/// and nobody is released until every one of them has arrived. That can only complete if all of them are inside
	/// the lock at once. If reads were exclusive the second would never enter, nothing would ever be released, and
	/// the arrangement times out - a failed test rather than a hung run.

	@Test("Reads run concurrently")

	func testReadsAreConcurrent() async
	{
		let finished = await Self.completes(within:5.0)
		{
			let lock = BXReadWriteLock(label:"test")
			let readers = 3

			let arrived = DispatchSemaphore(value:0)
			let released = DispatchSemaphore(value:0)
			let done = DispatchSemaphore(value:0)

			// The coordinator lives INSIDE the timed body, or the readers would be waiting for a release that only
			// happens after the measurement has already given up

			let coordinator = Thread
			{
				for _ in 0 ..< readers { arrived.wait() }
				for _ in 0 ..< readers { released.signal() }
			}

			coordinator.qualityOfService = .userInitiated
			coordinator.start()

			for _ in 0 ..< readers
			{
				let reader = Thread
				{
					lock.read
					{
						arrived.signal()
						released.wait()
					}

					done.signal()
				}

				reader.qualityOfService = .userInitiated
				reader.start()
			}

			for _ in 0 ..< readers { done.wait() }
		}

		#expect(finished, "the readers could not all be inside the lock at once, so reads are not concurrent")
	}


	/// ...and the other half: a write EXCLUDES readers while it runs. Asserted from inside the write, so the reader is
	/// asked to proceed at a moment when it provably cannot, and then again afterwards to show it was merely blocked.

	@Test("A write excludes readers while it runs")

	func testWriteExcludesReaders() async
	{
		let outcome = Counter()

		let finished = await Self.completes(within:5.0)
		{
			let lock = BXReadWriteLock(label:"test")
			let readerFinished = DispatchSemaphore(value:0)

			lock.write
			{
				let reader = Thread
				{
					lock.read { }
					readerFinished.signal()
				}

				reader.qualityOfService = .userInitiated
				reader.start()

				if readerFinished.wait(timeout:.now() + 0.25) == .timedOut
				{
					outcome.increment()
				}
			}

			if readerFinished.wait(timeout:.now() + 2.0) == .success
			{
				outcome.increment()
			}
		}

		#expect(finished, "the scenario did not complete")
		#expect(outcome.count == 2, "a reader entered during the write, or never ran at all")
	}


//----------------------------------------------------------------------------------------------------------------------


	// MARK: - Re-entrancy


	/// The `isOnQueue` check is what makes nesting safe, and every one of these would DEADLOCK without it. They are
	/// documented in the class comment and were never tested, though the check is a single line a refactor could drop.

	@Test("Nested calls on the same lock do not deadlock", arguments:
	[
		"write-in-write", "read-in-write", "read-in-read", "write-in-read",
	])

	func testNestingDoesNotDeadlock(_ shape:String) async
	{
		let finished = await Self.completes
		{
			let lock = BXReadWriteLock(label:"test")

			switch shape
			{
				case "write-in-write":	lock.write { lock.write { } }
				case "read-in-write":	lock.write { lock.read { } }
				case "read-in-read":	lock.read { lock.read { } }
				default:				lock.read { lock.write { } }
			}
		}

		#expect(finished, "\(shape) deadlocked")
	}


	/// NOT PINNED BY A TEST, and the attempt is worth recording. `isOnQueue` asks only whether the code is on THIS
	/// lock's queue, so interleaving two locks defeats it: by the time an inner `lockA.write` runs, the thread is on
	/// lockB's queue, lockA no longer recognises it as re-entrant, and it waits for a barrier it is itself holding.
	/// That is case (3) in the class documentation, and it still deadlocks exactly as described.
	///
	/// A test for it was written and REMOVED. Proving a deadlock means abandoning a thread inside a dispatch barrier,
	/// and a queue whose barrier block never returns cannot be torn down - the whole test process crashed at the end
	/// of the run, not while the test itself was executing, which took a while to attribute. The behavior is
	/// documented here instead, following the same rule as every other trap in this codebase whose failure mode takes
	/// the process with it.
}


//----------------------------------------------------------------------------------------------------------------------
