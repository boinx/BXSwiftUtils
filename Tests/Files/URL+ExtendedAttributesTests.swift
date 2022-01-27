//
//  URL+ExtendedAttributesTests.swift
//  BXSwiftUtils
//
//  Created by Peter Baumgartner on 18.10.18.
//  Copyright © 2018 Boinx Software Ltd. & Imagine GbR. All rights reserved.
//

import XCTest
import BXSwiftUtils

class URL_ExtendedAttributesTests : XCTestCase
{
	private var url = URL(fileURLWithPath:"/")
	private let key = "com.boinx.foo"


	// Creates a temp file
	
	override open func setUp()
	{
		let path = NSTemporaryDirectory()
		self.url = URL(fileURLWithPath:path).appendingPathComponent("tmp")
		try! "This is a test".write(to:url, atomically:true, encoding:.utf8)
	}
	
	// Deletes the temp file
	
	override open func tearDown()
	{
		try! FileManager.default.removeItem(at:url)
	}


	// Test that an attribute for an unknown key doesn't exist
	
	func testExists()
    {
		let exists = url.hasExtendedAttribute(forName:"com.boinx.unknown")
		XCTAssertEqual(exists,false)
    }


	// Test String attribute
	
	func testStringAttribute()
    {
		let value1:String = "bar"
		
		try! url.setExtendedAttribute(value1, forName:key)

		let exists1 = url.hasExtendedAttribute(forName:key)
		XCTAssertEqual(exists1,true)

		let value2:String = url.extendedAttribute(forName:key)!
		XCTAssertEqual(value1,value2)
		
		try! url.removeExtendedAttribute(forName:key)
		
		let exists2 = url.hasExtendedAttribute(forName:key)
		XCTAssertEqual(exists2,false)
    }


	func testLongStringAttribute()
    {
		let value1:String = "This is a really long string that will not into a 16 byte buffer - so this is the real test!!!"
		
		try! url.setExtendedAttribute(value1, forName:key)

		let exists1 = url.hasExtendedAttribute(forName:key)
		XCTAssertEqual(exists1,true)

		let value2:String = url.extendedAttribute(forName:key)!
		XCTAssertEqual(value1,value2)
		
		try! url.removeExtendedAttribute(forName:key)
		
		let exists2 = url.hasExtendedAttribute(forName:key)
		XCTAssertEqual(exists2,false)
    }


	// Test Int attribute
	
	func testIntAttribute()
    {
		let value1:Int = 42
		
		try! url.setExtendedAttribute(value1, forName:key)

		let exists1 = url.hasExtendedAttribute(forName:key)
		XCTAssertEqual(exists1,true)

		let value2:Int = url.extendedAttribute(forName:key)!
		XCTAssertEqual(value1,value2)
		
		try! url.removeExtendedAttribute(forName:key)
		
		let exists2 = url.hasExtendedAttribute(forName:key)
		XCTAssertEqual(exists2,false)
    }


	// Test Bool attribute
	
	func testBoolAttribute()
    {
		let value1:Bool = true
		
		try! url.setExtendedAttribute(value1, forName:key)

		let exists1 = url.hasExtendedAttribute(forName:key)
		XCTAssertEqual(exists1,true)

		let value2:Bool = url.extendedAttribute(forName:key)!
		XCTAssertEqual(value1,value2)
		
		try! url.removeExtendedAttribute(forName:key)

		let exists2 = url.hasExtendedAttribute(forName:key)
		XCTAssertEqual(exists2,false)
    }


	// Test Data attribute
	
	func testDataAttribute()
    {
		let bytes:[UInt8] = [0x18,0x03,0x19,0x69]
		let value1 = Data(bytes:bytes)
		
		try! url.setExtendedAttribute(value1, forName:key)

		let exists1 = url.hasExtendedAttribute(forName:key)
		XCTAssertEqual(exists1,true)

		let value2:Data = url.extendedAttribute(forName:key)!
		XCTAssertEqual(value1,value2)
		
		try! url.removeExtendedAttribute(forName:key)

		let exists2 = url.hasExtendedAttribute(forName:key)
		XCTAssertEqual(exists2,false)
    }

}
