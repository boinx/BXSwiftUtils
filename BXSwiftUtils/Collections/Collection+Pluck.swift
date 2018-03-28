//
//  Collection+Pluck.swift
//  BXSwiftUtils
//
//  Created by Stefan Fochler on 28.03.18.
//  Copyright © 2018 Boinx Software Ltd. & Imagine GbR. All rights reserved.
//

import Foundation

extension Collection
{
    /**
     Plucks ("extracts") the value at `keyPath` from each element of the collection.
     
     The order of the returned values depends on the internal order of the collection and is the same as when using the
     regular `map(transform:)` function.
     
     - Parameter keyPath: The key path relative to an element of the collection.
     - Returns: The array of extracted values.
    */
    public func pluck<T>(_ keyPath: KeyPath<Element, T>) -> [T] {
        return self.map { $0[keyPath: keyPath] }
    }
}
