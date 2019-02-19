//
//  Mirror+IterateProperties.swift
//  BXSwiftUtils
//
//  Created by Peter Baumgartner on 19.02.19.
//  Copyright ©2019 Imagine GbR. All rights reserved.
//


// Based on blog post https://www.swiftbysundell.com/posts/reflection-in-swift


//----------------------------------------------------------------------------------------------------------------------


public extension Mirror
{

	/// Iterates over properties with the specified type of a target object and perform a closure for each of them.
	///
	/// Assuming you have properties conforming to the Cleanable protocol, to call the cleanup() function on all
	/// properties use the following code:
	///
	///		Mirror.iterateProperties(of:self, recursive:true)
	///		{
    ///         childProperty:Cleanable in
    ///         childProperty.cleanup()
    ///		}
	///
	/// - parameter target: The object that holds the properties
	/// - parameter type: The type of properties to iterate
	/// - parameter recursive: If true descend recursively into the object graph
	/// - parameter closure: The closure to be called for each property that qualifies

    public static func iterateProperties<T>(
    	of target: Any,
        with type: T.Type = T.self,
        recursive: Bool = false,
        perform closure: (T)->Void)
    {
        let mirror = Mirror(reflecting: target)

        for child in mirror.children
        {
        	if let property = child.value as? T
        	{
				closure(property)
        	}

			if let array = child.value as? [T]
			{
				array.forEach { closure($0) }
			}
			
			if let dictionary = child.value as? [AnyHashable:T]
			{
				dictionary.values.forEach { closure($0) }
			}

            if recursive
            {
                Mirror.iterateProperties(of:child.value, recursive:true, perform:closure)
            }
        }
    }
}


//----------------------------------------------------------------------------------------------------------------------
