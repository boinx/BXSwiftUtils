//
//  BXCleanupPool+Tests.swift
//  BXSwiftUtils
//
//  Created by Stefan Fochler on 28.09.18.
//  Copyright © 2018 Boinx Software Ltd. & Imagine GbR. All rights reserved.
//

import XCTest
import BXSwiftUtils

class BXCleanupPool_Tests: XCTestCase
{

    var cleanupPool = BXCleanupPool()
    
    var optionalProperty: NSObject?
    var nonoptionalProperty: NSObject = NSObject()
    
    var automaticProperty: NSObject?
    {
        willSet { self.cleanupPool.registerCleanup(self, \.automaticProperty, nil) }
    }

    override func setUp()
    {
        self.cleanupPool = BXCleanupPool()
    }

    func testManualCleanup()
    {
        self.optionalProperty = NSObject()
        
        XCTAssertNotNil(self.optionalProperty)
        
        self.cleanupPool.registerCleanup(self, \.optionalProperty, nil)
        self.cleanupPool.cleanup()
        
        XCTAssertNil(self.optionalProperty)
    }
    
    func testCleanupOnDeinit()
    {
        self.optionalProperty = NSObject()
        
        XCTAssertNotNil(self.optionalProperty)
        
        self.cleanupPool.registerCleanup(self, \.optionalProperty, nil)
        self.cleanupPool = BXCleanupPool()
        
        XCTAssertNil(self.optionalProperty)
    }
    
    func testAutomaticRegistration()
    {
        self.automaticProperty = NSObject()
        
        XCTAssertNotNil(self.automaticProperty)
        
        self.cleanupPool.cleanup()
        
        XCTAssertNil(self.automaticProperty)
    }

    func testCustomCleanupValue()
    {
        self.optionalProperty = NSObject()
        self.nonoptionalProperty = NSObject()
        
        let customObject = NSObject()
        
        XCTAssertNotNil(self.optionalProperty)
        
        self.cleanupPool.registerCleanup(self, \.optionalProperty, customObject)
        self.cleanupPool.registerCleanup(self, \.nonoptionalProperty, customObject)
        self.cleanupPool.cleanup()
        
        XCTAssert(self.optionalProperty === customObject)
        XCTAssert(self.nonoptionalProperty === customObject)
    }
    
    func testMultipleRegistration()
    {
        weak var weakCustomObject: NSObject?
        
        do {
            let strongCustomObject = NSObject()
            weakCustomObject = strongCustomObject
            self.cleanupPool.registerCleanup(self, \.nonoptionalProperty, strongCustomObject)
        }
        
        XCTAssertNotNil(weakCustomObject)
        
        self.cleanupPool.registerCleanup(self, \.nonoptionalProperty, NSObject())
        
        XCTAssertNil(weakCustomObject)
    }

    func testCleanupClosure()
    {
        self.optionalProperty = NSObject()

        self.cleanupPool.registerCleanup(self)
        {
        	target in
        	target.optionalProperty = nil
        }

        XCTAssertNotNil(self.optionalProperty)
        self.cleanupPool.cleanup()
        XCTAssertNil(self.optionalProperty)
    }
	
}
