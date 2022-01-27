//
//  Collection+PluckTests.swift
//  BXSwiftUtils
//
//  Created by Stefan Fochler on 28.03.18.
//  Copyright © 2018 Boinx Software Ltd. & Imagine GbR. All rights reserved.
//

import XCTest
import BXSwiftUtils

// Internal test class
fileprivate class SomeClass
{
    let intProp: Int
    
    init(intProp: Int)
    {
        self.intProp = intProp
    }
}

// Must be hashable to be used within Set.
extension SomeClass: Hashable
{
    var hashValue: Int { return ObjectIdentifier(self).hashValue }
    
    static func ==(lhs: SomeClass, rhs: SomeClass) -> Bool
    {
        return ObjectIdentifier(lhs) == ObjectIdentifier(rhs)
    }
}


class Collection_PluckTests: XCTestCase
{

    /*
     Asserts that `map(to:)` gives the correct result for arrays.
     */
    func testArray()
    {
        let arr = [
            SomeClass(intProp: 10),
            SomeClass(intProp: 42),
            SomeClass(intProp: 100),
        ]
        
        let result = arr.pluck(\.intProp)
        
        XCTAssertEqual(result, [10, 42, 100])
    }

    /*
     Asserts that `map(to:)` is available on other collection types, e.g. a Set.
     */
    func testSet()
    {
        let set: Set = [
            SomeClass(intProp: 10),
            SomeClass(intProp: 100),
            SomeClass(intProp: 42),
            SomeClass(intProp: 100)
        ]
        
        let result = set.pluck(\.intProp)
        
        XCTAssertEqual(Set(result), Set([10, 42, 100]))
    }
    
}

