//
//  Collection+SafeAccessTest.swift
//  BXSwiftUtilsTests-macOS
//
//  Created by Stefan Fochler on 08.03.18.
//  Copyright © 2018 Boinx Software Ltd. All rights reserved.
//

import XCTest
import BXSwiftUtils


class Collection_SafeAccessTest: XCTestCase {

    let data = ["hello", "world"]
    
    func testSuccessfullAccess() {
        XCTAssertEqual(data[safe: 0], "hello", "retrieves existing element")
    }

    func testOutOfBoundsAccess() {
        XCTAssertEqual(data[safe: 1337], nil, "safely returns nil")
    }

}
