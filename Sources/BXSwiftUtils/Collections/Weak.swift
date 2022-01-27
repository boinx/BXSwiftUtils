//
//  Weak.swift
//  BXSwiftUtils
//
//  Created by Stefan Fochler on 25.06.18.
//  Copyright © 2018 Boinx Software Ltd. & Imagine GbR. All rights reserved.
//

import Foundation

/// This class defines a simple box that stores a weak reference to a value type.
///
/// This can be handy when creating weak collections in Swift that should not hold a strong reference to the elements, or
/// when used with APIs that would otherwise create a strong reference to their argument.

public class Weak<Value> where Value: AnyObject
{
    public private(set) weak var value: Value?
    
    public init(_ value: Value)
    {
        self.value = value
    }
}
