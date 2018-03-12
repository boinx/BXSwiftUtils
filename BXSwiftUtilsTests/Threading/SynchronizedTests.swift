//
//  SynchronizedTests.swift
//  BXSwiftUtils
//
//  Created by Stefan Fochler on 12.03.18.
//  Copyright © 2018 Boinx Software Ltd. & Imagine GbR. All rights reserved.
//

import XCTest
import BXSwiftUtils

class SynchronizedTests: XCTestCase {
    
    enum TestError: Error {
        case someError
    }

    /*
     Asserts that the given block is executed.
     */
    func testSynchronized() {
        var count = 0
        
        synchronized(self)
        {
            count += 1
        }
        
        XCTAssertEqual(count, 1, "code was executed")
    }

    /*
     Asserts that the block can return a value.
     */
    func testSynchronizedReturn() {
        let count = synchronized(self) {
            1
        }
        
        XCTAssertEqual(count, 1, "code returned the correct value")
    }
    
    /*
     Asserts that the block may throw an error and that the error is re-thrown.
     */
    func testSynchronizedThrows() {
        XCTAssertThrowsError(try synchronized(self,
        {
            throw TestError.someError
        }), "rethrows error")
    }

}
