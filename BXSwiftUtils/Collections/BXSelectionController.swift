//**********************************************************************************************************************
//
//  BXSelectionController.swift
//	Replacement for the multiple selection functionality of NSArrayController without all the costly overhead
//  Copyright ©2019 Peter Baumgartner. All rights reserved.
//
//**********************************************************************************************************************


import Foundation

#if os(macOS)
import AppKit
#endif


//----------------------------------------------------------------------------------------------------------------------


/// This protocol provides a way to uniquely identify objects

public protocol BXSelectable : class
{
	typealias ID = String

	/// Returns the identifier for an object
	
	var id: ID { get }
	
	/// The handlers are called when an object is removed from the object graph, and should thus also be removed
	/// from the selection. The arguments to the handler are the object that should be removed from the selection,
	/// and a Bool that indicated whether the object is still alive (true) or currently dying (false).
	
	var autoDeselectHandlers: [String:BXAutoDeselectHandler] { set get }

	typealias BXAutoDeselectHandler = (NSObject,Bool) -> Void
}


//----------------------------------------------------------------------------------------------------------------------


// MARK: -

open class BXSelectionController : NSObject
{

	/// ObjectWrapper holds a weak reference to an object and manages the property observers
	
	private class ObjectWrapper
	{
		/// The object is stored in a weak ref so we do not retain it just because it was selected
		
		weak var object: NSObject? = nil
		
		/// A list of property observers. Will be replaced by Combine subscriptions in the future
		
		var observers: [Any] = []
		
		/// Creates a new ObjectWrapper
		
		init(_ object:NSObject)
		{
			self.object = object
		}

		/// Adds the registered property observers on the selected object
		
		func addObservers(with controller:BXSelectionController)
		{
			guard let object = object else { return }
			
			for info in controller.propertiesObserverInfo
			{
				self.observers += KVO(object:object, keyPath:info.keyPath, options:info.options)
				{
					[weak controller] _,_ in controller?.publish(forKey:info.keyPath)
				}
			}
		}
		
		/// Removes all property observers
		
		func removeObservers()
		{
			self.observers.removeAll()
		}
	}
	
	
//----------------------------------------------------------------------------------------------------------------------


	// MARK: -
	
	/// This struct stores the info necessary to create KVO property observers on newly selected objects
	
	private struct PropertyObserverInfo
	{
		var keyPath: String
		var options: NSKeyValueObservingOptions
	}
	
	
//----------------------------------------------------------------------------------------------------------------------


	// MARK: -
	
	/// Selected objects are stored in a dictionary keyed by their id. That way each object can only be in
	/// the selection once.
	
	private var selection: [BXSelectable.ID:ObjectWrapper] = [:]
	
	/// The list of properties that should be observed
	
	private var propertiesObserverInfo: [PropertyObserverInfo] = []

	/// A Notification that gets sent whenever the selection changes.
	
	public static let selectionDidChangeNotification = NSNotification.Name("BXSelectionController.selectionDidChange")

	/// When you set an UndoManager on this controller, then any changes to the selection will be undoable

	public var undoManager:UndoManager? = nil
	
	/// The debugName is only used for identifying different instances of this class during debugging or logging
	
	public var debugName: String = ""
	
	/// This uniquely identifies this BXSelectionController. Used as a key in the autoDeselectHandlers dictionary.
	
	private var id = UUID().uuidString
	
	
//----------------------------------------------------------------------------------------------------------------------


	// MARK: - Lifetime
	
	public init(undoManager:UndoManager? = nil, debugName:String = "")
	{
		self.undoManager = undoManager
		self.debugName = debugName
		super.init()
	}

	/// Cancel all outstanding scheduled function calls
	
	deinit
	{
		self.cancelAllDelayedPerforms()
	}
	

//----------------------------------------------------------------------------------------------------------------------


	// MARK: - Register Property Observers
	
	
	// When an outside object adds an observer, store info about the observed property in the propertiesObserverInfo
	// array. This is used later when objects are added to the selection to rebuild its KVO observers.
	
