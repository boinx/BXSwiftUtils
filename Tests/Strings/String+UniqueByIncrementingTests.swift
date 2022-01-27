//
//  String+UniqueByIncrementingTests.swift
//  BXSwiftUtils
//
//  Created by Stefan Fochler on 11.09.18.
//  Copyright © 2018 Boinx Software Ltd. & Imagine GbR. All rights reserved.
//

import XCTest
import BXSwiftUtils

class String_UniqueByIncrementingTests: XCTestCase {

    func testNonCollidingString()
    {
        XCTAssertEqual("bla".uniqueStringByIncrementing(rejectIf: { _ in false }), "bla")
    }
    
    func testSimpleCollidingString()
    {
        let existing = ["bla"]
        XCTAssertEqual("bla".uniqueStringByIncrementing(rejectIf: existing.contains), "bla 2")
    }
    
    func testMultipleCollidingString()
    {
        let existing = ["bla", "bla 2", "bla 3"]
        XCTAssertEqual("bla".uniqueStringByIncrementing(rejectIf: existing.contains), "bla 4")
    }
    
    func testStringEndingInDigitsIsNotIncrementedWhenNoAnnotationIsPassed()
    {
        let existing = ["show 2018"]
        XCTAssertEqual("show 2018".uniqueStringByIncrementing(rejectIf: existing.contains), "show 2018 2")
    }
    
    func testAppendCopyWithoutCollision()
    {
        let existing: [String] = []
        XCTAssertEqual("bla".uniqueStringByIncrementing(rejectIf: existing.contains, appendAnnotation: "copy"), "bla copy")
        XCTAssertEqual("bla copy".uniqueStringByIncrementing(rejectIf: existing.contains, appendAnnotation: "copy"), "bla copy")
    }
    
    func testSimpleCollisionContainingCopy()
    {
        let existing = ["bla copy", "bla copy 3"]
        XCTAssertEqual("bla".uniqueStringByIncrementing(rejectIf: existing.contains, appendAnnotation: "copy"), "bla copy 2")
        XCTAssertEqual("bla copy 3".uniqueStringByIncrementing(rejectIf: existing.contains, appendAnnotation: "copy"), "bla copy 4")
    }
    
    func testComplexCollisionContainingCopy()
    {
        let existing = ["bla copy", "bla copy 2"]
        XCTAssertEqual("bla copy".uniqueStringByIncrementing(rejectIf: existing.contains, appendAnnotation: "copy"), "bla copy 3")
        XCTAssertEqual("bla copy 2".uniqueStringByIncrementing(rejectIf: existing.contains, appendAnnotation: "copy"), "bla copy 3")
    }
    
    func testAppendingWithSeparator()
    {
        let existing = ["bla--copy", "bla--copy--2"]
        XCTAssertEqual("bla--copy".uniqueStringByIncrementing(rejectIf: existing.contains, appendAnnotation: "copy", separator: "--"), "bla--copy--3")
        XCTAssertEqual("bla--copy--2".uniqueStringByIncrementing(rejectIf: existing.contains, appendAnnotation: "copy", separator: "--"), "bla--copy--3")
    }
    
    func testWithFileExtension()
    {
        let existing = ["bla.jpg", "foo copy.jpg"]
        XCTAssertEqual("bla.jpg".uniqueFilenameByIncrementing(rejectIf: existing.contains), "bla 2.jpg")
        XCTAssertEqual("bla.jpg".uniqueFilenameByIncrementing(rejectIf: existing.contains, appendAnnotation: "copy"), "bla copy.jpg")
        XCTAssertEqual("foo.jpg".uniqueFilenameByIncrementing(rejectIf: existing.contains, appendAnnotation: "copy"), "foo copy 2.jpg")
    }
}
