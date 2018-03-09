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

    /*
     Asserts that two log levels are comparable.
     */
    func testLevelComparable()
    {
        XCTAssertGreaterThan(BXLogger.Level.verbose, BXLogger.Level.warning)
    }

    /*
     Asserts that a single message gets logged to a destination added via `addDestination`.
     */
    func testAddDestination()
    {
        var count = 0
        
        var logger = BXLogger()
        
        logger.addDestination
        { (level, message) in
           count += 1
        }
        
        logger.print(level: .error, force: false, showLocation: false, message: { "bla" })
        
        XCTAssertEqual(count, 1, "printed once")
    }
    
    /*
     Asserts that the default max log level swallows verbose and debug messages but not warnings and errors.
     This is useful to make sure that the default max log level is not simply changed at some point in the future and
     thus unexpectedly effects the consumers of the BXLogger class.
     */
    func testDefaultLogLevel()
    {
        var count = 0
        
        var logger = BXLogger()
        
        logger.addDestination
        { (level, message) in
            count += 1
            
            XCTAssert(level == .warning || level == .error, "level is warning or error")
        }
        
        logger.verbose { "verbose" }
        logger.debug(showLocation: true) { "debug" }
        logger.warning { "warning" }
        logger.error { "error" }
        
        XCTAssertEqual(count, 2, "printed two times")
    }
    
    /*
     Asserts that settings a custom log level changes the default behavior regarind swallowing/forwarding events.
     */
    func testCustomLogLevel()
    {
        var count = 0
        
        var logger = BXLogger()
        
        logger.maxLevel = .debug
        
        logger.addDestination
        { (level, message) in
            count += 1
            
            XCTAssert(level == .debug || level == .warning || level == .error, "level is debug, warning, or error")
        }
        
        logger.verbose { "verbose" }
        logger.debug { "debug" }
        logger.warning { "warning" }
        logger.error(showLocation: true) { "error" }
        
        XCTAssertEqual(count, 3, "printed three times")
    }
    
    /*
     Asserts that messages can be forced through the log level filter if desired.
     */
    func testForceLog()
    {
        var count = 0
        
        var logger = BXLogger()
        
        logger.addDestination
        { (level, message) in
            // log shouldn't pass the default max log level, but is forced
            count = 1
        }
        
        logger.print(level: .verbose, force: true, showLocation: false, message: { "bla" })
        
        XCTAssertEqual(count, 1, "printed once")
    }
}
