//**********************************************************************************************************************
//
//  DispatchQueue+Throttle.swift
//	Adds coalecing and throttling to GCD queues
//  Copyright ©2018 Peter Baumgartner. All rights reserved.
//
//**********************************************************************************************************************

import Foundation


//----------------------------------------------------------------------------------------------------------------------


extension DispatchQueue
{
	// Scheduled worker blocks, grouped by identifier string
	
	private static var coalescedWorkItems: [String:DispatchWorkItem] = [:]
	
	// Last time a worker block was executed for a given identifier string
	
	private static var throttledWorkTimes: [String:CFAbsoluteTime] = [:]

	// A lock that protects against threading issue when accessing the two shared dictionaries above
	
	private static var lock:BXReadWriteLock = BXReadWriteLock(label:"com.boinx.BXSwiftUtils.DispatchQueue.lock")


//----------------------------------------------------------------------------------------------------------------------


	// MARK: -
	

	/**
	
	Coalesces all blocks with the same identifier to the end of the specified interval. The block
	will only be executed once, when no calls occur for at least the specified interval time.
	````
	DispatchQueue.main.coalesce("performExpensiveWork",interval:0.1)
	{
	    performExpensiveWork()
	}
	````
	- parameter identifier: A unique identifier string that is used to coalesce block invocations together
	- parameter interval: The time in seconds before the block is first executed
	- parameter block: The closure (block) to be executed

	*/
	
	public func coalesce(_ identifier: String, interval: CFTimeInterval=0.0, block: @escaping ()->Void)
	{
		DispatchQueue.lock.read()
		{
			let oldItem = DispatchQueue.coalescedWorkItems[identifier]
			oldItem?.cancel()
		}
		
		let newItem = DispatchWorkItem()
		{
            block()
 			DispatchQueue.lock.write() { DispatchQueue.coalescedWorkItems[identifier] = nil }
 		}
		
		DispatchQueue.lock.write()
		{
			DispatchQueue.coalescedWorkItems[identifier] = newItem
		}
		
        self.asyncAfter(deadline: .now()+interval, execute: newItem)
	}
	
	
//----------------------------------------------------------------------------------------------------------------------


	/**
	
	Throttles all blocks with the same identifier to be called only once (at the beginnging) of the specified
	interval. All remaining calls with the same identifier will be suppressed until the interval has elapsed.
	````
	DispatchQueue.main.throttle("performExpensiveWork",interval:0.1)
	{
	    performExpensiveWork()
	}
	````
	- parameter identifier: A unique identifier string that is used to group block invocations together
	- parameter interval: The interval duration (in seconds) between block invocations
	- parameter block: The closure (block) to be executed

	*/

	public func throttle(_ identifier: String, interval: CFTimeInterval=0.0, block: @escaping ()->Void)
	{
		var shouldExecuteBlock = false
		
		DispatchQueue.lock.read()
		{
			let lastTime = DispatchQueue.throttledWorkTimes[identifier] ?? 0.0
			let now = CFAbsoluteTimeGetCurrent()
			shouldExecuteBlock = now >= lastTime+interval
		}
		
		if shouldExecuteBlock
		{
			let item = DispatchWorkItem()
			{
				let time = CFAbsoluteTimeGetCurrent()
				block()
				DispatchQueue.lock.write() { DispatchQueue.throttledWorkTimes[identifier] = time }
			}

			self.async(execute:item)
		}
	}


//----------------------------------------------------------------------------------------------------------------------


	// MARK: -
	
	/// Cancels any coalesced work that was scheduled with the coalesce(_:interval:block:) method.
	/// - parameter identifier: A unique string that identifies the scheduled work that should be canceled

	public static func cancelCoalescedWork(withIdentifier identifier: String)
	{
		DispatchQueue.lock.write()
		{
			let item = self.coalescedWorkItems[identifier]
			item?.cancel()
			self.coalescedWorkItems[identifier] = nil
		}
	}
	

	/// Cancels all scheduled coalesced work with identifiers that have a matching prefix. This is useful
	/// for cleaning up pending work for a controller that is about to be deallocated. It is obviously the
	/// responsibility of the caller to give all this work identifiers with matching prefixes.
	
	public static func cancelCoalescedWork(withPrefix prefix: String)
	{
		DispatchQueue.lock.write()
		{
			for (identifier,item) in self.coalescedWorkItems
			{
				if identifier.hasPrefix(prefix)
				{
					item.cancel()
					self.coalescedWorkItems[identifier] = nil
				}
			}
		}
	}

	/// Cancels all scheduled coalesced work that was scheduled with the coalesce(_:interval:block:) method.
	
	public static func cancelAllCoalescedWork()
	{
		DispatchQueue.lock.write()
		{
			for (_,item) in self.coalescedWorkItems
			{
				item.cancel()
			}
			
			self.coalescedWorkItems = [:]
		}
	}

}


//----------------------------------------------------------------------------------------------------------------------




