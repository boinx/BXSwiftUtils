//
//  Dictionary+EnumKeysTests.swift
//  BXSwiftUtils
//
//  Created by Stefan Fochler on 18.04.18.
//  Copyright © 2018 Boinx Software Ltd. & Imagine GbR. All rights reserved.
//

import XCTest
import BXSwiftUtils

class Dictionary_EnumKeysTests: XCTestCase
{
    private enum MyKeys: String
    {
        case stringKey1
        case stringKey2
    }
    
    /*
     Asserts that when using subscript access:
      - existing values are accessible
      - existing values can be changed
      - new values can be added
     */
    func testSettingWithoutRawvalueExtension()
    {
        var stringDict: [String: Int] = ["stringKey1": 42]
        
        XCTAssertEqual(stringDict[MyKeys.stringKey1], 42)
        
        stringDict[MyKeys.stringKey1] = 23
        stringDict[MyKeys.stringKey2] = 100
        
        XCTAssertEqual(stringDict, ["stringKey1": 23, "stringKey2": 100])
    }
    
    /*
     Asserts that when using the namespaced dictionary:
      - existing values with correct keys are accessible
      - existing values can be changed
      - new values can be added
     */
    func testNamespacing()
    {
        var stringDict: [String: Int] = ["stringKey1": 42]
        
        stringDict.using(MyKeys.self)
        { (dict) in
            XCTAssertEqual(dict[.stringKey1], 42)
            
            dict[.stringKey1] = 23
            dict[.stringKey2] = 100
        }
        
        XCTAssertEqual(stringDict, ["stringKey1": 23, "stringKey2": 100])
    }
}
