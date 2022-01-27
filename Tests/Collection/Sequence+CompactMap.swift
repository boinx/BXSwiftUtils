//
//  Sequence+CompactMap.swift
//  BXSwiftUtils
//
//  Created by Stefan Fochler on 01.05.18.
//  Copyright © 2018 Boinx Software Ltd. & Imagine GbR. All rights reserved.
//

import XCTest
import BXSwiftUtils

class Sequence_CompactMap: XCTestCase
{

    func testExample()
    {
        let input = [1, 2, 3, 4, 5, 6]
        
        // Poor man's filter of odd values...
        let result = input.compactMap
        { value -> Int? in
            if value % 2 == 0
            {
                return value
            }
            else
            {
                return nil
            }
        }
        
        XCTAssertEqual(result, [2, 4, 6])
    }

}
