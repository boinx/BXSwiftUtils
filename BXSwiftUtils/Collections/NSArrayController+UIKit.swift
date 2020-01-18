//**********************************************************************************************************************
//
//  NSArrayController+UIKit.swift
//	Missing NSArrayController class for UIKit
//  Copyright ©2017 Peter Baumgartner. All rights reserved.
//
//**********************************************************************************************************************


import Foundation


//----------------------------------------------------------------------------------------------------------------------


// Since NSArrayController is part of AppKit and not Foundation (how stupid is that?) we need to supply
// this class ourself for iOS projects. Many thanks to Cocotron for details on the implementation:
// https://github.com/toaster/hg-cocotron/blob/master/AppKit/NSController/NSArrayController.m

#if os(iOS)

//----------------------------------------------------------------------------------------------------------------------


public struct NSBindingName : RawRepresentable,Equatable,Hashable
{
	public let rawValue:String
	
    public init(_ rawValue:String)
    {
		self.rawValue = rawValue
	}
	
    public init(rawValue:String)
    {
		self.rawValue = rawValue
	}

    public var hashValue:Int
    {
		return self.rawValue.hashValue
    }

    public static func ==(lhs:NSBindingName,rhs:NSBindingName) -> Bool
    {
		return lhs.rawValue == rhs.rawValue
    }
	
    public static let contentArray = NSBindingName("contentArray")
}


//----------------------------------------------------------------------------------------------------------------------


// This is a stripped down version of NSArrayController, that contains just the features that are needed in FotoMagico

open class NSArrayController : NSObject
{


//----------------------------------------------------------------------------------------------------------------------


	// Create the controller and a selection proxy object
	
	override public init()
	{
		super.init()
		_selection = _NSSelectionProxy(controller:self)
	}
	
	
//----------------------------------------------------------------------------------------------------------------------


	// Define KVO dependencies
	
	override open class func keyPathsForValuesAffectingValue(forKey key:String) -> Set<String>
	{
		if key == "contentArray"
		{
			return Set(["content"])
		}
		else if key == "selection"
		{
			return Set(["content","contentArray","selectionIndexes"])
		}
		else if key == "selectionIndex"
		{
			return Set(["content","contentArray","selectionIndexes","selection"])
		}
		else if key == "selectedObjects"
		{
			return Set(["content","contentArray","selectionIndexes","selection"])
		}
		else if key == "canRemove"
		{
			return Set(["selectionIndexes"])
		}
		else if key == "canSelectNext"
		{
			return Set(["selectionIndexes"])
		}
		else if key == "canSelectPrevious"
		{
			return Set(["selectionIndexes"])
		}
		
		return super.keyPathsForValuesAffectingValue(forKey:key)
	}

	
//----------------------------------------------------------------------------------------------------------------------


	// MARK:
	// MARK: Content
	
	
	/// This property can be used for programmatically setting the controllers 'contentArray'
	
	@objc dynamic open var content:Any?
	{
		set
		{
			if let array = newValue as? [Any]
			{
				self.contentArray = NSMutableArray(array:array)
				self.rearrangeObjects()
			}
		}
		
		get
		{
			return self.contentArray
		}
	}
	
	/// The type of objects stored in the array
	
	open var objectClass:Swift.AnyClass!


//----------------------------------------------------------------------------------------------------------------------


    open func bind(_ binding:NSBindingName,to observable:Any,withKeyPath keyPath:String,options:[String:Any]?=nil)
	{
		if binding.rawValue == "contentArray"
		{
			if let object = observable as? NSObject
			{
				self.bindingObject = object
				self.bindingKeyPath = keyPath
				
				self.updateContentArray()
				
				let keypathComponents = keyPath.components(separatedBy:".")
				let keyPathPrefix = keypathComponents.first!
//				let keyPathSuffix = keypathComponents.last!
                
				self.contentArrayObserver = KVO(object:object,keyPath:keyPathPrefix,options:[.initial,.new])
				{
					[weak self] _,_ in
					self?.updateContentArray()
				}
			}
		}
	}