	override open func addObserver(_ observer:NSObject, forKeyPath _keyPath:String, options:NSKeyValueObservingOptions = [], context:UnsafeMutableRawPointer?)
	{
		// If the keypath starts with "selection." strip the prefix. This is done because most historic code with
		// NSArrayControllers binds a control with a keypath like "selection.propertyName". Since BXSelectionController
		// is a lightweight replacement for NSArrayController, and BXSelectionController doesn't use an internal
		// "selection" proxy object, we simply strip this part from the keypath to remain backwards compatible.
		
		let keyPath = _keyPath.strippingSelectionPrefix()
		
		// Add the observer to self. The UI control is now observing this controller.

//print("\(debugName).addObserver observer=\(observer) keyPath='\(keyPath)' context=\(context)")

		super.addObserver(observer, forKeyPath:keyPath, options:options, context:context)
		
		// Record the info for this property, so that it can be observed on objects added to the selection at
		// a later time. Please note that if the property is already in the array, we won't add it again.
		
		for info in self.propertiesObserverInfo
		{
			if keyPath == info.keyPath && options == info.options { return }
		}
		
		self.propertiesObserverInfo += PropertyObserverInfo(keyPath:keyPath, options:options)
		
		// Since the list of properties has changed, rebuild the observers of all selected objects
		
		self.rebuildSelectionObservers()
	}
	
	
	override open func removeObserver(_ observer:NSObject, forKeyPath _keyPath:String, context:UnsafeMutableRawPointer?)
	{
		// Remove the observer from self (the controller) and delete the property info from the list
		
		let keyPath = _keyPath.strippingSelectionPrefix()

//print("\(debugName).removeObserver observer=\(observer) keyPath='\(keyPath)' context=\(context)")

		super.removeObserver(observer, forKeyPath:keyPath, context:context)
		self.propertiesObserverInfo.removeAll { $0.keyPath == keyPath }
		
		// Since the list of properties has changed, rebuild the observers of all selected objects
		
		self.rebuildSelectionObservers()
	}


	override open func removeObserver(_ observer:NSObject, forKeyPath _keyPath:String)
	{
		// Remove the observer from self (the controller) and delete the property info from the list
		
		let keyPath = _keyPath.strippingSelectionPrefix()

//print("\(debugName).removeObserver observer=\(observer) keyPath='\(keyPath)'")

		super.removeObserver(observer, forKeyPath:keyPath)
		self.propertiesObserverInfo.removeAll { $0.keyPath == keyPath }
		
		// Since the list of properties has changed, rebuild the observers of all selected objects
		
		self.rebuildSelectionObservers()
	}


//----------------------------------------------------------------------------------------------------------------------


	/// Throws away existing KVO observers and completely rebuilds them for each selected object. This should
	/// always be called when new properties are added AFTER setting the selection!
	
