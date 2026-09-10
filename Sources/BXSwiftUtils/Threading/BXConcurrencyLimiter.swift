//**********************************************************************************************************************
//
//  BXConcurrencyLimiter.swift
//	Limits how many async operations are allowed to run at the same time
//  Copyright ©2026 Peter Baumgartner. All rights reserved.
//
//**********************************************************************************************************************


import Foundation


//----------------------------------------------------------------------------------------------------------------------


/// BXConcurrencyLimiter caps the number of async operations that may run concurrently.
///
/// Please note that this is NOT a DispatchSemaphore. A task that has to wait for a free slot merely _suspends_ - it
/// never blocks its thread. That distinction is the entire point of this class: the Swift concurrency cooperative
/// thread pool only has `activeProcessorCount` threads, so blocking even a handful of them (e.g. with a
/// DispatchSemaphore, or with a synchronous system API that waits on one internally) starves the pool and deadlocks
/// every other `await` in the process.
///
/// Also note that this limits _concurrency_ (how many run at once), unlike BXValueThrottler or DispatchQueue.throttle,
/// which limit _frequency_ (how often something runs).
///
///		let limiter = BXConcurrencyLimiter(limit:4)
///		…
///		let image = try await limiter.perform { try await loadThumbnail(for:url) }

public actor BXConcurrencyLimiter
{
	/// The maximum number of operations that are allowed to run at the same time
	
	private let limit:Int
	
	/// The number of operations that are currently running
	
	private var runningCount = 0
	
	/// Operations that are waiting for a free slot, in FIFO order
	
	private var waiting:[CheckedContinuation<Void,Never>] = []
	
	
//----------------------------------------------------------------------------------------------------------------------


	// MARK: - Lifetime
	
	/// Creates a new limiter that lets at most `limit` operations run concurrently
	
	public init(limit:Int)
	{
		self.limit = max(1,limit)
	}
	
	
//----------------------------------------------------------------------------------------------------------------------


	// MARK: - Performing Work
	
	/// Runs the supplied closure as soon as a slot is free, suspending (never blocking) until then.
	///
	/// Only the bookkeeping in acquire() and release() needs to be actor isolated, so perform() itself is
	/// nonisolated and no caller has to hop onto the limiter just to be let through. The closure runs on the
	/// generic executor either way, as nonisolated async functions always do.
	
	public nonisolated func perform<T>(_ work:() async throws -> T) async rethrows -> T
	{
		await self.acquire()
		
		// The slot must be given back no matter how we leave - including when the closure throws or the surrounding
		// task is cancelled. defer cannot await, so hop back onto the actor in a detached-style Task. That Task does
		// not inherit cancellation, so the slot is always released.
		
		defer { Task { await self.release() } }
		
		return try await work()
	}
	
	
	/// Waits for a free slot and claims it
	
	private func acquire() async
	{
		if self.runningCount < self.limit
		{
			self.runningCount += 1
			return
		}
		
		await withCheckedContinuation
		{
			continuation in
			self.waiting += continuation
		}
	}
	
	
	/// Gives a slot back, handing it directly to the longest waiting operation if there is one
	
	private func release()
	{
		if !self.waiting.isEmpty
		{
			// Hand the slot over without decrementing, as the resumed operation takes it over as is

			let continuation = self.waiting.removeFirst()
			continuation.resume()
		}
		else
		{
			self.runningCount -= 1
		}
	}
}


//----------------------------------------------------------------------------------------------------------------------
