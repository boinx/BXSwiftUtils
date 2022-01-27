//
//  Bool+OperatorsTests.swift
//  BXSwiftUtils
//
//  Created by Benjamin Federer on 05.12.18.
//  Copyright © 2018 Boinx Software Ltd. & Imagine GbR. All rights reserved.
//

import XCTest
import BXSwiftUtils

class Bool_OperatorsTests : XCTestCase
{
	func testORAndAssign()
	{
		var boolValue = false
		
		boolValue ||= false
		XCTAssertFalse(boolValue)	// 0 0 | 0
		
		boolValue ||= true
		XCTAssertTrue(boolValue)	// 0 1 | 1
		
		boolValue ||= true
		XCTAssertTrue(boolValue)	// 1 1 | 1
		
		boolValue ||= false
		XCTAssertTrue(boolValue)	// 1 0 | 1
	}
	
	func testANDAndAssign()
	{
		var boolValue = false
		
		boolValue &&= false
		XCTAssertFalse(boolValue) 	// 0 0 | 0
		
		boolValue &&= true
		XCTAssertFalse(boolValue) 	// 0 1 | 0
		
		boolValue = true
		
		boolValue &&= true
		XCTAssertTrue(boolValue) 	// 1 1 | 1
		
		boolValue &&= false
		XCTAssertFalse(boolValue) 	// 1 0 | 0
	}
	
	func testXOR()
	{
		var boolValue: Bool = false
		
		boolValue = false ^^ false
		XCTAssertFalse(boolValue) 	// 0 0 | 0
		
		boolValue = false ^^ true
		XCTAssertTrue(boolValue) 	// 0 1 | 1
		
		boolValue = true ^^ false
		XCTAssertTrue(boolValue) 	// 1 0 | 1
		
		boolValue = true ^^ true
		XCTAssertFalse(boolValue) 	// 1 1 | 0
	}
	
	func testXORPrecedenceLeftToRight() // same as right to left
	{
		var boolValue: Bool = false
		
		boolValue = false ^^ false ^^ true
		XCTAssertTrue(boolValue)
		
		boolValue = false ^^ false ^^ false
		XCTAssertFalse(boolValue)
		
		boolValue = false ^^ true ^^ true
		XCTAssertFalse(boolValue)
		
		boolValue = false ^^ true ^^ false
		XCTAssertTrue(boolValue)
		
		boolValue = true ^^ false ^^ true
		XCTAssertFalse(boolValue)
		
		boolValue = true ^^ false ^^ false
		XCTAssertTrue(boolValue)
		
		boolValue = true ^^ true ^^ false
		XCTAssertFalse(boolValue)
		
		boolValue = true ^^ true ^^ true
		XCTAssertTrue(boolValue)
	}
}
