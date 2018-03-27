//
//  KVOTests.swift
//  BXSwiftUtils
//
//  Created by Stefan Fochler on 27.03.18.
//  Copyright © 2018 Boinx Software Ltd. & Imagine GbR. All rights reserved.
//

import XCTest
import BXSwiftUtils


// Dummy class that must inherit from NSObject
fileprivate class SomeClass: NSObject
{
    @objc dynamic var intProp: Int = 42
    
    deinit {
        KVO.invalidate(for: self)
    }
}

class KVOTests: XCTestCase {
    
    @objc fileprivate dynamic var exposedObject: SomeClass?
    
    var observers = [Any]()
    
    override func setUp() {
        super.setUp()
        self.observers = []
    }

    /*
     Tests regarding the general functionality can be found int he TypedKVOTests file.
     */

    /*
     Asserts that an NSException is thrown when the key path is invalid.
     
     NOTE: Not all cases are correctly detected! If self.exposedObject was nil, the last invocation would succeed nonetheless.
     */
    func testInvalidKeyPath()
    {
        self.exposedObject = SomeClass()

        XCTAssertThrowsError(try NSException.toSwiftError
        {
            let _ = KVO(object: self, keyPath: "", { (_, _) in })
        })
        
        XCTAssertThrowsError(try NSException.toSwiftError
        {
            let _ = KVO(object: self, keyPath: "nonexistingObject", { (_, _) in })
        })
        
        XCTAssertThrowsError(try NSException.toSwiftError
        {
            let _ = KVO(object: self, keyPath: "exposedObject.foobar", { (_, _) in })
        })
    }
}
