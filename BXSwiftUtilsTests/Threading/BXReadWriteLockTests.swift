//
//  BXReadWriteLockTests.swift
//  BXSwiftUtils
//
//  Created by Stefan Fochler on 12.03.18.
//  Copyright © 2018 Boinx Software Ltd. & Imagine GbR. All rights reserved.
//

import XCTest
import BXSwiftUtils

fileprivate class Resource
{
    var prop: Int = 0
}

class BXReadWriteLockTests: XCTestCase
{

    private var lock: BXReadWriteLock!
    
    // an unprotected class-type that can be used for concurrent access
    private var resource: Resource!
    
    override func setUp()
    {
        super.setUp()
        
        lock = BXReadWriteLock(label: "test")
        resource = Resource()
    }

    func testRead()
    {
        let count = lock.read
        {
            return 1
        }
        
        XCTAssertEqual(count, 1, "simple read")
    }

    func testWrite()
    {
        let count = lock.write
        {
            return 1
        }
        
        XCTAssertEqual(count, 1, "simple write")
    }
    
    /**
     Attempts to provoke a race-condition involving concurrent access on `resource.prop` and assert that all readers
     access the resource in a valid state.
     
     This is done in the following way:
     
     1. 100 concurrent readers are spawned that initially sleep for 0 to 100 ms
     2. A writer is spawned that sleeps for 50ms and then locks the resource for writing and brings it into an invalid
        state. By using this invalid state, we can assert that no reader can access the resource during this time
     3. The writer sleeps for 75ms and brings the resource back into a valid state
     4. We wait until all readers have finished reading
     
     Of cource, there is a probability that all readers finish before the writer even starts, in which case no race
     condition is provoked.
     However, this chance is around 7.88*10^(-31), so we're pretty safe I guess.
     */
    func testConcurrency()
    {
        let expect = expectation(description: "testConcurrency")
        expect.expectedFulfillmentCount = 100
        expect.assertForOverFulfill = true
        
        let queue = DispatchQueue(label: "testConcurrencyQueue", qos: .background, attributes: [.concurrent])
        
        for _ in 0..<100
        {
            queue.async
            {
                // sleep between 0 and 0.1 seconds to make the race conditions racier
                let sleep: Double = Double(arc4random_uniform(100))/1000
                Thread.sleep(forTimeInterval: sleep)
                
                let value = self.lock.read { self.resource.prop }
                
                XCTAssert(value == 0 || value == 1, "value is in a valid state")
                
                expect.fulfill()
            }
        }

        queue.async {
            Thread.sleep(forTimeInterval: 0.05)
            
            self.lock.write
            {
                // bring resource into "invalid" state
                self.resource.prop = 42
                
                // sleep for 50ms
                Thread.sleep(forTimeInterval: 0.075)
                
                // bring resource back to "valid" state
                self.resource.prop = 1
            }
        }
        
        waitForExpectations(timeout: 1, handler: nil)
    }
}
