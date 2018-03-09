//**********************************************************************************************************************
//
//  Synchronized.swift
//	Simulates the @synchronized directive of Objective-C
//  Copyright ©2016 Peter Baumgartner. All rights reserved.
//
//**********************************************************************************************************************


import Foundation


//----------------------------------------------------------------------------------------------------------------------


/**

This global functions simulates the @synchronized feature of Objective-C. Use just like in Objective-C,
but without the @ character:

		synchronized(self)
		{
		   ...
		}

- Parameter lock: The object that is used for locking
- Parameter closure: The closure that is executed when the lock is acquired

*/

public func synchronized(_ lock: AnyObject, _ closure: ()->() )
{
    objc_sync_enter(lock)
    defer { objc_sync_exit(lock) }

    closure()
}


/**

This global functions simulates the @synchronized feature of Objective-C. This variant takes a block that
can throw an error:

		synchronized(self)
		{
		   ...
		}
		
- Parameter lock: The object that is used for locking
- Parameter closure: The closure that is executed when the lock is acquired

*/

public func synchronized(_ lock: AnyObject, _ closure:() throws->() ) rethrows
{
    objc_sync_enter(lock)
    defer { objc_sync_exit(lock) }

    try closure()
}


/**

This global functions simulates the @synchronized feature of Objective-C. Use just like in Objective-C,
but without the @ character. The main difference here is, that the block returns something. This is useful
for implementing getter methods:

		synchronized(self)
		{
		   return _someUnsafeProperty
		}

- Parameter lock: The object that is used for locking
- Parameter closure: The closure that is executed when the lock is acquired
- Returns: The return value of the block is returned to the caller

*/

public func synchronized<T>(_ lock: AnyObject, _ closure: ()->T ) -> T
{
    objc_sync_enter(lock)
    defer { objc_sync_exit(lock) }

    let result = closure()
	return result
}


//----------------------------------------------------------------------------------------------------------------------
