//
//  Enum+Comparable.swift
//  BXSwiftUtils
//
//  Created by Stefan Fochler on 24.09.18.
//  Copyright © 2018 Boinx Software Ltd. & Imagine GbR. All rights reserved.
//

import XCTest
import BXSwiftUtils

fileprivate enum State: Int, ComparableEnum
{
    case waiting
    case running
    case finished
}

#if swift(>=4.2)

fileprivate enum StringState: String, CaseIterable, ComparableEnum
{
    case waiting
    case running
    case finished
}

#endif

class Enum_Comparable: XCTestCase
{

    func testIntEnum()
    {
        XCTAssert(State.waiting < State.running)
        XCTAssertEqual([State.running, State.finished, State.waiting].max(), State.finished)
    }
    
    #if swift(>=4.2)
    
    func testStringEnum()
    {
        XCTAssert(StringState.waiting < StringState.running)
        XCTAssertEqual([StringState.running, StringState.finished, StringState.waiting].max(), StringState.finished)
    }
    
    #endif
    
}
