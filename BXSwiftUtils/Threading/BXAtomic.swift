//
//  BXAtomic.swift
//  BXSwiftUtils
//
//  Created by Stefan Fochler on 14.05.18.
//  Copyright © 2018 Boinx Software Ltd. & Imagine GbR. All rights reserved.
//

import Foundation

/**
 Wrapper around a value that provides atomic access using an internal dispatch queue.
 
 The value is accesses synchronously but parallel (for reads) or sequential (for writes). The value can be get/set using
 the `value` getter/setter. Note that this setter does not guarantee atomic access when first reading and then modifying
 the item!
 
 Instead, use the `modify(_:)` function that executes a closure in a synchronized fashion or one of the convenience
 methods provided for specific data types.
 */
class BXAtomic<T>
{
    private var lock: BXReadWriteLock
    private var _value: T
    
    /**
     Create an atomic wrapper with an initial value.
     */
    init(_ value: T)
    {
        self._value = value
        self.lock = BXReadWriteLock(label: "com.boinx.atomic.\(type(of: self._value))")
    }
    
    var value: T
    {
        get
        {
            return self.lock.read { self._value }
        }
        set
        {
            self.lock.write { self._value = newValue }
        }
    }
    
    /**
     Modify the stored value in a threadsafe fashion by executing the given block.
     
     - parameter block: Modification block that takes the current value and returns a value that will be stored as the
                        wrapper's new value.
     */
    @discardableResult func modify(_ block: (T) throws -> T) rethrows -> T
    {
        return try self.lock.write
        {
            self._value = try block(self._value)
            return self._value
        }
    }
}

extension BXAtomic where T: Numeric
{
    @discardableResult func increment() -> T
    {
        return self.modify { $0 + 1 }
    }
    
    @discardableResult func decrement() -> T
    {
        return self.modify { $0 - 1 }
    }
}

extension BXAtomic where T == Bool
{
    @discardableResult func toggle() -> T
    {
        return self.modify { !$0 }
    }
}