	open func unbind(_ binding:NSBindingName)
	{
		if binding.rawValue == "contentArray"
		{
			self.contentArray = nil
			self.contentArrayObserver = nil
		}
	}
	
	
	internal weak var bindingObject:NSObject? = nil
	
	internal var bindingKeyPath:String? = nil

	internal var contentArrayObserver:KVO? = nil


//----------------------------------------------------------------------------------------------------------------------


	// In case of @unionOfArrays, we'll need to observe each subarray
	
	internal func observeUnionOfArrays()
	{
		guard let object = self.bindingObject else { return }
		guard let keyPath = bindingKeyPath else { return }
		guard keyPath.contains("@unionOfArrays") else { return }
		
		let keypathComponents = keyPath.components(separatedBy:".")
		guard let keyPathPrefix = keypathComponents.first else { return }
		guard let keyPathSuffix = keypathComponents.last else { return }
		guard let subObjects = object.value(forKeyPath:keyPathPrefix) as? [NSObject] else { return }

		self.unionOfArrayObservers = []

		for subObject in subObjects
		{
			self.unionOfArrayObservers += KVO(object:subObject,keyPath:keyPathSuffix,options:.new)
			{
				[weak self] _,_ in
				self?.updateContentArray()
			}
		}
	}
	
	/// An list of KVO observers that watch the subarrays for changes
	
	internal var unionOfArrayObservers:[KVO] = []


//----------------------------------------------------------------------------------------------------------------------


	/// This method is called whenever KVO detects a change in the data model. It then copies the array from
	/// the data model to the private property 'contentArray', which will in turn to copied to 'arrangedObjects'.
	
	internal func updateContentArray()
	{
		if let object = self.bindingObject, let keyPath = bindingKeyPath
		{
			let swiftArray = object.value(forKeyPath:keyPath)	// Returns Swift array type [Any]
			let array = swiftArray as! NSArray					// which can only be converted to NSArray, not NSMutableArray!
			self.contentArray = NSMutableArray(array:array)		// so converting to NSMutableArray takes an extra step!
		
			self.rearrangeObjects()
		}
	}


	/// The contentArray represents the "input" side of the NSArrayController
	
	internal var contentArray:NSMutableArray? = nil
	
	
//----------------------------------------------------------------------------------------------------------------------


 	// MARK:
	// MARK: Arranging
	
	
	open func rearrangeObjects()
	{
		if let objects = self.contentArray as? [Any]
		{
			// Save current selection
			
			let savedSelectedObjects = self.selectedObjects ?? []
			let selection = (_selection as? _NSSelectionProxy)

			// Prepare for changing the array
			
			self.willChangeValue(forKey:"arrangedObjects")
			selection?.controllerWillChangeObjects()
			
			// Update the arrangedObjects array
			
			self._arrangedObjects = NSMutableArray(array:self.arrange(objects))
			
			// In case of @unionOfArrays, we'll need to observe each subarray
			
			self.observeUnionOfArrays()
			
			// Restore the selection
			
			if preservesSelection
			{
				self.setSelectedObjects(savedSelectedObjects)
			}
			
			// Notify others that arrangedObjects has changed
			
			selection?.controllerDidChangeObjects()
			self.didChangeValue(forKey:"arrangedObjects")
		}
	}
	
	
	/// This method filters and sorts the contentArray to produce the output, which is stored in arrangedObjects.
	/// This class doesn't do any filtering or sorting, but subclasses can override this method.
	
	open func arrange(_ objects:[Any]) -> [Any]
	{
		return objects
	}
	
	
	/// arrangedObjects is the "output" of the NSArrayController.
	
    @objc open dynamic var arrangedObjects:NSMutableArray
	{
		return _arrangedObjects
	}
	
	
	/// Internal storage for the arrangedObjects
	
	internal var _arrangedObjects = NSMutableArray()

	
//----------------------------------------------------------------------------------------------------------------------


