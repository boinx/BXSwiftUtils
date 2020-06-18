//**********************************************************************************************************************
//
//  Wrapper+Atomic.swift
//  A property wrapper which allows for easy atomic access.
//  Copyright © 2020 Boinx Software Ltd. & Imagine GbR. All rights reserved.
//
//**********************************************************************************************************************

import Foundation

// Source: https://www.onswiftwings.com/posts/atomic-property-wrapper/

@propertyWrapper
public struct Atomic<Value> {

    private var value: Value
    private let lock = NSLock()

    public init(wrappedValue value: Value) {
        self.value = value
    }

    public var wrappedValue: Value {
      get { return load() }
      set { store(newValue: newValue) }
    }

    public func load() -> Value {
        lock.lock()
        defer { lock.unlock() }
        return value
    }

    public mutating func store(newValue: Value) {
        lock.lock()
        defer { lock.unlock() }
        value = newValue
    }
}