	func rebuildSelectionObservers()
	{
		self.performCoalesced(#selector(_rebuildSelectionObservers))
	}

	@objc func _rebuildSelectionObservers()
	{
		self.selection.values.forEach
		{
			$0.removeObservers()
			$0.addObservers(with:self)
		}
	}


//----------------------------------------------------------------------------------------------------------------------


	/// Publishes a value change for all registered properties
	
	fileprivate func publish()
	{
		self.performCoalesced(#selector(_publish))
	}
	
	@objc fileprivate func _publish()
	{
		for info in self.propertiesObserverInfo
		{
			self.publish(forKey:info.keyPath)
		}
	}

	/// Publishes a value change for the specified property
	
	fileprivate func publish(forKey key:String)
	{
		DispatchQueue.main.asyncIfNeeded
		{
			self.willChangeValue(forKey:key)
			self.didChangeValue(forKey:key)
			self.publishObjectWillChange()
		}
	}
	
	
//----------------------------------------------------------------------------------------------------------------------


	// MARK: - KVC Accessors
	
	
	/// Sets the new value on all selected objects
	
	override open func setValue(_ value:Any?, forKey _key:String)
	{
		let key = _key.strippingSelectionPrefix()
		guard key.count > 0 else { return }
		self.selectedObjects.forEach { $0.setValue(value,forKey:key) }
	}

	/// Sets the new value on all selected objects
	
	override open func setValue(_ value:Any?, forKeyPath _keyPath:String)
	{
		let keyPath = _keyPath.strippingSelectionPrefix()
		guard keyPath.count > 0 else { return }
		self.selectedObjects.forEach { $0.setValue(value,forKeyPath:keyPath) }
	}


//----------------------------------------------------------------------------------------------------------------------


	/// Gets the value from all selected objects. If the value is unique it will be returned, otherwise
	/// NSMultipleValuesMarker will be returned.
	
	override open func value(forKey _key:String) -> Any?
	{
		let key = _key.strippingSelectionPrefix()
		if key == "selection" { return self }
		var uniqueValue: Any? = nil
		
		for object in self.selectedObjects
		{
			if let value = object.value(forKey:key)
			{
				if uniqueValue == nil
				{
					uniqueValue = value
				}
				else if let value1 = uniqueValue as? NSObject, let value2 = value as? NSObject, !value1.isEqual(value2)
				{
					return NSMultipleValuesMarker
				}
			}
		}
		
		return uniqueValue
	}
	
	
	/// Gets the value from all selected objects. If the value is unique it will be returned, otherwise
	/// NSMultipleValuesMarker will be returned.
	
	override open func value(forKeyPath _keyPath:String) -> Any?
	{
		let keyPath = _keyPath.strippingSelectionPrefix()
		if keyPath == "selection" { return self }
		var uniqueValue: Any? = nil
		
		for object in self.selectedObjects
		{
			if let value = object.value(forKeyPath:keyPath)
			{
				if uniqueValue == nil
				{
					uniqueValue = value
				}
				else if let value1 = uniqueValue as? NSObject, let value2 = value as? NSObject, !value1.isEqual(value2)
				{
					return NSMultipleValuesMarker
				}
			}
		}
		
		return uniqueValue
	}
	
	
//----------------------------------------------------------------------------------------------------------------------


	/// Returns an array of values. If the selection is empty, the returned Set will also be empty. If the
	/// property values for the selected objects is unique, the Set will contain a single value. In case of
	/// multiple (non-unique) values, the Set will contain more than one value.
	
	public func values<T:Equatable>(forKeyPath _keyPath:String) -> Set<T>
	{
		let keyPath = _keyPath.strippingSelectionPrefix()
		var values = Set<T>()
		
		for object in self.selectedObjects
		{
			if let value = object.value(forKeyPath:keyPath) as? T
			{
				values.insert(value)
			}
			else if let valueArray = object.value(forKeyPath:keyPath) as? [T]
			{
				for value in valueArray
				{
					values.insert(value)
				}
			}
		}
		
		return values
	}
	
	
//----------------------------------------------------------------------------------------------------------------------


	// MARK: - Selection


	/// Adds a new object to the selection
	
	open func addSelectedObject(_ object:NSObject, registerUndo:Bool = true)
	{
//print("\(debugName).addSelectedObject")

		// Bail out if the object is not selectable
		
		guard let id = (object as? BXSelectable)?.id else { return }
		
		// Bail out if the object is already selected
		
		guard selection[id] == nil else { return }
		
		// Store the object in the selection and observe its properties
		
		let wrappedObject = ObjectWrapper(object)
		wrappedObject.addObservers(with:self)
		selection[id] = wrappedObject
		
		// Install an optional handler that automatically deselects the object when necessary

		(object as? BXSelectable)?.autoDeselectHandlers[self.id] =
		{
			[weak self] in self?.removeSelectedObject($0, registerUndo:$1)
		}

		// Register an undo action
		
		if registerUndo
		{
			self.undoManager?.registerUndoWithAutomaticName(target:self)
			{
				target in target.removeSelectedObject(object)
			}
		}
		
		// Send notification for selection change
		
		NotificationCenter.default.post(name:type(of:self).selectionDidChangeNotification, object:object)

		// Publish common values to the UI
		
		self.publish()
	}


	/// Adds objects to the selection
	
	open func addSelectedObjects(_ objects:[NSObject], registerUndo:Bool = true)
	{
		objects.forEach { self.addSelectedObject($0,registerUndo:registerUndo) }
	}


//----------------------------------------------------------------------------------------------------------------------


	/// Removes an object from the selection
	
	open func removeSelectedObject(_ object:NSObject, registerUndo:Bool = true)
	{
//print("\(debugName).removeSelectedObject")

		guard let id = (object as? BXSelectable)?.id else { return }

		if let wrappedObject = selection[id]
		{
			// Remove autoDeselectHandler
			
			(object as? BXSelectable)?.autoDeselectHandlers[self.id] = nil

			// Remove object from selection
			
			wrappedObject.removeObservers()
			selection[id] = nil

			// Register an undo action
			
			if registerUndo
			{
				self.undoManager?.registerUndoWithAutomaticName(target:self)
				{
					target in target.addSelectedObject(object)
				}
			}
			
			// Send notification for selection change
		
			NotificationCenter.default.post(name:type(of:self).selectionDidChangeNotification, object:object)

			// Publish common values to the UI
		
			self.publish()
		}
	}

	/// Removes objects from the selection
	
	open func removeSelectedObjects(_ objects:[NSObject], registerUndo:Bool = true)
	{
		objects.forEach { self.removeSelectedObject($0, registerUndo:registerUndo) }
	}


//----------------------------------------------------------------------------------------------------------------------


	/// Replaces the current selection with a new one
	
	open func setSelectedObjects(_ objects: [NSObject], registerUndo:Bool = true)
	{
		let oldSelection = self.selection
		let oldSelectedObjects = oldSelection.values.compactMap { $0.object }

		// First remove observers from old selection
		
		for (_,wrappedObject) in self.selection
		{
			wrappedObject.removeObservers()
		}

		// Then create and store the new selection
		
		var newSelection: [String:ObjectWrapper] = [:]
		
		for object in objects
		{
			if let id = (object as? BXSelectable)?.id
			{
				// Observe object properties
		
				let wrappedObject = ObjectWrapper(object)
				wrappedObject.addObservers(with:self)
				newSelection[id] = wrappedObject

				// Install an optional handler that automatically deselects the object when necessary
		
				(object as? BXSelectable)?.autoDeselectHandlers[self.id] =
				{
					[weak self] in self?.removeSelectedObject($0, registerUndo:$1)
				}
			}
		}
		
		self.selection = newSelection

		// Register an undo action
	
		if registerUndo
		{
			self.undoManager?.registerUndoWithAutomaticName(target:self)
			{
				target in target.setSelectedObjects(oldSelectedObjects)
			}
		}
		
		// Send notifications for all changes
		
		Set(
			oldSelection.values.compactMap { $0.object } +
			newSelection.values.compactMap { $0.object }
		)
		.forEach
		{
			NotificationCenter.default.post(name:type(of:self).selectionDidChangeNotification, object:$0)
		}

		// Publish common values to the UI
		
		self.publish()
	}
	
	
	/// Returns all selected objects as an array. The objects are not in any particular order.

	open var selectedObjects: [NSObject]
	{
		return self.selection.values.compactMap { $0.object }
	}
	
	
//----------------------------------------------------------------------------------------------------------------------


	/// This property returns true if we have any selected objects

	@objc dynamic open var hasSelection:Bool
	{
		return self.selectedObjectCount > 0
	}
	

	/// Return the number of selected object

	open var selectedObjectCount:Int
	{
		return self.selection.count
	}
	

	/// Returns true if the specified object is currently selected
	
	open func isSelected(_ object:NSObject) -> Bool
	{
		return self.selection.values.contains { $0.object === object }
	}
	
}


//----------------------------------------------------------------------------------------------------------------------


// MARK: -

fileprivate extension String
{
	/// Removes the prefix "selection." from a keypath
	
	func strippingSelectionPrefix() -> String
	{
		return self.replacingOccurrences(of:"selection.", with:"")
	}
}


//----------------------------------------------------------------------------------------------------------------------