 	// MARK:
	// MARK: Selecting
	
	
	open var avoidsEmptySelection = false
	open var preservesSelection = true
	open var alwaysUsesMultipleValuesMarker = false


//----------------------------------------------------------------------------------------------------------------------


	/// The index of the first selected object. If nothing is selected -1 will be returned.
	
    open var selectionIndex:Int
	{
		set
		{
			self.setSelectionIndexes(IndexSet(integer:newValue))
		}
		
		get
		{
			return self._selectionIndexes.first ?? -1
		}
	}
	
	
//----------------------------------------------------------------------------------------------------------------------


    @discardableResult open func setSelectionIndexes(_ inIndexes:IndexSet) -> Bool
	{
		var indexes = inIndexes
		
		// If we're supposed to avoid an empty selection, then simply select the first object.
		
		if self.avoidsEmptySelection && indexes.count==0 && _arrangedObjects.count>0
		{
			indexes = IndexSet(integer:0)
		}
		
		// Bail out if the selection doesn't change.
		
		if _selectionIndexes == indexes
		{
			return false
		}
		
		let selection = (_selection as? _NSSelectionProxy)
		
		self.willChangeValue(forKey:"selectionIndexes")
		selection?.controllerWillChangeObjects()
		self._selectionIndexes = indexes
		selection?.controllerDidChangeObjects()
		self.didChangeValue(forKey:"selectionIndexes")
		
		return true
	}
	
    @objc open dynamic var selectionIndexes:IndexSet
	{
		return self._selectionIndexes
	}
	
    internal var _selectionIndexes:IndexSet = IndexSet()
	
	
//----------------------------------------------------------------------------------------------------------------------


	// Sets the selectedObjects
	
    @discardableResult open func setSelectedObjects(_ selectedObjects:[Any]) -> Bool
	{
		var indexes = IndexSet()
		
		for object in selectedObjects
		{
			let i = _arrangedObjects.indexOfObjectIdentical(to:object)
			
			if i != NSNotFound
			{
				indexes.insert(i)
			}
		}
		
		return self.setSelectionIndexes(indexes)
	}
	
	// Returns the selectedObjects. Please note that this algorithm tries to avoid exceptions if _selectionIndexes
	// is out-dated and contains indexes that are not available in the _arrangedObjects array anymore.
	
    @objc open dynamic var selectedObjects:[Any]!
	{
//		return _arrangedObjects.objects(at:_selectionIndexes)

//		return _selectionIndexes.map
//		{
//			let i = $0
//			return i<_arrangedObjects.count ? _arrangedObjects[i] : 0
//		}

		var objects:[Any] = []
		
		for i in _selectionIndexes
		{
			if i<_arrangedObjects.count
			{
				objects += _arrangedObjects[i]
			}
		}
		
		return objects
	}


//----------------------------------------------------------------------------------------------------------------------


	@discardableResult open func addSelectedObjects(_ objects:[Any]) -> Bool
	{
		guard objects.count > 0 else { return false }
		let selection = (_selection as? _NSSelectionProxy)

		self.willChangeValue(forKey:"selectionIndexes")
		selection?.controllerWillChangeObjects()

		for object in objects
		{
			let i = _arrangedObjects.indexOfObjectIdentical(to:object)
			
			if i != NSNotFound
			{
				self._selectionIndexes.insert(i)
			}
		}
		
		selection?.controllerDidChangeObjects()
		self.didChangeValue(forKey:"selectionIndexes")
		
		return objects.count > 0
	}
	
	
	@discardableResult open func removeSelectedObjects(_ objects:[Any]) -> Bool
	{
		guard objects.count > 0 else { return false }
		let selection = (_selection as? _NSSelectionProxy)
		var didRemove = false
		
		self.willChangeValue(forKey:"selectionIndexes")
		selection?.controllerWillChangeObjects()

		for object in objects
		{
			let i = _arrangedObjects.indexOfObjectIdentical(to:object)
			
			if i != NSNotFound
			{
				self._selectionIndexes.remove(i)
				didRemove = true
			}
		}
		
		selection?.controllerDidChangeObjects()
		self.didChangeValue(forKey:"selectionIndexes")
		
		return didRemove
	}


//----------------------------------------------------------------------------------------------------------------------


