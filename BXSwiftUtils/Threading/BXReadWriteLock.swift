//
//  ReadWriteLock.swift
//  mimoLive
//
//  Created by Stefan Fochler on 10.01.18.
//  Copyright © 2018 Boinx Software Ltd. All rights reserved.
//

import Foundation

/**
 A read-write lock that allows parallel read operations happening exclusively with serial write opertations.
 The benefit of using an RW Lock is that mutliple read operations from concurrent threads do not block each other.
 
 It is the programmer's responsibility to not modify the protected resource within read blocks!
 
 Both read and write operations may return data or throw exceptions which will be simply passed on to the calling code.
 */
public class BXReadWriteLock
{
	private let concurrentQueue: DispatchQueue
	private let queueKey = DispatchSpecificKey<Void>()
	
	public init(label: String)
    {
		self.concurrentQueue = DispatchQueue(label: label, attributes: .concurrent)
		self.concurrentQueue.setSpecific(key: self.queueKey, value: ())
	}

    /// Whether or not the executing code is already running on the internal queue
	private var isOnQueue: Bool
    {
		return DispatchQueue.getSpecific(key: self.queueKey) != nil
	}
	
	/**
     Schedules a reader block that will not modify the protected resource and wait for its completion.
     
     Before the block executes, all writing blocks that have already been scheduled will have finished and no new writing
     blocks will be started before this reading block finishes.
     
     Since there can be an arbitrary number of concurrent reads, nesting `read` calls is safe as long as the threadpool
     has threads available, so recusrive calls of undetermined depth still have to be avoided.
     
     - Parameter closure: A block is *not* allowed to modify the resource protected by this lock.
     
     - Returns: The result of executing `closure`.
	*/
	public func read<T>(_ closure: () throws -> T) rethrows -> T
    {
		// Prevent deadlocks caused by scheduling a read block from within a write block
		if self.isOnQueue
        {
			return try closure()
		}
		
		return try self.concurrentQueue.sync
        {
			return try closure()
		}
	}
	
	/**
     Schedule a writer block that will modify the protected resource and wait for its completion.
     
     Before the block executes, all reading blocks that have already been scheduled will have finished and no new reading
     blocks will be started before this writing block finishes.
     
     This function is reentrant in the sense that the following will work correctly and *not* deadlock:
     
     ````
     lock.write {
         // (1): Must not change the current queue here
         lock.write {
             // ...
         }
         lock.read {
             // (2): Reading during a write is also ok if the code is running on the correct internal queue
         }
         // ...
     }
     ````
     
     Note: This is only true if the operations in (2) did not change the queue the second `write` is executed on. For
     example the following code would still deadlock, because the call at (2) would fail to recognize that the write lock
     on `lockA` is alredy acquired.
     
     ````
     lockA.write {
     lockB.write {
     lockA.write { } // (3): Deadlock here
     }
     }
     ````
     
     - Parameter closure: A block is allowed to modify the resource protected by this lock.
	*/
	public func write<T>(_ closure: () throws -> T) rethrows -> T
    {
		// Prevent deadlocks caused by scheduling a write block within another write block
		if self.isOnQueue
        {
			return try closure()
		}
		
		return try self.concurrentQueue.sync(flags: .barrier)
        {
			return try closure()
		}
	}
}
