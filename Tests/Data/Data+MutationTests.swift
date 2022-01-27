//
//  URL+ExtendedAttributesTests.swift
//  BXSwiftUtils
//
//  Created by Peter Baumgartner on 18.10.18.
//  Copyright © 2018 Boinx Software Ltd. & Imagine GbR. All rights reserved.
//

import XCTest
import BXSwiftUtils

class Data_MutationTests : XCTestCase
{

	// Tests XOR for Data of equal length
	
	func testEqualLengthXOR()
    {
		let array00 = Array<UInt8>(repeating:0x00, count:1000)
		let arrayFF  = Array<UInt8>(repeating:0xFF, count:1000)
		let array55 = Array<UInt8>(repeating:0x55, count:1000)
		let arrayAA   = Array<UInt8>(repeating:0xAA, count:1000)
		
		let data00 = Data(bytes:array00)
		let dataFF = Data(bytes:arrayFF)
		let data55 = Data(bytes:array55)
		let dataAA = Data(bytes:arrayAA)

		var data = Data(bytes:array00)

		data.xor(with:dataFF)
		XCTAssertEqual(data,dataFF)
 
 		data.xor(with:dataFF)
		XCTAssertEqual(data,data00)
		
 		data.xor(with:data55)
		XCTAssertEqual(data,data55)
		
 		data.xor(with:dataFF)
		XCTAssertEqual(data,dataAA)
		
 		data.xor(with:dataFF)
		XCTAssertEqual(data,data55)
		
 		data.xor(with:data55)
		XCTAssertEqual(data,data00)
   }


	// Tests XOR for Data of different length with infinite repeating
	
	func testInfiniteRepeatingXOR()
    {
		let arrayFF  = Array<UInt8>(repeating:0xFF, count:100)
		let array55 = Array<UInt8>(repeating:0x55, count:100)
		
		let dataFF = Data(bytes:arrayFF)
		let data55 = Data(bytes:array55)

		let array = Array<UInt8>(repeating:0x00, count:1000)
		var data = Data(bytes:array)

		data.xor(with:dataFF)
		XCTAssertEqual(data, Data(bytes:Array<UInt8>(repeating:0xFF, count:1000)))
 
		data.xor(with:dataFF)
		XCTAssertEqual(data, Data(bytes:Array<UInt8>(repeating:0x00, count:1000)))
 
		data.xor(with:data55)
		XCTAssertEqual(data, Data(bytes:Array<UInt8>(repeating:0x55, count:1000)))
 
		data.xor(with:dataFF)
		XCTAssertEqual(data, Data(bytes:Array<UInt8>(repeating:0xAA, count:1000)))
  }


	// Tests XOR for Data of different length with finite repeating

	func testFiniteRepeatingXOR()
    {
		let data1 = Data(bytes:[0x00,0x00,0x00,0x00,0x00,0x00])
		let data2 = Data(bytes:[0xFF,0xFF,0xFF,0x00,0x00,0x00])
		let data3 = Data(bytes:[0x55,0x55,0x55,0x00,0x00,0x00])
		let data4 = Data(bytes:[0xAA,0xAA,0xAA,0x00,0x00,0x00])

		let key2 = Data(bytes:[0xFF])
		let key3 = Data(bytes:[0x55])
		let key4 = Data(bytes:[0xAA])

		let array = Array<UInt8>(repeating:0x00, count:6)
		var data = Data(bytes:array)

		data.xor(with:key2,maximumRepeatCount:3)
		XCTAssertEqual(data,data2)

		data.xor(with:key2,maximumRepeatCount:3)
		XCTAssertEqual(data,data1)

		data.xor(with:key3,maximumRepeatCount:3)
		XCTAssertEqual(data,data3)

		data.xor(with:data2,maximumRepeatCount:3)
		XCTAssertEqual(data,data4)

		data.xor(with:key4,maximumRepeatCount:3)
		XCTAssertEqual(data,data1)

		data.xor(with:key2,maximumRepeatCount:2)
		XCTAssertNotEqual(data,data2)
	}

}
