//
//  SynchronizedTests.swift
//  BXSwiftUtils
//
//  Copyright © 2026 Boinx Software Ltd. & Imagine GbR. All rights reserved.
//

import Testing
import Foundation
@testable import BXSwiftUtils


//----------------------------------------------------------------------------------------------------------------------


/// `synchronized(lock) { }` is `objc_sync_enter`/`exit` around a closure, which means it inherits the recursive
/// behavior of an Objective-C `@synchronized` block - and that the lock has to be released even when the closure
/// throws, which is the case a `defer` exists for and nothing had checked.

@Suite("Synchronized")

struct SynchronizedTests
{
	/// A bare identity token - `synchronized` locks on the OBJECT, so this deliberately has no state. That is also
	/// what makes it Sendable: there is nothing to race on, and without the conformance every closure below reports
	/// a non-Sendable capture.

	final class Lock : Sendable {}


	/// Starts a worker at the quality of service the TEST itself runs at.
	///
	/// Swift Testing runs test bodies at user-initiated QoS while `Thread.detachNewThread` starts at default, so a
	/// test that then waits on such a thread is a high priority thread blocked on a low priority one. The runtime
	/// reports that as a priority inversion, and under load it is a real stall rather than only a warning.

	static func startWorker(_ body:@escaping @Sendable () -> Void)
	{
		let thread = Thread(block:body)
		thread.qualityOfService = .userInitiated
		thread.start()
	}


	/// Waits on a semaphore WITHOUT occupying a cooperative thread.
	///
	/// A test body is a task on the cooperative pool, which has about as many threads as the machine has cores -
	/// blocking one with `semaphore.wait()` takes it out of circulation for every other suite running at the same
	/// time. Awaiting a continuation resumed from a dispatch queue keeps the pool free, and asks for the same QoS
	/// the workers run at so neither side is waiting on something slower than itself.

	static func wait(on semaphore:DispatchSemaphore, for seconds:Double) async -> DispatchTimeoutResult
	{
		await withCheckedContinuation
		{
			(continuation:CheckedContinuation<DispatchTimeoutResult,Never>) in

			DispatchQueue.global(qos:.userInitiated).async
			{
				continuation.resume(returning:semaphore.wait(timeout:.now() + seconds))
			}
		}
	}

	struct Failure : Error {}


	@Test("The closure runs and its value is returned")

	func testRunsAndReturns()
	{
		let lock = Lock()
		var count = 0

		synchronized(lock)
		{
			count += 1
		}

		#expect(count == 1)
		#expect(synchronized(lock) { 42 } == 42)
		#expect(synchronized(lock) { "text" } == "text")
	}


	/// An error is rethrown rather than swallowed - and, more importantly, the LOCK IS RELEASED on the way out. A
	/// `defer` is what makes that true, and without it every subsequent use of the same lock would deadlock.

	@Test("A throwing closure rethrows and still releases the lock")

	func testThrowingReleasesTheLock()
	{
		let lock = Lock()

		#expect(throws:Failure.self)
		{
			try synchronized(lock)
			{
				throw Failure()
			}
		}

		// The real assertion: the lock is usable again. Without the defer this line would never return.

		#expect(synchronized(lock) { 1 } == 1)
	}


	/// Recursive by nature, because objc_sync counts entries per thread. Worth pinning: it is what lets a locked
	/// method call another locked method on the same object, and it is not a property of every lock.

	@Test("Taking the same lock again on the same thread is allowed")

	func testRecursion()
	{
		let lock = Lock()

		let result = synchronized(lock)
		{
			synchronized(lock)
			{
				synchronized(lock) { 3 }
			}
		}

		#expect(result == 3)
	}


	/// The lock is any object, and two different objects are two different locks - so nesting them cannot deadlock,
	/// however they are ordered.

	@Test("Different objects are different locks")

	func testDistinctLocks()
	{
		let first = Lock()
		let second = Lock()

		let result = synchronized(first) { synchronized(second) { 1 } } + synchronized(second) { synchronized(first) { 1 } }

		#expect(result == 2)
	}


	/// It really does exclude another thread, which is the only thing it is for. Proved by rendezvous rather than by
	/// timing: the holder waits to be released, and a second thread must not get in while it does.

	@Test("A second thread is excluded while the lock is held")

	func testMutualExclusion() async
	{
		let lock = Lock()
		let entered = DispatchSemaphore(value:0)
		let release = DispatchSemaphore(value:0)
		let secondEntered = DispatchSemaphore(value:0)

		// Take the lock and hold it until released

		Self.startWorker
		{
			synchronized(lock)
			{
				entered.signal()
				release.wait()
			}
		}

		let held = await Self.wait(on:entered, for:2.0)

		#expect(held == .success, "the first thread never took the lock")

		// Ask a second thread for the same lock while the first still holds it

		Self.startWorker
		{
			synchronized(lock) { }
			secondEntered.signal()
		}

		let blocked = await Self.wait(on:secondEntered, for:0.25)

		#expect(blocked == .timedOut, "a second thread entered while the lock was held")

		// ...and it gets in once the lock is free, which shows it was blocked rather than never scheduled

		release.signal()

		let admitted = await Self.wait(on:secondEntered, for:2.0)

		#expect(admitted == .success, "the second thread never got in at all")
	}
}


//----------------------------------------------------------------------------------------------------------------------
