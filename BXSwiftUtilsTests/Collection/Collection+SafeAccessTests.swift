//
//  Collection+SafeAccessTest.swift
//  BXSwiftUtilsTests-macOS
//
//  Created by Stefan Fochler on 08.03.18.
//  Copyright © 2018 Boinx Software Ltd. All rights reserved.
//

import XCTest
import BXSwiftUtils


class Collection_SafeAccessTests: XCTestCase
{
    let data = ["hello", "world", "one", "two", "three"]
    let empty: [String] = []
    
    func testSuccessfullAccess()
    {
        XCTAssertEqual(data[safe: 0], "hello", "retrieves existing element")
    }

    func testOutOfBoundsAccess()
    {
        XCTAssertEqual(data[safe: 1337], nil, "safely returns nil")
    }
    
    func testClosedRangeAccess()
    {
        XCTAssertEqual(data[safe: 0...1], ["hello", "world"])
        XCTAssertEqual(data[safe: 1...1], ["world"])
        XCTAssertEqual(data[safe: 2...4], ["one", "two", "three"])
        XCTAssertEqual(data[safe: 2...10], ["one", "two", "three"])
        XCTAssertEqual(data[safe: -1...1], ["hello", "world"])
        XCTAssertEqual(Array(data[safe: -10...10]), data)
        
        XCTAssertEqual(data[safe: 10...20], [])
        XCTAssertEqual(data[safe: -20...(-10)], [])
        XCTAssertEqual(empty[safe: -10...10], [])
    }
    
    func testRangeAccess()
    {
        XCTAssertEqual(data[safe: 0..<2], ["hello", "world"])
        XCTAssertEqual(data[safe: 0..<1], ["hello"])
        XCTAssertEqual(data[safe: 2..<5], ["one", "two", "three"])
        XCTAssertEqual(data[safe: 2..<10], ["one", "two", "three"])
        XCTAssertEqual(data[safe: -1..<2], ["hello", "world"])
        XCTAssertEqual(Array(data[safe: -10..<10]), data)
        
        XCTAssertEqual(data[safe: 10..<20], [])
        XCTAssertEqual(data[safe: -20..<(-10)], [])
        XCTAssertEqual(empty[safe: -10..<10], [])
    }
}
