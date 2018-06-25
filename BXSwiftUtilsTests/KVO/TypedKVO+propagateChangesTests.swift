//
//  TypedKVO+propagateChangesTests.swift
//  BXSwiftUtils
//
//  Created by Stefan Fochler on 25.06.18.
//  Copyright © 2018 Boinx Software Ltd. & Imagine GbR. All rights reserved.
//

import XCTest
import BXSwiftUtils


class TypedKVO_PropagateChangesTests: XCTestCase
{
    @objc dynamic private var sourceProperty: String = "source"
    @objc dynamic private var destinationProperty: String = "destination"
    
    /*
     Asserts that propagation works.
     */
    func testBasicFunctionality()
    {
        var count = 0

        let propagation = TypedKVO.propagateChanges(from: self, \.sourceProperty, to: self, \.destinationProperty)
        let observation = TypedKVO(self, \.destinationProperty, options: []) { (target, change) in
            count += 1
        }
        
        self.sourceProperty = "changed value"
        
        XCTAssertEqual(count, 1)
    }
    
    /*
     Asserts that async propagation works.
     */
    func testAsyncPropagation()
    {
        let expectation = XCTestExpectation(description: "async propagation")
        var count = 0

        let propagation = TypedKVO.propagateChanges(from: self, \.sourceProperty, to: self, \.destinationProperty, asyncOn: DispatchQueue.main)
        let observation = TypedKVO(self, \.destinationProperty, options: []) { (target, change) in
            count += 1
            expectation.fulfill()
        }
        
        self.sourceProperty = "changed value"
        
        XCTAssertEqual(count, 0)
        
        wait(for: [expectation], timeout: 1.0)
        
        XCTAssertEqual(count, 1)
    }
}
