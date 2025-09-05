//**********************************************************************************************************************
//
//  BXFileCleanupPool.swift
//	Singleton controller that acts like NSAutoReleasePool for files and folders
//  Copyright ©2025 Peter Baumgartner. All rights reserved.
//
//**********************************************************************************************************************


import Foundation

#if canImport(AppKit)
import AppKit
#endif

#if canImport(UIKit)
import UIKit
#endif


//----------------------------------------------------------------------------------------------------------------------


public class BXFileCleanupPool
{
	/// By default cleanup will be performed just before the app terminates.
	///
	/// If you require y different cleanup time, then set the notificationName before calling BXFileCleanupPool.shared for the first time.
	
	#if os(macOS)
	public static var notificationName:Notification.Name = NSApplication.willTerminateNotification
	#else
	public static var notificationName:Notification.Name = UIApplication.willTerminateNotification
	#endif
	
	/// The singleton instance of this controller
	
	public static let shared = BXFileCleanupPool()
	
	/// The list of files/folders to be deleted
	
	private var urls:[URL] = []
	
	/// Listener for notification
	
	private var observer:Any? = nil
	

//----------------------------------------------------------------------------------------------------------------------


	/// Registers the cleanup pool for the specified notification
	
	private init()
	{
		self.observer = NotificationCenter.default.publisher(for:Self.notificationName).sink
		{
			[weak self] _ in
			self?.cleanup()
		}
	}
	
	/// Adds a URL to the cleanup pool
	
	public func add(_ url:URL?)
	{
		guard let url = url else { return }
		
		synchronized(self)
		{
			self.urls.append(url)
		}
	}
	

//----------------------------------------------------------------------------------------------------------------------


	/// Deletes all file/folder stored in self.urls from the file system
	
	public func cleanup()
	{
		let urls = synchronized(self)
		{
			let urls = self.urls
			self.urls.removeAll()
			return urls
		}
		
		for url in urls
		{
			self.cleanup(url)
		}
	}
	
	/// Deletes the specified file/folder from the file system

	private func cleanup(_ url:URL)
	{
		// Get rid of an existing file or folder. Please note that we are not doing this via NSFileManager (which
		// takes forever and is synchronous), but via NSTask an rm, which is asynchronous. The benefit is that we
		// return immediately, and the app can be terminated, while the rm task continues to run until done.

		let path = url.path
		Process.launchedProcess(launchPath:"/bin/rm",arguments:["-fr",path])
	}
}


//----------------------------------------------------------------------------------------------------------------------