	/// The selection proxy. Send KVC messages to this proxy to target all selectedObjects
	
    @objc open dynamic var selection:Any
	{
		return _selection
	}
	
	internal var _selection:Any = 0
}


//----------------------------------------------------------------------------------------------------------------------


// MARK:

internal struct _NSObserverInfo
{
	weak var observer:NSObject? = nil
	var keyPath:String
	var options:NSKeyValueObservingOptions
	var context:UnsafeMutableRawPointer? = nil
}


//----------------------------------------------------------------------------------------------------------------------


// MARK:

/// Helper class that acts as a proxy for the selection of the NSArrayController. You can bind against this object.

internal class _NSSelectionProxy : NSObject
{
	internal weak var arrayController:NSArrayController?
	internal var observers:[_NSObserverInfo] = []
	internal var objectProxies:[_NSObjectProxy] = []

	
	init(controller:NSArrayController)
	{
		arrayController = controller
		super.init()
	}

	
	// Sets the value on all selectedObjects of the owning controller.
	
	override func setValue(_ value:Any?,forKeyPath keyPath:String)
	{
		guard let selectedObjects = arrayController?.selectedObjects as? [NSObject] else { return }
		
		for object in selectedObjects
		{
			object.setValue(value,forKeyPath:keyPath)
		}
	}
	
	
	override func setValue(_ value:Any?,forKey key:String)
	{
		guard let selectedObjects = arrayController?.selectedObjects as? [NSObject] else { return }
		
		for object in selectedObjects
		{
			object.setValue(value,forKey:key)
		}
	}
	
	
	/// Returns the (common) value of all selected objects. If there is no common value then NSMultipleValuesMarker
	/// will be returned instead.
	
	override func value(forKeyPath keyPath:String) -> Any?
	{
		guard let controller = arrayController
		else { return NSNoSelectionMarker }

		guard let selectedObjects = controller.selectedObjects as? [NSObject]
		else { return NSNoSelectionMarker }
		
		let alwaysUsesMultipleValuesMarker = controller.alwaysUsesMultipleValuesMarker
		var uniqueValue:Any? = nil
		
		for object in selectedObjects
		{
			let value = object.value(forKeyPath:keyPath)
			
			if uniqueValue != nil && value != nil
			{
				if alwaysUsesMultipleValuesMarker
				{
					return NSMultipleValuesMarker
				}
				else if !isEqual(uniqueValue!,value!)
				{
					return NSMultipleValuesMarker
				}
			}
			else
			{
				uniqueValue = value
			}
		}
		
		return uniqueValue
	}


	override func value(forKey key:String) -> Any?
	{
		guard let controller = arrayController
		else { return NSNoSelectionMarker }

		guard let selectedObjects = controller.selectedObjects as? [NSObject]
		else { return NSNoSelectionMarker }
		
		let alwaysUsesMultipleValuesMarker = controller.alwaysUsesMultipleValuesMarker
		var uniqueValue:Any? = nil
		
		for object in selectedObjects
		{
			let value = object.value(forKey:key)
			
			if uniqueValue != nil && value != nil
			{
				if alwaysUsesMultipleValuesMarker
				{
					return NSMultipleValuesMarker
				}
				else if !isEqual(uniqueValue!,value!)
				{
					return NSMultipleValuesMarker
				}
			}
			else
			{
				uniqueValue = value
			}
		}
		
		return uniqueValue
	}


	internal func isEqual(_ a:Any,_ b:Any) -> Bool
	{
		guard let objectA = a as? NSObject else { return false }
		guard let objectB = b as? NSObject else { return false }
		return objectA.isEqual(objectB)
		
//		let TypeA = type(of:a)
//		let TypeB = type(of:b)
//
//		guard TypeA == TypeB else { return false }
//		guard let a = a as? TypeA.self, let b = b as? TypeA.self else { return false }
//		return a == b
	}


