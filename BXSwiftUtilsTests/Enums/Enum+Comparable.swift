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

class Enum_Comparable: XCTestCase {

    func testExample() {
        XCTAssert(State.waiting < State.running)
        XCTAssertEqual([State.running, State.finished, State.waiting].max(), State.finished)
    }
    
}
