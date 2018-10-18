//
//  URL+ExtendedAttributesTests.swift
//  BXSwiftUtils
//
//  Created by Peter Baumgartner on 18.10.18.
//  Copyright © 2018 Boinx Software Ltd. & Imagine GbR. All rights reserved.
//

import XCTest
import BXSwiftUtils

class URL_ExtendedAttributesTests: XCTestCase
{

    private var testURL : URL
    {
		let path = NSTemporaryDirectory()
		return URL(fileURLWithPath:path).appendingPathComponent("test")
    }


	func testExtendedAttributeExists()
    {
		let url = self.testURL
		try! "This is a test".write(to:url, atomically:true, encoding:.utf8)
		
		let exists = url.hasExtendedAttribute(forName:"com.boinx.unknown")
		XCTAssertEqual(exists,false)

		try! FileManager.default.removeItem(at:url)
    }
	
	
	func testExtendedAttributeString()
    {
		let url = self.testURL
		let key = "com.boinx.foo"
		let value1:String = "bar"
		
		try! "This is a test".write(to:url, atomically:true, encoding:.utf8)
		
		try! url.setExtendedAttribute(value1, forName:key)

		let exists1 = url.hasExtendedAttribute(forName:key)
		XCTAssertEqual(exists1,true)

		let value2:String = try! url.extendedAttribute(forName:key)
		XCTAssertEqual(value1,value2)
		
		try! url.removeExtendedAttribute(forName:key)
		let exists2 = url.hasExtendedAttribute(forName:key)
		XCTAssertEqual(exists2,false)

		try! FileManager.default.removeItem(at:url)
    }
	
	
	func testExtendedAttributeInt()
    {
		let url = self.testURL
		let key = "com.boinx.foo"
		let value1:Int = 42
		
		try! "This is a test".write(to:url, atomically:true, encoding:.utf8)
		
		try! url.setExtendedAttribute(value1, forName:key)

		let exists1 = url.hasExtendedAttribute(forName:key)
		XCTAssertEqual(exists1,true)

		let value2:Int = try! url.extendedAttribute(forName:key)
		XCTAssertEqual(value1,value2)
		
		try! url.removeExtendedAttribute(forName:key)
		let exists2 = url.hasExtendedAttribute(forName:key)
		XCTAssertEqual(exists2,false)

		try! FileManager.default.removeItem(at:url)
    }
	
	
	func testExtendedAttributeBool()
    {
		let url = self.testURL
		let key = "com.boinx.foo"
		let value1:Bool = true
		
		try! "This is a test".write(to:url, atomically:true, encoding:.utf8)
		
		try! url.setExtendedAttribute(value1, forName:key)

		let exists1 = url.hasExtendedAttribute(forName:key)
		XCTAssertEqual(exists1,true)

		let value2:Bool = try! url.extendedAttribute(forName:key)
		XCTAssertEqual(value1,value2)
		
		try! url.removeExtendedAttribute(forName:key)
		let exists2 = url.hasExtendedAttribute(forName:key)
		XCTAssertEqual(exists2,false)

		try! FileManager.default.removeItem(at:url)
    }

}
