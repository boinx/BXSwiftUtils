//**********************************************************************************************************************
//
//  DispatchQueue+Throttle.swift
//  Adds coalecing and throttling to GCD queues
//  Copyright ©2018 Peter Baumgartner & Stefan Fochler. All rights reserved.
//
//**********************************************************************************************************************

import Foundation


//----------------------------------------------------------------------------------------------------------------------

extension DispatchQueue
{
    // Scheduled worker blocks, grouped by identifier string
    
    private static var coalescedWork: [String: (index: Int, item: DispatchWorkItem)] = [:]
    private static var workItemIndex = BXAtomic<Int>(0)
    
    // Last time a worker block was executed for a given identifier string
    
    private static var throttledWork: [String: WorkStatus] = [:]

    private enum WorkStatus
    {
        case dispatched
        case executed(CFAbsoluteTime)
    }
	
    // A lock that protects against threading issue when accessing the two shared dictionaries above
    
    private static var lock = BXReadWriteLock(label: "com.boinx.BXSwiftUtils.DispatchQueue.lock")


//----------------------------------------------------------------------------------------------------------------------


    // MARK: -
    
    /**
     Debounces all blocks with the same identifier to the end of the specified interval. The block
     will only be executed once, when no calls occur for at least the specified interval time.
     
     ## Example
     ```
     DispatchQueue.main.debounce("performExpensiveWork", interval: 0.1)
     {
         performExpensiveWork()
     }
     ```
     
     - parameter identifier: An identifier string that is used to coalesce block invocations together.
     - parameter interval: The time in seconds before the block is first executed.
     - parameter block: The closure (block) to be executed.
    */
    
    public func debounce(_ identifier: String, interval: CFTimeInterval = 0.0, block: @escaping () -> Void)
    {
        let index = DispatchQueue.workItemIndex.increment()
        
        let newItem = DispatchWorkItem()
        {
            block()
            
            DispatchQueue.lock.write()
            {
                if let storedIndex = DispatchQueue.coalescedWork[identifier]?.index, storedIndex == index
                {
                    DispatchQueue.coalescedWork[identifier] = nil
                }
            }
         }
        
        DispatchQueue.lock.write()
        {
            let oldItem = DispatchQueue.coalescedWork[identifier]?.item
            oldItem?.cancel()
            DispatchQueue.coalescedWork[identifier] = (index: index, item: newItem)
        }
        
        self.asyncAfter(deadline: .now() + interval, execute: newItem)
    }
    
    
    /// Alias of `debounce(_:interval:block:)`
	
    public func coalesce(_ identifier: String, interval: CFTimeInterval = 0.0, block: @escaping () -> Void)
    {
        self.debounce(identifier, interval: interval, block: block)
    }


//----------------------------------------------------------------------------------------------------------------------


    /**
     Throttles all blocks with the same identifier to be called only once (at the beginnging) of the specified
     interval. All remaining calls with the same identifier will be suppressed until the interval has elapsed.
     
     ## Example
     ```
     DispatchQueue.main.throttle("performExpensiveWork",interval:0.1)
     {
         performExpensiveWork()
     }
     ```
     
     - parameter identifier: An identifier string that is used to group block invocations together.
     - parameter interval: The interval duration (in seconds) between block invocations.
     - parameter block: The closure (block) to be executed.
    */

    public func throttle(_ identifier: String, interval: CFTimeInterval = 0.0, block: @escaping () -> Void)
    {
        let shouldDispatch: Bool = DispatchQueue.lock.write()
        {
        	let distantPast = -Double.greatestFiniteMagnitude
            let status = DispatchQueue.throttledWork[identifier] ?? .executed(distantPast)
        	let dispatchTime = CFAbsoluteTimeGetCurrent()
            
            if case .executed(let lastTime) = status, dispatchTime >= (lastTime + interval)
            {
                DispatchQueue.throttledWork[identifier] = .dispatched
                return true
            }
			
            return false
        }
  
        guard shouldDispatch else { return }
        
        self.async
        {
            let executionTime = CFAbsoluteTimeGetCurrent()
            DispatchQueue.lock.write() { DispatchQueue.throttledWork[identifier] = .executed(executionTime) }
            block()
        }
    }


//----------------------------------------------------------------------------------------------------------------------


