//
//  BXCleanupPool.swift
//  BXSwiftUtils
//
//  Created by Stefan Fochler & Peter Baumgartner on 28.09.18.
//  Copyright © 2018 Boinx Software Ltd. & Imagine GbR. All rights reserved.
//

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
    private var isRegistrationEnabled = true
    private var pool: [Cleanable] = []


    // Allow external instantiation
	
    public init() {}


    /// Registers a closure for execution upon cleanup.
    /// - parameter target: The target object is being handed to the closure without so that capturing it strongly is avoided.
    /// - parameter cleanupClosure: This is the closure that is executed upon cleanup.
	
    public func registerCleanup<Base: AnyObject>(_ target:Base, _ cleanupClosure: @escaping (Base)->Void)
    {
        guard self.isRegistrationEnabled else { return }

    	let wrapper = ClosureWrapper(target,cleanupClosure)
		self.pool.append(wrapper)
    }


    /// Registers a cleanup value for a property
    /// - parameter target: The object containing the property
    /// - parameter keyPath: The keypath to the property
    /// - parameter cleanupValue: The property will be set to this value upon cleanup

    public func registerCleanup<Base: AnyObject, Value>(_ target: Base, _ keyPath: ReferenceWritableKeyPath<Base, Value>, _ cleanupValue: Value)
    {
        guard self.isRegistrationEnabled else { return }
        
        let wrapper = PropertyWrapper(target, keyPath, cleanupValue)
        self.addItemToPool(wrapper)
    }
	
	
    // Allow passing in a non-optional `cleanupValue`s for optional key paths (otherwise, caller would have to wrap
    // cleanupValue in `Optional()` for above function to match).
	
    public func registerCleanup<Base: AnyObject, OptionalValue: OptionalType>(_ target: Base, _ keyPath: ReferenceWritableKeyPath<Base, OptionalValue>, _ cleanupValue: OptionalValue.Wrapped)
    {
        guard self.isRegistrationEnabled else { return }
        
        let wrapper = PropertyWrapper(target, keyPath, OptionalValue(cleanupValue))
        self.addItemToPool(wrapper)
    }
	
    private func addItemToPool(_ item: Cleanable)
    {
        self.pool = self.pool.filter({ !$0.equals(item) }) + item
    }
	
	
    /// Performs cleanup for all jobs added to the pool. After calling this function, the pool is emtpy, but may
    /// be reused for registering new cleanup jobs.
	
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


// This protocol simplifies the generics in the PropertyWrapper and ClosureWrapper structs below

fileprivate protocol Cleanable
{
    func cleanup()
    func equals(_ other: Cleanable) -> Bool
}


// This wrapper avoids strong references to the target object

fileprivate struct PropertyWrapper<Base: AnyObject, Value>: Cleanable, Equatable
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
    
    func equals(_ other: Cleanable) -> Bool
    {
        if let otherWrapper = other as? PropertyWrapper<Base, Value>
        {
            return self == otherWrapper
        }
        
        return false
    }
    
    static func == (lhs: PropertyWrapper<Base, Value>, rhs: PropertyWrapper<Base, Value>) -> Bool
    {
        return lhs.target === rhs.target && lhs.keyPath == rhs.keyPath
    }
}


// This wrapper avoids strong references to the target object

fileprivate struct ClosureWrapper<Base: AnyObject> : Cleanable
{
    weak var target: Base?
    let cleanupClosure: (Base)->Void
	
    init(_ target: Base, _ cleanupClosure: @escaping (Base)->Void)
    {
        self.target = target
        self.cleanupClosure = cleanupClosure
    }
	
    func cleanup()
    {
    	if let target = self.target
    	{
    		self.cleanupClosure(target)
		}
    }

	// Since closures are anonymous and can contain anything, we assume they are never equal!
	
    func equals(_ other: Cleanable) -> Bool
    {
        return false
    }
}
