//**********************************************************************************************************************
//
//  KVO.swift
//	Small helper class that provides closure based API around KVO
//  Copyright ©2016 Peter Baumgartner. All rights reserved.
//
//**********************************************************************************************************************

// TODO: Comment
#if os(macOS)
import AppKit
#endif

import Foundation


//----------------------------------------------------------------------------------------------------------------------


/// Small helper class that provides closure based API around KVO. Instances of this class can be attached
/// to other classes. When the instances are deallocated, the KVO is automatically unregistered.

public class KVO : NSObject
{
    public/*(get)*/ private(set) weak var observedObject:NSObject?
    public let keyPath:String
    private let closure:(Any?,Any?)->()
	private var isActive = false


//----------------------------------------------------------------------------------------------------------------------


	// MARK: -
	
	/// Create a new KVO helper, observing the property `keypath` of `object`. When it changes,
	/// the closure `callback' is called.
	
    public init(object inObject: NSObject, keyPath inKeyPath: String, options: NSKeyValueObservingOptions = [.initial, .new], _ inClosure:@escaping (Any?,Any?)->())
	{
        self.observedObject = inObject
        self.keyPath = inKeyPath
        self.closure = inClosure
		super.init()
		
		// Gather all objects in the keypath, starting with inObject
		
		let keys = keyPath.components(separatedBy:".").dropLast()
		var objectsInKeypath: [NSObject] = [inObject]
		var nextObject: NSObject? = inObject
		
		for key in keys
		{
			nextObject = nextObject?.value(forKey:key) as? NSObject
			
			if nextObject == nil || NSIsControllerMarker(nextObject)
			{
				break
			}
   
            objectsInKeypath += nextObject
		}
		
		// If any object in the keypath dies, then automatically remove the observer again
		
		for object in objectsInKeypath
		{
			NotificationCenter.default.addObserver(
				self,
				selector: #selector(KVO.handleInvalidate(notification:)),
				name: KVO.invalidateNotification,
				object: object)
		}
  
        // Add the observer
        
        inObject.addObserver(
            self,
            forKeyPath: keyPath,
            options: options,
            context: nil)
        
        self.isActive = true
    }


//----------------------------------------------------------------------------------------------------------------------


	/// The KVO is automatically removed when getting rid of the helper.
	
    deinit
	{
		self.invalidate(for:observedObject)
		NotificationCenter.default.removeObserver(self)
	}


//----------------------------------------------------------------------------------------------------------------------


	/// When the property at `keypath` has changed, the closure is executed.

    override open func observeValue(
		forKeyPath keyPath:String?,
        of object:Any?,
        change:[NSKeyValueChangeKey:Any]?,
        context:UnsafeMutableRawPointer?)
	{
		var oldValue:Any? = nil
		var newValue:Any? = nil
		
		if let change = change
		{
			oldValue = change[NSKeyValueChangeKey.oldKey]
			newValue = change[NSKeyValueChangeKey.newKey]
		}
		
		self.closure(oldValue,newValue)
    }


//----------------------------------------------------------------------------------------------------------------------


	// MARK: -
	
	/// Notification name that must be sent when objects are dying.
	
	private static let invalidateNotification = NSNotification.Name("invalidate")
	
	/// Send out a notification letting KVO observers know that this object is about to disappear. Receivers
	/// of this notification should remove their KVO observer, or they risk crashing due to an exception.
	
	public class func invalidate(for object:NSObject)
	{
		NotificationCenter.default.post(
			name:KVO.invalidateNotification,
			object:object)
	}
	
	/// Called in response to KVO.invalidateNotification. Take the object reference from the notification itself.
	/// This is much more reliable that trying to get the object reference from self.observedObject - as it is
	/// already nilled out at the time the deinit of this object is called.
	
	@objc private func handleInvalidate(notification: NSNotification)
	{
        let object = self.observedObject ?? (notification.object as? NSObject)
		self.invalidate(for: object)
	}


	/// Removes the KVO observer again.
	
	private func invalidate(for inObject:NSObject?)
	{
        synchronized(self)
        {
            if self.isActive
            {
                if let object = inObject
                {
                    object.removeObserver(self, forKeyPath:keyPath)
                    self.isActive = false
                }
            }
        }
	}
}