     /**
     Throttles the execution of the specified block to match the performance capabilities of the current machine,
     i.e. it doesn't schedule more blocks that can be handled at a given time.
     
     It will only schedule another block after the previous one has finished executing.
     However, a final execution after the specified timeout is always guarranteed.
     This makes `dynamicThrottle` the best choice for performing UI work based on events that might occur more
     frequently than the machine is capable of handling.
	
     ## Example
     
         let semaphore = DispatchSemaphore(value: 1)
         serialQueue.dynamicThrottle(with:semaphore)
         {
             performExpensiveWork()
         }

     
     The following diagram depicts the scheduling and execution of tasks 1-4 using `dynamicThrottle`. Only tasks 1 and 4
     are being executed, while tasks 2 and 3 were cancelled because a new task was spawned and delayed.
     
         task1 -> |>- - - - - - - - - ->|
         task2 ->    |.(*)...X
         task3 ->            |.(*)...X
         task4 ->                    |.(*)......|>- - - - - - - - - ->|
     
         |       = task is scheduled
         |>      = task is scheduled & starts execution
         ->|     = task finishes execution
         .(*)... = delayed by `finalExecutionTimeout`
         X       = delayed task is cancelled by following task
     
	 - parameter semaphore: A DispatchSemaphore that controls that the next block will only be schedules after the previous one has finished executing.
                            **Important**: Must be initialized to value 1.
     - parameter delay: The delay to wait before the next block is allowed to be scheduled for execution.
     - parameter finalExecutionTimeout: The timeout to wait before for the final execution.
     - parameter block: The closure (block) to be executed.
    */

   public func dynamicThrottle(with semaphore: DispatchSemaphore, delay: CFTimeInterval = 0.01, finalExecutionTimeout: CFTimeInterval = 0.5, block: @escaping () -> Void)
    {
    	// If the semaphore is currently free, then schedule another execution of the block. After the block
    	// has finished executing, wait a little bit before signaling the semaphore again. This helps to
    	// reduce memory pressure.
		let identifier = String(semaphore.hash)

		if semaphore.wait(timeout:.now()) == .success
		{
			DispatchQueue.cancelCoalescedWork(withIdentifier: identifier)	// Cancel previous final execution
			
			self.async														// Instead schedule "immediate" execution
			{
				block()
				
				DispatchQueue.main.asyncAfter(deadline:.now() + delay)		// Reducing memory pressure doesn't
				{															// work reliably without this delay
					semaphore.signal()
				}
			}
		}
		
		// If the semaphore is not free, it means that we swallowed the above request. In this case schedule a
		// final (coalesced) execution with a rather long timeout, so that a final execution will always happen.
		
		else
		{
			self.coalesce(identifier, interval: finalExecutionTimeout)
			{
				block()
			}
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
            let work = self.coalescedWork[identifier]
            work?.item.cancel()
            self.coalescedWork[identifier] = nil
        }
    }
    

    /// Cancels all scheduled coalesced work with identifiers that have a matching prefix. This is useful
    /// for cleaning up pending work for a controller that is about to be deallocated. It is obviously the
    /// responsibility of the caller to give all this work identifiers with matching prefixes.
    
    public static func cancelCoalescedWork(withPrefix prefix: String)
    {
        DispatchQueue.lock.write()
        {
            for (identifier, work) in self.coalescedWork
            {
                if identifier.hasPrefix(prefix)
                {
                    work.item.cancel()
                    self.coalescedWork[identifier] = nil
                }
            }
        }
    }

    /// Cancels all scheduled coalesced work that was scheduled with the coalesce(_:interval:block:) method.
    
    public static func cancelAllCoalescedWork()
    {
        DispatchQueue.lock.write()
        {
            for work in self.coalescedWork.values
            {
                work.item.cancel()
            }
            
            self.coalescedWork = [:]
        }
    }

}


//----------------------------------------------------------------------------------------------------------------------

