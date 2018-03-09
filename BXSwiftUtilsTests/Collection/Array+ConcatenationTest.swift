//
//  Array+ConcatenationTest.swift
//  BXSwiftUtilsTests-macOS
//
//  Created by Stefan Fochler on 08.03.18.
//  Copyright © 2018 Boinx Software Ltd. All rights reserved.
//

import XCTest
import BXSwiftUtils

class Array_ConcatenationTest: XCTestCase {

    func testPlusEqualsOperator() {
        var myArray = [1, 2, 3]
        myArray += 4
        XCTAssertEqual(myArray, [1, 2, 3, 4], "non-nil elements are appended")
    }
    
    func testPlusEqualsOperatorWithNil() {
        var myArray = [1, 2, 3]
        myArray += nil
        XCTAssertEqual(myArray, [1, 2, 3], "nil elements are not appended")
    }
    
    func testPlusOperatorAppend() {
        let myArray = [1, 2, 3]
        let newArray = myArray + 4
        XCTAssertEqual(myArray, [1, 2, 3], "original array is not modified")
        XCTAssertEqual(newArray, [1, 2, 3, 4], "new array is correctly concatenated")
    }
    
    func testPlusOperatorAppendNil() {
        let myArray = [1, 2, 3]
        let newArray = myArray + nil
        XCTAssertEqual(myArray, [1, 2, 3], "original array is not modified")
        XCTAssertEqual(newArray, [1, 2, 3], "new array is correctly concatenated")
    }

    func testPlusOperatorPrepend() {
        let myArray = [1, 2, 3]
        let newArray = 0 + myArray
        XCTAssertEqual(myArray, [1, 2, 3], "original array is not modified")
        XCTAssertEqual(newArray, [0, 1, 2, 3], "new array is correctly concatenated")
    }
    
    func testPlusOperatorPrependNil() {
        let myArray = [1, 2, 3]
        let newArray = nil + myArray
        XCTAssertEqual(myArray, [1, 2, 3], "original array is not modified")
        XCTAssertEqual(newArray, [1, 2, 3], "new array is correctly concatenated")
    }
    
}
