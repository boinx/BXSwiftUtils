//
//  Weak.swift
//  BXSwiftUtils
//
//  Created by Stefan Fochler on 25.06.18.
//  Copyright © 2018 Boinx Software Ltd. & Imagine GbR. All rights reserved.
//

import XCTest
import BXSwiftUtils


class weakTests: XCTestCase
{
    /*
     Asserts that a weak reference is held.
     */
    func testBasicFunctionality()
    {
        var weakStr: Weak<NSString>?
        
        do
        {
            let strongStr = NSString(string: "hello world")
            weakStr = Weak(strongStr)
            
            // While the oirignal value is stil alive, the reference must point to the correct value.
            XCTAssertEqual(weakStr!.ref, strongStr)
        }
        
        // When the original value goes out of scope and gets deallocated, the reference must be nil.
        XCTAssertNil(weakStr!.ref)
    }
}