	override func addObserver(_ observer:NSObject,forKeyPath keyPath:String,options:NSKeyValueObservingOptions=[],context:UnsafeMutableRawPointer?)
	{
		self.stopObservingSelectedObjects()
		let info = _NSObserverInfo(observer:observer,keyPath:keyPath,options:options,context:context)
		self.observers.append(info)
		self.startObservingSelectedObjects()
	}
	
	override func removeObserver(_ observer:NSObject,forKeyPath keyPath:String)
	{
		self.stopObservingSelectedObjects()

		if let index = self.observers.index(where:{ $0.observer===observer && $0.keyPath==keyPath })
		{
			self.observers.remove(at:index)
		}
		
		self.startObservingSelectedObjects()
	}
	
	// Whenever the controller changes the arrangedObjects or selectedObjects, KVO observing must be temporarily
	// stopped and then resumed once mutating the array has concluded.
	
	private var controllerChangeCount = 0
	
	public func controllerWillChangeObjects()
	{
		if controllerChangeCount == 0
		{
			self.stopObservingSelectedObjects()
		}
		
		controllerChangeCount += 1
	}
	
	public func controllerDidChangeObjects()
	{
		controllerChangeCount -= 1
		
		if controllerChangeCount == 0
		{
			self.startObservingSelectedObjects()
		}
	}
	
	// Start KVO observing all selected objects
	
	func startObservingSelectedObjects()
	{
		guard let selectedObjects = arrayController?.selectedObjects as? [NSObject] else { return }
		let keyPaths = self.observers.map { $0.keyPath }
		self.objectProxies.removeAll()
		
		for object in selectedObjects
		{
			for keyPath in keyPaths
			{
				let proxy = _NSObjectProxy(owner:self,object:object,keyPath:keyPath,options:[.old,.new],context:nil)
				objectProxies.append(proxy)
			}
		}
	}
	
	// Stop KVO observing
	
	func stopObservingSelectedObjects()
	{
		self.objectProxies.removeAll()
	}
	
	// Any KVO notifications received by a _NSObjectProxy will be routed to here. We now need to pass on this
	// notification to all observers interested in this keyPath.
	
	override func observeValue(forKeyPath keyPath:String?,of object:Any?,change:[NSKeyValueChangeKey:Any]?,context:UnsafeMutableRawPointer?)
	{
		let targets = self.observers.filter { $0.keyPath == keyPath }

		for info in targets
		{
			let observer = info.observer?.value(forKey:"observer") as? NSObject
			observer?.observeValue(forKeyPath:keyPath,of:self,change:change,context:info.context)
		}

//		guard let change = change else { return }
//		guard let prior = change[NSKeyValueChangeKey.notificationIsPriorKey] as? Bool else { return }
//		guard let keyPath = keyPath else { return }
//
//		if prior
//		{
//			self.willChangeValue(forKey:keyPath)
//		}
//		else
//		{
//			self.didChangeValue(forKey:keyPath)
//		}
	}
	
}
	

//----------------------------------------------------------------------------------------------------------------------


// MARK:

/// Helper class that observes a single keypath of an object and passes any KVO notifications to the owner of this proxy

internal class _NSObjectProxy : NSObject
{
	weak var owner:NSObject?
	weak var object:NSObject?
	var keyPath:String
	
	init(owner:NSObject,object:NSObject,keyPath:String,options:NSKeyValueObservingOptions=[],context:UnsafeMutableRawPointer?)
	{
		self.owner = owner
		self.object = object
		self.keyPath = keyPath
		
		super.init()
		
		object.addObserver(self,forKeyPath:keyPath,options:options,context:context)
	}
	
	deinit
	{
		object?.removeObserver(self,forKeyPath:keyPath)
	}
	
	override func observeValue(forKeyPath keyPath:String?,of object:Any?,change:[NSKeyValueChangeKey:Any]?,context:UnsafeMutableRawPointer?)
	{
		self.owner?.observeValue(forKeyPath:keyPath,of:object,change:change,context:context)
	}
}


//----------------------------------------------------------------------------------------------------------------------


#endif



