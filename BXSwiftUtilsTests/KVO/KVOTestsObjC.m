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

@end


@implementation KVOTestsObjC


- (void)testExample {
    NSMutableArray *results = NSMutableArray.new;

    self.observationTarget = SomeClass.new;

    KVO *observer = [KVO observe:self onKeyPath:@"observationTarget.intProp" options:NSKeyValueObservingOptionInitial|NSKeyValueObservingOptionNew usingBlock:^(id _Nullable oldValue, id _Nullable newValue)
    {
        [results addObject:newValue];
    }];
    #pragma unused (observer)

    self.observationTarget.intProp = 100;

    NSArray *expected = @[@(42), @(100)];
    XCTAssertEqualObjects(results, expected);
}

@end
