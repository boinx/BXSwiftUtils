//
//  Collection+Flatten.swift
//  BXSwiftUtils
//
//  Created by Stefan Fochler on 07.05.18.
//  Copyright © 2018 Boinx Software Ltd. & Imagine GbR. All rights reserved.
//

import XCTest
import BXSwiftUtils

class Collection_Flatten: XCTestCase {

    /*
     Asserts that a nested array of integers is correctly flattened
     */
    func testFlatten() {
        let input = [[1,2,3], [4], [], [5,6]]
        let result = input.flatten()
        
        XCTAssertEqual([1,2,3,4,5,6], result)
    }
    
}
