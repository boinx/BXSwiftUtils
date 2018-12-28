//**********************************************************************************************************************
//
//  NotificationCenter+AutoRemove.swift
//	Adds a new method to add an observer for notifications
//  Copyright ©2018 Peter Baumgartner. All rights reserved.
//
//**********************************************************************************************************************


import Foundation


//----------------------------------------------------------------------------------------------------------------------


extension NotificationCenter
{
	/// This wrapper stores the token that was returned by the NotificationCenter.
	/// When a wrapper is deallocated, the observer is automatically removed again.

	public class AutoRemovingWrapper
	{
		private var token: Any
		
		internal init(_ token: Any)
		{
			self.token = token
		}
		
		deinit
		{
			NotificationCenter.default.removeObserver(token)
		}
	}

	/// An alternate way to add an observer for notifications
	///
	/// This method has a slightly different signature than the original one provided by Apple. The main difference
	/// is that the returned AutoRemovingWrapper will automatically remove the observer again once it is deallocated.
	///
	/// - parameter name: The name of the notification
	/// - parameter object: Provide the object argument if you want the observation to be further constrained
	/// - parameter queue: The block will be executed on this queue
	/// - parameter block: The block to be called when the notification fires
	/// - returns: A wrapper that automatically removes the observer once the wrapper is deallocated

    public func addAutoRemovingObserver(forName name: NSNotification.Name?, object: Any?, queue: OperationQueue?, using block: @escaping (Notification)->Void) -> AutoRemovingWrapper
    {
     	let token = self.addObserver(forName:name, object:object, queue:queue, using:block)
     	return AutoRemovingWrapper(token)
    }
}


//----------------------------------------------------------------------------------------------------------------------


