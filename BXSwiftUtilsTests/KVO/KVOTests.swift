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
     Tests regarding the general functionality can be found int he TypedKVOTests file!
     */

    /*
     Asserts the availability of the class and its basic usage.
    */
    func testBasicFunctionality()
    {
        var count = 0
        
        self.exposedObject = SomeClass()
    
        self.observers += KVO(object: self, keyPath: "exposedObject.intProp", options: [.new, .initial])
        { (oldValue, newValue) in
            if count == 0
            {
                XCTAssertEqual(newValue as? Int, 42)
            }
            else
            {
                XCTAssertEqual(newValue as? Int, 100)
            }
            count += 1
        }
        
        self.exposedObject!.intProp = 100
        
        XCTAssertEqual(count, 2)
    }
}
