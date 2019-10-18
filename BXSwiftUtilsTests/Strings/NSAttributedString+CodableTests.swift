//
//  NSAttributedString+CodableTests.swift
//  BXSwiftUtils
//
//  Created by Stefan Fochler on 19.04.18.
//  Copyright © 2018 Boinx Software Ltd. & Imagine GbR. All rights reserved.
//

import XCTest
//import BXSwiftUtils

fileprivate struct MyContainer: Codable
{
    var string: NSAttributedString
    
    init()
    {
        self.string = NSAttributedString(string: "SomeDefaultValue")
    }
    
    enum CodingKeys: String, CodingKey
    {
        case string
    }
    
    init(from decoder: Decoder) throws
    {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        self.string = try container.decode(NSAttributedString.self, forKey: .string)
    }
}

fileprivate struct MyOptionalContainer: Codable
{
    var string: NSAttributedString?
    
    init()
    {
        self.string = NSAttributedString(string: "SomeDefaultValue")
    }
    
    enum CodingKeys: String, CodingKey
    {
        case string
    }
    
    init(from decoder: Decoder) throws
    {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        self.string = try container.decodeIfPresent(NSAttributedString.self, forKey: .string)
    }
}


class NSAttributedString_CodableTests: XCTestCase
{

    func testEncodeAndDecode()
    {
        // Setup the container struct with a non-default value for the attributed string
        var myContainer = MyContainer()
        myContainer.string = NSAttributedString(string: "ExpectedValue")
        
        // Encode the container struct
        let encoder = PropertyListEncoder()
        let data = try! encoder.encode(myContainer)
        
        // Decode the container struct again
        let decoder = PropertyListDecoder()
        let newContainer = try! decoder.decode(MyContainer.self, from: data)

        XCTAssertEqual(newContainer.string, NSAttributedString(string: "ExpectedValue"))
    }

    func testDecodeIfPresent()
    {
        // Setup the container struct with a non-default value for the attributed string
        var myContainer = MyOptionalContainer()
        myContainer.string = nil
        
        // Encode the container struct
        let encoder = PropertyListEncoder()
        let data = try! encoder.encode(myContainer)
        
        // Decode the container struct again
        let decoder = PropertyListDecoder()
        let newContainer = try! decoder.decode(MyOptionalContainer.self, from: data)

        XCTAssertEqual(newContainer.string, nil)
    }
}
