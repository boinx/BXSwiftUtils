//
//  BXLoggerTest.swift
//  BXSwiftUtils
//
//  Created by Stefan Fochler on 09.03.18.
//  Copyright © 2018 Boinx Software Ltd. & Imagine GbR. All rights reserved.
//

import XCTest
import BXSwiftUtils

class BXLoggerTests: XCTestCase {

    func testLevelComparable()
    {
        XCTAssertGreaterThan(BXLogger.Level.verbose, BXLogger.Level.warning)
    }

    func testAddDestination()
    {
        let expect = expectation(description: "Destination Called")
        
        var logger = BXLogger()
        logger.addDestination { (level, message) in
           expect.fulfill()
        }
        logger.print(level: .error, force: false, showLocation: false, message: { "bla" })
        
        waitForExpectations(timeout: 0.1, handler: nil)
    }
    
    func testDefaultLogLevel()
    {
        let expect = expectation(description: "Destination Called Twice")
        
        var count = 0;
        
        var logger = BXLogger()
        
        logger.addDestination { (level, message) in
            count += 1
            
            XCTAssert(level == .warning || level == .error, "level is warning or error")
            
            if count == 2
            {
                expect.fulfill()
            }
        }
        logger.verbose { "verbose" }
        logger.debug(showLocation: true) { "debug" }
        logger.warning { "warning" }
        logger.error { "error" }
        
        waitForExpectations(timeout: 0.1, handler: nil)
    }
    
    func testCustomLogLevel()
    {
        let expect = expectation(description: "Destination Called Twice")
        
        var count = 0;
        
        var logger = BXLogger()
        logger.maxLevel = .debug
        logger.addDestination { (level, message) in
            count += 1
            
            XCTAssert(level == .debug || level == .warning || level == .error, "level is debug, warning, or error")
            
            if count == 3
            {
                expect.fulfill()
            }
        }
        logger.verbose { "verbose" }
        logger.debug { "debug" }
        logger.warning { "warning" }
        logger.error(showLocation: true) { "error" }
        
        waitForExpectations(timeout: 0.1, handler: nil)
    }
    
    func testForceLog()
    {
        let expect = expectation(description: "Destination Called")
        
        var logger = BXLogger()
        logger.addDestination { (level, message) in
            // log shouldn't pass the default max log level, but is forced
            expect.fulfill()
        }
        logger.print(level: .verbose, force: true, showLocation: false, message: { "bla" })
        
        waitForExpectations(timeout: 0.1, handler: nil)
    }
}
