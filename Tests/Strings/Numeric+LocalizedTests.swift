//
//  Numeric+LocalizedTests.swift
//  BXSwiftUtils
//
//  Created by Peter Baumgartner on 12.10.18.
//  Copyright © 2018 Boinx Software Ltd. & Imagine GbR. All rights reserved.
//

import XCTest
import BXSwiftUtils

class Numeric_LocalizedTest : XCTestCase
{
	private let US = Locale(identifier:"en_US")
	private let DE = Locale(identifier:"de_DE")
	
	func testIntToString()
    {
		XCTAssertTrue( (1920).localized(locale: US) == "1920" )
		XCTAssertTrue( (1920).localized(with:"#.#px", locale: US) == "1920px" )
		XCTAssertTrue( (1920).localized(with:"#.# px", locale: US) == "1920 px" )
	}
	
	func testDoubleToString()
    {
		XCTAssertTrue( (1.234).localized(locale: US) == "1.2" )
        XCTAssertTrue( (1.234).localized(locale: DE) == "1,2" )
		XCTAssertTrue( (1.234).localized(with:"#.#s", locale: US) == "1.2s" )
		XCTAssertTrue( (1.234).localized(with:"#.#s", locale: DE) == "1,2s" )
 		XCTAssertTrue( (1.234).localized(with:"#.##s", locale: DE) == "1,23s" )
	}
	
	func testStripCharacters()
    {
 		XCTAssertTrue( "1234unit".strippingNonNumericCharacters() == "1234" )
 		XCTAssertTrue( "1234 unit".strippingNonNumericCharacters() == "1234" )
  		XCTAssertTrue( "12 34".strippingNonNumericCharacters() == "1234" )
  		XCTAssertTrue( " 1234 ".strippingNonNumericCharacters() == "1234" )
  		XCTAssertTrue( "bla1234laber".strippingNonNumericCharacters() == "1234" )
	}
	
	func testStringToInt()
    {
 		let pxFormatter = NumberFormatter.forInteger(with:"#px")

 		XCTAssertTrue( "1234".intValue(with:pxFormatter) == 1234 )
  		XCTAssertTrue( " 1234 ".intValue(with:pxFormatter) == 1234 )
  		XCTAssertTrue( "12 34".intValue(with:pxFormatter) == 1234 )
  		XCTAssertTrue( "1234px".intValue(with:pxFormatter) == 1234 )
  		XCTAssertTrue( "1234 px".intValue(with:pxFormatter) == 1234 )
  		XCTAssertTrue( "1234 otherUnit".intValue(with:pxFormatter) == 1234 )
	}
	
	func testStringToDouble()
    {
 		let angleFormatter = NumberFormatter.forInteger(with:"#.#°")

 		XCTAssertTrue( "12.34".doubleValue(with:angleFormatter) == 12.34 )
  		XCTAssertTrue( " 12.34 ".doubleValue(with:angleFormatter) == 12.34 )
  		XCTAssertTrue( "12.34°".doubleValue(with:angleFormatter) == 12.34 )
  		XCTAssertTrue( "12.34 °".doubleValue(with:angleFormatter) == 12.34 )
  		XCTAssertTrue( "12.34 otherUnit".doubleValue(with:angleFormatter) == 12.34 )
	}
	
}
