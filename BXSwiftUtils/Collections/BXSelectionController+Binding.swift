//**********************************************************************************************************************
//
//  BXSelectionController+Binding.swift
//	Adds support for Swift keypaths and SwiftUI Bindings
//  Copyright ©2019 Peter Baumgartner. All rights reserved.
//
//**********************************************************************************************************************


#if canImport(SwiftUI)
import SwiftUI
#endif


//----------------------------------------------------------------------------------------------------------------------


extension BXSelectionController
{

	/// Returns a Set of values. If the controller selection is empty, the returned Set will also be empty.
	/// If the property values for the selected objects are unique, the Set will contain a single value.
	/// In case of multiple (non-unique) values, the Set will contain more than one value.
	///
	/// - parameter keyPath: The keyPath for a property of type T on a class C
	/// - returns: A set of values of type T.
	
	public func values<C,T:Equatable>(forKeyPath keyPath:KeyPath<C,T>) -> Set<T>
	{
		var values = Set<T>()
		
		for object in self.selectedObjects
		{
			if let object = object as? C
			{
				if let valueArray = object[keyPath:keyPath] as? [T]
				{
					for value in valueArray
					{
						values.insert(value)
					}
				}
				else
				{
					let value = object[keyPath:keyPath]
					values.insert(value)
				}
			}
		}
		
		return values
	}


//----------------------------------------------------------------------------------------------------------------------


	/// Sets the new value on all objects that are selected in this controller.
	///
	/// - parameter values: A Set of values of type T - please note that only the first value in this Set will be used!
	/// - parameter keyPath: A keypath for a writable property of type T on class C
	
	public func setValues<C,T:Equatable>(_ values:Set<T>, forKeyPath keyPath:ReferenceWritableKeyPath<C,T>)
	{
		guard let value = values.first else { return }
		
		for object in self.selectedObjects
		{
			if let object = object as? C
			{
				if let types = object[keyPath:keyPath] as? [T]
				{
					#warning("TODO: implement")
				}
				else
				{
					object[keyPath:keyPath] = value
				}
			}
		}
	}


//----------------------------------------------------------------------------------------------------------------------


	/// Creates a generic SwiftUI binding to a property of type T on a class C. The selected objects in
	/// this controller must of class C for this to work correctly.
	/// 
	/// - parameter keyPath: A keypath for a writable property of type T on class C
	/// - returns: A Binding to a Set of values of type T.

	@available(macOS 10.15.2, iOS 13.2, *)
	
	public func binding<C,T:Equatable>(forKeyPath keyPath:ReferenceWritableKeyPath<C,T>) -> Binding<Set<T>>
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
	
	
//----------------------------------------------------------------------------------------------------------------------


	// This dynamic lookup adds support for directly accessing properties of C without manually implementing
	// glue code accessors like we had to do in the past. Wonderful magic!
	
//	public subscript<C,T:Equatable>(dynamicMember keyPath:ReferenceWritableKeyPath<C,T>) -> Set<T>
//	{
//		set
//		{
//			self.setValues(newValue, forKeyPath:keyPath)
//		}
//
//		get
//		{
//			return self.values(forKeyPath:keyPath)
//		}
//	}


//----------------------------------------------------------------------------------------------------------------------


}
