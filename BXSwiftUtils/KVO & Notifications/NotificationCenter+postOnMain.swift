//**********************************************************************************************************************
//
//  NotificationCenter+postOnMain.swift
//	Posts a notification on the main thread to make sure that calling thread is not blocked
//  Copyright ©2021 Peter Baumgartner. All rights reserved.
//
//**********************************************************************************************************************


import Foundation


//----------------------------------------------------------------------------------------------------------------------


extension NotificationCenter
{
	/// Posts a notification on the main thread in an async fashion, so that the calling thread is never blocked by waiting for receivers to execute their blocks.
	
    public func postOnMainAsync(name:Notification.Name, object:Any?)
    {
		DispatchQueue.main.async
		{
			self.post(name:name, object:object)
		}
    }
    
	/// Posts a notification on the main thread. If the caller is on the main thread, all receivers will execute their blocks synchronously.
	/// If the caller is on a background thread, then all receiver blocks are executed asynchronously and the called is not blocked
	
    public func postOnMain(name:Notification.Name, object:Any?)
    {
		if Thread.isMainThread
		{
			self.post(name:name, object:object)					// Sync (caller is blocked)
		}
		else
		{
			self.postOnMainAsync(name:name, object:object)		// Async (caller is not blocked)
		}
    }
}


//----------------------------------------------------------------------------------------------------------------------


