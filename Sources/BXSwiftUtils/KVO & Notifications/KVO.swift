//**********************************************************************************************************************
//
//  KVO.swift
//	Lightweight wrapper class that provides closure based API around KVO
//  Copyright ©2016-2022 Peter Baumgartner. All rights reserved.
//
//**********************************************************************************************************************


import Foundation


//----------------------------------------------------------------------------------------------------------------------


// ATTENTION
// ---------
//
// For many years NSObject's KVO exhibited nasty behavior of throwing exceptions (and thus crashing the application)
// when KVO observers were not properly removed before objects are deallocated. An example exception is:
//
// 		*** Terminating app due to uncaught exception 'NSInternalInconsistencyException', reason:
// 		'An instance 0x1005bf3a0 of class Foo was deallocated while key value observers were still
// 		registered with it. Current observation info: <NSKeyValueObservationInfo 0x102804ac0> ( ... )'
//
// To avoid the crashes caused by the exception we added some code to the KVO wrapper class, that provided automatic
// (just-in-time) tear down of observers just before objects are deallocated. This mechanism is based on notifications
// being sent from the objects deinit method, and KVO wrappers reacting to these notifications.
//
// While it worked and got rid of the crashes, this strategy doesn't scale well. It exhibits O(n^2) complexity, slowing
// large object graphs to a crawl, so in 2022 it became apparent that a new strategy was needed.
//
// After some research with a sample project, I could no longer reproduce any exceptions and crashes - which puzzled me
// quite a bit. Some more googling revealed the following link that explains, that Apple removed the nasty exceptions
// starting with macOS 10.13 and iOS 11.
//
//		https://fpotter.org/posts/when-is-kvo-unregistration-automatic
//
// So going forward, the safety code (based on notifications and auto-removal of observers) is no longer necessary -
// we can now safely remove the expensive, performance killing code, without risking new crashes. For documentation
// purposes the code is not completely removed, but commented out for future reference.


//----------------------------------------------------------------------------------------------------------------------


/// Lightweight wrapper class that provides closure based API around KVO. Instances of this class can be attached
/// to other classes. When the instances are deallocated, the KVO is automatically unregistered.

public class KVO : NSObject
{
    public private(set) weak var observedObject: NSObject?
    public let keyPath: String
    private let closure: (Any?,Any?)->()
//	private var isActive = false


//----------------------------------------------------------------------------------------------------------------------


	/// Create a new KVO helper, observing the property `keypath` of `object`. When it changes, the closure is called.
	/// - parameter object: The root object that is being observed.
	/// - parameter keyPath: The String based keypath to the property that is observed.
	/// - parameter options: Valid options are .initial, .old, and .new.
	/// - parameter closure: This closure (with old and new value) will be called when the observed property changes.
    /// - parameter oldValue: The old value, if `options` contains `.old`.
    /// - parameter newValue: The old value, if `options` contains `.new`.
	/// - returns: KVO wrapper object, which should be retained as long as you wish the observing to be active.

    public init(object: NSObject, keyPath: String, options: NSKeyValueObservingOptions = [], _ closure:@escaping (_ oldValue: Any?, _ newValue: Any?)->())
	{
        self.observedObject = object
        self.keyPath = keyPath
        self.closure = closure
		super.init()
  
        // Add the observer
        
        object.addObserver(
            self,
            forKeyPath: keyPath,
            options: options,
            context: nil)
        
//        self.isActive = true
		
//		 Gather all objects in the keypath, starting with inObject			// Safety behavior removed,
//																			// because no longer needed
//		let keys = keyPath.components(separatedBy:".").dropLast()			// (see comments at top)
//		var objectsInKeypath: [NSObject] = [object]
//		var nextObject: NSObject? = object
//
//		for key in keys
//		{
//			nextObject = nextObject?.value(forKey:key) as? NSObject
//
//			if nextObject == nil || NSIsControllerMarker(nextObject)
//			{
//				break
//			}
//
//            objectsInKeypath += nextObject
//		}
//
//		// If any object in the keypath dies, then automatically remove the observer again
//
//		for object in objectsInKeypath
//		{
//			NotificationCenter.default.addObserver(
//				self,
//				selector: #selector(KVO.handleInvalidate(notification:)),
//				name: KVO.invalidateNotification,
//				object: object)
//		}
    }


