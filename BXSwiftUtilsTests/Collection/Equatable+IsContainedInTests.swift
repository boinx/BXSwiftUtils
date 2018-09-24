//
//  Equatable+IsContainedInTests.swift
//  BXSwiftUtils
//
//  Created by Stefan Fochler on 24.09.18.
//  Copyright © 2018 Boinx Software Ltd. & Imagine GbR. All rights reserved.
//

import XCTest
import BXSwiftUtils

fileprivate enum State
{
    case waiting
    case running
    case finished
}

class Equatable_IsContainedInTests: XCTestCase
{
    func testIsContainedInFunction()
    {
        XCTAssert(State.waiting.isContained(in: [.waiting, .running]))
        XCTAssertFalse(State.waiting.isContained(in: [.running]))
        XCTAssertFalse(State.waiting.isContained(in: []))
    }
    
    func testOperator()
    {
        XCTAssert(State.waiting ~== [.waiting, .running])
        XCTAssertFalse(State.waiting ~== [.running])
        XCTAssertFalse(State.waiting ~== [])
    }
}
