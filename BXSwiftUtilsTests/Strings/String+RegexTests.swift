//
//  String+UniqueByIncrementingTests.swift
//  BXSwiftUtils
//
//  Created by Peter Baumgartner on 12.10.18.
//  Copyright © 2018 Boinx Software Ltd. & Imagine GbR. All rights reserved.
//

import XCTest
import BXSwiftUtils

class String_RegexTests: XCTestCase
{

	func testPositive()
    {
    	let str = "Bla Laber ABC Schwafel Sülz"
    	let matches = str.regexMatches(for:"ABC")
        XCTAssertEqual(matches,["ABC"])
    }
	
	func testNegative()
    {
    	let str = "Bla Laber ABC Schwafel Sülz"
    	let matches = str.regexMatches(for:"XYZ")
        XCTAssertEqual(matches,[])
    }
    
    func testMatchCount()
    {
    	let str = "Bla ABC Laber ABC Schwafel ABC Sülz"
    	let matches = str.regexMatches(for:"ABC")
        XCTAssertEqual(matches.count,3)
    }
	
    func testOperator()
    {
    	let str = "Bla Laber ABC Schwafel Sülz"
    	let matches = str ~= "ABC"
        XCTAssertEqual(matches,true)
    }
}
