//
//  Comparable+ClipTests.swift
//  BXSwiftUtils-Tests
//
//  Created by Stefan Fochler on 22.11.18.
//  Copyright © 2018 Boinx Software Ltd. & Imagine GbR. All rights reserved.
//

import XCTest
import BXSwiftUtils

class Comparable_ClipTests : XCTestCase
{
	func testClippedMinMax()
	{
		XCTAssertEqual(5.0.clipped(min: 0.0, max: 10.0), 5.0)
		XCTAssertEqual(5.0.clipped(min: 0.0, max: 5.0), 5.0)
		XCTAssertEqual(5.0.clipped(min: 0.0, max: 4.0), 4.0)
		XCTAssertEqual(5.0.clipped(min: 6.0, max: 10.0), 6.0)
	}
	
	func testClippedRange()
	{
		XCTAssertEqual(5.0.clipped(to: 0...10), 5.0)
		XCTAssertEqual(5.0.clipped(to: 0...5), 5.0)
		XCTAssertEqual(5.0.clipped(to: 0...4), 4.0)
		XCTAssertEqual(5.0.clipped(to: 6...10), 6.0)
	}
	
	func testClipMinMax()
	{
		var value = 5.0
		value.clip(min: 2.0, max: 3.0)
		XCTAssertEqual(value, 3.0)
	}
	
	func testClipRange()
	{
		var value = 5.0
		value.clip(to: 2...3)
		XCTAssertEqual(value, 3.0)
	}
	
	func testInvalidMinMax()
	{
		XCTAssertThrowsError(try NSException.toSwiftError
		{
			let _ = 5.0.clipped(min: 10.0, max: 0)
		})
		XCTAssertThrowsError(try NSException.toSwiftError
		{
			var value = 5.0
			value.clip(min: 10.0, max: 0)
		})
	}
}
