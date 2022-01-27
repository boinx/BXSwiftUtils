//
//  Collection+Assign.swift
//  BXSwiftUtils
//
//  Created by Stefan Fochler and Peter Baumgartne on 07.05.18.
//  Copyright © 2018 Boinx Software Ltd. & Imagine GbR. All rights reserved.
//

import Foundation

public extension Collection
{

    /// Assigns 'value' to a property (specified by keyPath) on each object in the collection.
    ///
    /// - Parameters:
    ///   - value: The new value
    ///   - keyPath: Specifies the property
    /// - Returns: The collection of objects
	
    @discardableResult func assign<Value>(_ value: Value, to keyPath: WritableKeyPath<Element, Value>) -> Self where Element: AnyObject
    {
        for var element in self
        {
            element[keyPath: keyPath] = value
        }
		
        return self
    }

    /// Returns a collection of elements whose property (specified by keyPath) was set to 'value'.
    ///
    /// - Parameters:
    ///   - value: The new value
    ///   - keyPath: Specifies the property
    /// - Returns: A new collection of elements whose property value was changed
	
    @discardableResult func assigning<Value>(_ value: Value, to keyPath: WritableKeyPath<Element, Value>) -> [Element]
    {
        return self.map
        {
            var mutableCopy = $0
            mutableCopy[keyPath: keyPath] = value
            return mutableCopy
        }
    }

}
