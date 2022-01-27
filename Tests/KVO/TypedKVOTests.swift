//
//  TypedKVOTests.swift
//  BXSwiftUtils
//
//  Created by Stefan Fochler on 26.03.18.
//  Copyright © 2018 Boinx Software Ltd. & Imagine GbR. All rights reserved.
//

import XCTest
import BXSwiftUtils


// Dummy class that must inherit from NSObject
fileprivate class SomeClass: NSObject
{
    @objc dynamic var intProp: Int = 42
    @objc dynamic var nestedObj: NestedClass? = NestedClass()
    
    deinit {
        KVO.invalidate(for: self)
    }
}

// Nested class that is being retained by SomeClass
fileprivate class NestedClass: NSObject
{
    @objc dynamic var stringProp: String = "hello"
    
    deinit {
        KVO.invalidate(for: self)
    }
}


class TypedKVOTests: XCTestCase
{

    // Property that is not exposed to objc runtime
    fileprivate var nonExposedProperty: SomeClass?
    
    // Property that is exposed to objc runtime
    @objc fileprivate dynamic var exposedProperty: SomeClass?

    var observers = [Any]()
    
    override func setUp()
    {
        super.setUp()
        self.observers = []
    }

    /*
     Asserts that KVO works and reports a changed value.
     */
    func testBasicFunctionality()
    {
        var count = 0
        
        self.exposedProperty = SomeClass()
    
        self.observers += observeSafe(self, \.exposedProperty?.intProp)
        { (target, change) in
            if count == 0
            {
                XCTAssertEqual(change.newValue ?? nil, 42)
            }
            else
            {
                XCTAssertEqual(change.newValue ?? nil, 100)
            }
            count += 1
        }
        
        self.exposedProperty?.intProp = 100
        
        XCTAssertEqual(count, 2)
    }
    
    
    /*
     Asserts that a NSException is thrown when the key path contains properties that are not exposed to the ObjC runtime.
     */
    func testNonexposedPropertyInKeyPath()
    {
        XCTAssertThrowsError(try NSException.toSwiftError
        {
            let _ = observeSafe(self, \.nonExposedProperty?.intProp, { (_, _) in })
        })        
    }
    
    /*
     Asserts that the KVO is invalidated when the observer token is deallocated.
     */
    func testTokenInvalidation()
    {
        self.exposedProperty = SomeClass()
        
        // Use emtpy option set to avoid the initial callback
        self.observers += observeSafe(self, \.exposedProperty?.intProp, options: [])
        { (target, change) in
            XCTFail("This should not have been called at all")
        }
        
        self.observers = []
        
        // This does not trigger a notification since the observer tokens have been cleared and KVOs invalidated
        self.exposedProperty!.intProp = 100
    }

    /*
     Asserts that the KVO is invalidated when a property in the key path is deallocated.
     */
    func testAutomaticCleanupOfObjectInKeyPath()
    {
        var count = 0
        
        self.exposedProperty = SomeClass()
    
        self.observers += observeSafe(self, \.exposedProperty?.nestedObj?.stringProp)
        { (target, change) in
            if count == 0
            {
                XCTAssertEqual(change.newValue ?? nil, "hello")
            }
            else
            {
                XCTAssertEqual(change.newValue ?? nil, nil)
            }
            count += 1
        }
        
        // This would crash if the observer was not destroyed in time
        self.exposedProperty!.nestedObj = nil
        self.exposedProperty = nil

        XCTAssertEqual(count, 3)
    }
    
    /*
     Asserst that the KVO is invalidated when a property in the key path and the key path's root object is deallocated.
     */
    func testAutomaticCleanupOfIntermediateAndRootObject()
    {
        var count = 0
        
        self.exposedProperty = SomeClass()
    
        self.observers += observeSafe(self.exposedProperty!, \.nestedObj?.stringProp)
        { (target, change) in
            if count == 0
            {
                XCTAssertEqual(change.newValue ?? nil, "hello")
            }
            else
            {
                XCTAssertEqual(change.newValue ?? nil, nil)
            }
            count += 1
        }
        
        // This would crash if the observer was not destroyed in time
        self.exposedProperty!.nestedObj = nil
        self.exposedProperty = nil

        XCTAssertEqual(count, 2)
    }
    
    /*
     Asserts that the KVO is invalidated when the key path's root object is deallocated.
     */
    func testAutomaticCleanupOfRootObject()
    {
        var count = 0
        
        self.exposedProperty = SomeClass()
    
        self.observers += observeSafe(self.exposedProperty!, \.nestedObj?.stringProp)
        { (target, change) in
            if count == 0
            {
                XCTAssertEqual(change.newValue ?? nil, "hello")
            }
            count += 1
        }
        
        // This would crash if the observer was not destroyed in time
        self.exposedProperty = nil

        XCTAssertEqual(count, 1)
    }
}
