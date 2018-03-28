//
//  KVOTestsObjC.m
//  BXSwiftUtils
//
//  Created by Stefan Fochler on 28.03.18.
//  Copyright © 2018 Boinx Software Ltd. & Imagine GbR. All rights reserved.
//

@import XCTest;
@import BXSwiftUtils;


@interface SomeClass : NSObject

@property int intProp;

@end


@implementation SomeClass

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        self.intProp = 42;
    }
    return self;
}

@end


# pragma mark -


@interface KVOTestsObjC : XCTestCase

@property SomeClass *observationTarget;
@property NSMutableArray *observers;

@end


@implementation KVOTestsObjC

- (void)setUp {
    [super setUp];
    self.observers = NSMutableArray.new;
}

- (void)testExample {
    __block int count = 0;

    self.observationTarget = SomeClass.new;

    [self.observers addObject:
        [KVO observe:self onKeyPath:@"observationTarget.intProp" options:NSKeyValueObservingOptionInitial|NSKeyValueObservingOptionNew usingBlock:^(id _Nullable oldValue, id _Nullable newValue)
        {
            if (count == 0)
            {
                XCTAssertEqual([newValue integerValue], 42);
            }
            else
            {
                XCTAssertEqual([newValue integerValue], 100);
            }
            count++;
        }]
    ];
    
    self.observationTarget.intProp = 100;

    XCTAssertEqual(count, 2);
}

@end
