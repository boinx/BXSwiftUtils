//
//  Array+AllEqualTests.swift
//  BXSwiftUtils
//
//  Created by Stefan Fochler on 14.03.18.
//  Copyright © 2018 Boinx Software Ltd. & Imagine GbR. All rights reserved.
//

import XCTest
import BXSwiftUtils

class Array_AllEqualTests: XCTestCase {

    /*
     Test the basic properties of the allEqual method
     */
    func testAllEqual() {
        XCTAssertTrue([true, true, true].allEqual(to: true)!)
        XCTAssertFalse([true, false, true].allEqual(to: true)!)
        XCTAssertTrue([42, 42].allEqual(to: 42)!)
        XCTAssertNil([].allEqual(to: false))
    }
    
}