	/// The KVO is automatically removed when getting rid of the helper.
	
    deinit
	{
		observedObject?.removeObserver(self, forKeyPath:keyPath)
		
//		self.invalidate(for:observedObject)								// Safety behavior removed (see comments at top)
//		NotificationCenter.default.removeObserver(self)
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


	/// Notification name that must be sent when objects are dying.
	
//	private static let invalidateNotification = NSNotification.Name("invalidate")
	
	/// Send out a notification letting KVO observers know that this object is about to disappear. Receivers
	/// of this notification should remove their KVO observer, or they risk crashing due to an exception.
	
	@objc public class func invalidate(for object:NSObject)
	{
//		NotificationCenter.default.post(						// Safety behavior removed (see comments at top)
//			name:KVO.invalidateNotification,
//			object:object)
	}
	
	/// Called in response to KVO.invalidateNotification. Take the object reference from the notification itself.
	/// This is much more reliable that trying to get the object reference from self.observedObject - as it is
	/// already nilled out at the time the deinit of this object is called.
	
//	@objc private func handleInvalidate(notification: NSNotification)
//	{
//        let object = self.observedObject ?? (notification.object as? NSObject)
//		self.invalidate(for: object)
//	}


	/// Removes the KVO observer again
	
//	private func invalidate(for inObject:NSObject?)
//	{
//		synchronized(self)
//		{
//            if let object = inObject, self.isActive
//            {
//				object.removeObserver(self, forKeyPath:keyPath)
//				self.isActive = false
// 			}
//		}
//	}
}


//----------------------------------------------------------------------------------------------------------------------


// MARK: -
	
// Objective C API that allows nicer setup for observations with or without options

extension KVO
{
    @objc public static func observe(_ object:NSObject, onKeyPath keyPath:String, usingBlock block:@escaping ()->Void) -> KVO
    {
        return KVO(object:object, keyPath:keyPath)
        {
			_,_ in block()
        }
    }
    
    @objc public static func observe(_ object:NSObject, onKeyPath keyPath:String, options:NSKeyValueObservingOptions, usingBlock block: @escaping (_ oldValue:Any?, _ newValue:Any?)->Void) -> KVO
    {
        return KVO(object:object, keyPath:keyPath, options:options, block)
    }
}


//----------------------------------------------------------------------------------------------------------------------


// MARK: -
	
// Importing AppKit is needed for the NSIsControllerMarker() function. For iOS, provide our own implementation of this function.

#if os(macOS)

import AppKit

#elseif os(iOS)

public let NSNoSelectionMarker = "NSNoSelectionMarker" as AnyObject
public let NSMultipleValuesMarker = "NSMultipleValuesMarker" as AnyObject
public let NSNotApplicableMarker = "NSNotApplicableMarker" as AnyObject

public func NSIsControllerMarker(_ value:Any?) -> Bool
{
    let object = value as AnyObject
    return object === NSNoSelectionMarker || object === NSMultipleValuesMarker || object === NSNotApplicableMarker
}

public func NSIsMultipleValuesMarker(_ value:Any?) -> Bool
{
    let object = value as AnyObject
    return object === NSMultipleValuesMarker
}

public func NSIsNoSelectionMarker(_ value:Any?) -> Bool
{
    let object = value as AnyObject
    return object === NSNoSelectionMarker
}

public func NSIsNotApplicableMarker(_ value:Any?) -> Bool
{
    let object = value as AnyObject
    return object === NSNotApplicableMarker
}

#endif


//----------------------------------------------------------------------------------------------------------------------
