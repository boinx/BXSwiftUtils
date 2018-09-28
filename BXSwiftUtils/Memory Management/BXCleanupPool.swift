//
//  BXCleanupPool.swift
//  BXSwiftUtils
//
//  Created by Stefan Fochler on 28.09.18.
//  Copyright © 2018 Boinx Software Ltd. & Imagine GbR. All rights reserved.
//

fileprivate protocol Cleanable
{
    func cleanup()
    
    func equals(_ other: Cleanable) -> Bool
}

/**
 A container that can register cleanup items that get set to the provided value (e.g. `nil`) when `cleanup()` is called
 on the container or the container is deallocated.
 
 When registering cleanups, the `target` is not retained, but the `cleanupValue` is and all previous cleanups for the
 same `target` and `keyPath` are removed.
 Additionally, all cleanup items are removed once `cleanup()` is called.
 
 ## Example
 
     class MyController
     {
         private let handlers = BXCleanupPool()
 
         var onCloseHandler: (() -> Void)?
         {
             willSet { self.handlers.registerCleanup(self, \.onCloseHandler, nil)
         }
 
         // ...
 
         func documentWillClose()
         {
             self.handlers.cleanup()
         }
     }
 */
public class BXCleanupPool
{
    private var pool: [Cleanable] = []
    private var isRegistrationEnabled = true
    
    // Allow external instantiation
    public init() {}
    
    public func registerCleanup<Base: AnyObject, Value>(_ target: Base, _ keyPath: ReferenceWritableKeyPath<Base, Value>, _ cleanupValue: Value)
    {
        guard self.isRegistrationEnabled else { return }
        
        let wrapper = CleanableWrapper(target, keyPath, cleanupValue)
        self.addItemToPool(wrapper)
    }
    
    // Allow passing in a non-optional `cleanupValue`s for optional key paths (otherwise, caller would have to wrap
    // cleanupValue in `Optional()` for above function to match).
    public func registerCleanup<Base: AnyObject, OptionalValue: OptionalType>(_ target: Base, _ keyPath: ReferenceWritableKeyPath<Base, OptionalValue>, _ cleanupValue: OptionalValue.Wrapped)
    {
        guard self.isRegistrationEnabled else { return }
        
        let wrapper = CleanableWrapper(target, keyPath, OptionalValue(cleanupValue))
        self.addItemToPool(wrapper)
    }
    
    private func addItemToPool(_ item: Cleanable)
    {
        self.pool.removeAll(where: { $0.equals(item) })
        self.pool.append(item)
    }
    
    public func cleanup()
    {
        self.isRegistrationEnabled = false
        defer { self.isRegistrationEnabled = true }
        
        self.pool.forEach { $0.cleanup() }
        self.pool = []
    }
    
    deinit
    {
        self.cleanup()
    }
}

fileprivate struct CleanableWrapper<Base: AnyObject, Value>: Cleanable, Equatable
{
    weak var target: Base?
    let keyPath: ReferenceWritableKeyPath<Base, Value>
    let cleanupValue: Value
    
    init(_ target: Base, _ keyPath: ReferenceWritableKeyPath<Base, Value>, _ cleanupValue: Value)
    {
        self.target = target
        self.keyPath = keyPath
        self.cleanupValue = cleanupValue
    }
    
    func cleanup()
    {
        self.target?[keyPath: self.keyPath] = self.cleanupValue
    }
    
    func equals(_ other: Cleanable) -> Bool {
        if let otherWrapper = other as? CleanableWrapper<Base, Value>
        {
            return self == otherWrapper
        }
        
        return false
    }
    
    static func == (lhs: CleanableWrapper<Base, Value>, rhs: CleanableWrapper<Base, Value>) -> Bool
    {
        return lhs.target === rhs.target && lhs.keyPath == rhs.keyPath
    }
}
