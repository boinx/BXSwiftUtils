//
//  Collection+Pluck.swift
//  BXSwiftUtils
//
//  Created by Stefan Fochler on 28.03.18.
//  Copyright © 2018 Boinx Software Ltd. & Imagine GbR. All rights reserved.
//

import Foundation

public extension Collection
{
    /**
     Plucks ("extracts") the value at `keyPath` from each element of the collection.
     
     The order of the returned values depends on the internal order of the collection and is the same as when using the
     regular `map(transform:)` function.
     
     - Parameter keyPath: The key path relative to an element of the collection.
     - Returns: The array of extracted values.
    */
    func pluck<T>(_ keyPath: KeyPath<Element, T>) -> [T] {
        return self.map { $0[keyPath: keyPath] }
    }


    /// Returns a Set of values for the property specified by `keyPath`. The returned Set will contain
    /// exactly one entry if the values are unique, or more entries if the values are not unique.
    ///
    /// - Parameter keyPath: Specifies the property
    /// - Returns: A Set of of property values.
	
    func values<Value>(for keyPath: KeyPath<Element,Value>) -> Set<Value>
    {
    	var values = Set<Value>()
		
        for element in self
        {
        	let value = element[keyPath: keyPath]
        	values.insert(value)
        }
		
        return values
    }

}
