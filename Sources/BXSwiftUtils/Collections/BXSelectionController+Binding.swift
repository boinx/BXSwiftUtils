//**********************************************************************************************************************
//
//  BXSelectionController+Binding.swift
//	Adds support for Swift keypaths and SwiftUI Bindings
//  Copyright ©2019 Peter Baumgartner. All rights reserved.
//
//**********************************************************************************************************************


#if canImport(SwiftUI)
import SwiftUI


//----------------------------------------------------------------------------------------------------------------------


extension BXSelectionController
{

	/// Creates a generic SwiftUI binding to a property of type T on a class C. The selected objects in
	/// this controller must be of class C for this to work correctly.
	///
	/// - parameter keyPath: A keypath for a writable property of type T on class C
	/// - returns: A Binding to a Set of values of type T.

	@available(macOS 10.15.2, iOS 13.2, tvOS 13.0, *)
	
	public func binding<C,T:Hashable>(forKeyPath keyPath:ReferenceWritableKeyPath<C,T>) -> Binding<Set<T>>
	{
		return Binding<Set<T>>(
		
			get:
			{
				self.values(forKeyPath:keyPath)
			},
			
			set:
			{
				self.setValues($0, forKeyPath:keyPath)
			})
	}
	

	/// Creates a generic SwiftUI binding to a property of type T? on a class C. The selected objects in
	/// this controller must be of class C for this to work correctly.
	///
	/// - parameter keyPath: A keypath for a writable property of type T? on class C
	/// - returns: A Binding to a Set of values of type T.

	@available(macOS 10.15.2, iOS 13.2, tvOS 13.0, *)
	
	public func binding<C,T:Hashable>(forKeyPath keyPath:ReferenceWritableKeyPath<C,T?>) -> Binding<Set<T>>
	{
		return Binding<Set<T>>(
		
			get:
			{
				self.values(forKeyPath:keyPath)
//				Set( self.values(forKeyPath:keyPath).compactMap { $0 } )
			},
			
			set:
			{
				self.setValues($0, forKeyPath:keyPath)
			})
	}


	/// Returns a specialized binding that converts a property of type Int to a Set<Double>
	///
	/// This binding can be used by sliders when referencing Int properties.
	///
	/// - parameter keyPath: A keypath for a writable property of type Int on class C
	/// - returns: A Binding to a Set of Double values

	@available(macOS 10.15.2, iOS 13.2, tvOS 13.0, *)
	
	public func doubleBinding<C>(forKeyPath keyPath:ReferenceWritableKeyPath<C,Int>) -> Binding<Set<Double>>
	{
		return Binding<Set<Double>>(
		
			get:
			{
				let intValues = self.values(forKeyPath:keyPath)
				return Set( intValues.map { Double($0) } )
			},
			
			set:
			{
				doubleValues in
				let intValues = Set( doubleValues.map { Int($0) } )
				return self.setValues(intValues, forKeyPath:keyPath)
			})
	}



//----------------------------------------------------------------------------------------------------------------------


	/// Returns a Set of values. If the controller selection is empty, the returned Set will also be empty.
	/// If the property values for the selected objects are unique, the Set will contain a single value.
	/// In case of multiple (non-unique) values, the Set will contain more than one value.
	///
	/// - parameter keyPath: The keyPath for a property of type T on a class C
	/// - returns: A set of values of type T.
	
	public func values<C,T:Hashable>(forKeyPath keyPath:KeyPath<C,T>) -> Set<T>
	{
		var values = Set<T>()
		
		for object in self.selectedObjects
		{
			if let object = object as? C
			{
				let value = object[keyPath:keyPath]
				
				if let valueArray = value as? [T]
				{
					for v in valueArray
					{
						values.insert(v)
					}
				}
				else 
				{
					values.insert(value)
				}
			}
		}
		
		return values
	}


	/// Returns a Set of values. If the controller selection is empty, the returned Set will also be empty.
	/// If the property values for the selected objects are unique, the Set will contain a single value.
	/// In case of multiple (non-unique) values, the Set will contain more than one value.
	///
	/// - parameter keyPath: The keyPath for a property of type T on a class C
	/// - returns: A set of values of type T.
	
	public func values<C,T:Hashable>(forKeyPath keyPath:KeyPath<C,T?>) -> Set<T>
	{
		var values = Set<T>()
		
		for object in self.selectedObjects
		{
			if let object = object as? C, let v = object[keyPath:keyPath]
			{
				values.insert(v)
			}
		}
		
		return values
	}


	/// Returns a value if this value is unique across the selected objects, or nil if not. In case of an empty
	/// selection nil will also be returned.
	///
	/// - parameter keyPath: The keyPath for a property of type T on a class C
	/// - returns: An optional of type T.

	public func uniqueValue<C,T:Hashable>(forKeyPath keyPath:KeyPath<C,T>) -> T?
	{
		let values:Set<T> = self.values(forKeyPath:keyPath)
		
		if values.count == 1
		{
			return values.first
		}
		
		return nil
	}
	

	/// Returns a value if this value is unique across the selected objects, or nil if not. In case of an empty
	/// selection nil will also be returned.
	///
	/// - parameter keyPath: The keyPath for a property of type T on a class C
	/// - returns: An optional of type T.

	public func uniqueValue<C,T:Hashable>(forKeyPath keyPath:KeyPath<C,T?>) -> T?
	{
		let values:Set<T> = self.values(forKeyPath:keyPath)
		
		if values.count == 1
		{
			return values.first
		}
		
		return nil
	}
	

//----------------------------------------------------------------------------------------------------------------------


	/// Returns true if the selection contains a specified value at a given property keypath.
	///
	/// - parameter value: The value to search ofr
	/// - parameter keyPath: The keyPath for a property of type T on a class C
	/// - returns: True if the specified value has been found at the keyPath
	
	public func contains<C,T:Hashable>(value:T, forKeyPath keyPath:KeyPath<C,T>) -> Bool
	{
		for object in self.selectedObjects
		{
			if let object = object as? C
			{
				let v = object[keyPath:keyPath]
				
//				if let values = v as? [T]
//				{
//					for v in values
//					{
//						if v == value { return true }
//					}
//				}
//				else
//				{
					if v == value { return true }
//				}
			}
		}
		
		return false
	}


//----------------------------------------------------------------------------------------------------------------------


	/// Sets the new value on all objects that are selected in this controller.
	///
	/// - parameter values: A Set of values of type T - please note that only the first value in this Set will be used!
	/// - parameter keyPath: A keypath for a writable property of type T on class C
	
	public func setValues<C,T:Hashable>(_ values:Set<T>, forKeyPath keyPath:ReferenceWritableKeyPath<C,T>)
	{
		guard let value = values.first else { return }
		
		self.setValue(value, forKeyPath:keyPath)
	}


	/// Sets the new value on all objects that are selected in this controller.
	///
	/// - parameter value: A value of type T
	/// - parameter keyPath: A keypath for a writable property of type T on class C

	public func setValue<C,T:Hashable>(_ value:T, forKeyPath keyPath:ReferenceWritableKeyPath<C,T>)
	{
		for object in self.selectedObjects
		{
			if let object = object as? C
			{
				if let _ = object[keyPath:keyPath] as? [T]
				{
					// TODO: implement
				}
				else
				{
					object[keyPath:keyPath] = value
				}
			}
		}
	}


//----------------------------------------------------------------------------------------------------------------------


}

#endif
