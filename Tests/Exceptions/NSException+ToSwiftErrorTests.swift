//
//  NSException+ToSwiftErrorTests.swift
//  BXSwiftUtils
//
//  Created by Stefan Fochler on 27.03.18.
//  Copyright © 2018 Boinx Software Ltd. & Imagine GbR. All rights reserved.
//

import XCTest
import BXSwiftUtils

class NSException_ToSwiftErrorTests: XCTestCase {

    /*
     Asserts that a provoked NSException is captured and converted into a Swift Error.
     */
    func testConvertsExceptionIntoError()
    {
        XCTAssertThrowsError(try NSException.toSwiftError
        {
            // provoke an out of bounds NSException
            let arr = NSArray()
            arr.object(at: 1)
        })
    }

}
