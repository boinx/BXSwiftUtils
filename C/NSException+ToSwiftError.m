//
//  NSException+ToSwiftError.m
//  BXSwiftUtils
//
//  Created by Stefan Fochler on 27.03.18.
//  Copyright © 2018 Boinx Software Ltd. & Imagine GbR. All rights reserved.
//

#import "NSException+ToSwiftError.h"

@implementation NSException (ToSwiftError)

+ (BOOL)toSwiftError:(__attribute__((noescape)) void(^)(void))block error:(__autoreleasing NSError **)error
{
    @try
    {
        block();
        return YES;
    }
    @catch (NSException *exception)
    {
		NSDictionary* userInfo =
		@{
			NSLocalizedDescriptionKey: exception.description,
			NSLocalizedFailureReasonErrorKey: exception.reason,
			NSDebugDescriptionErrorKey: exception.debugDescription
		};
		
        *error = [[NSError alloc] initWithDomain:exception.name code:0 userInfo:userInfo];
        return NO;
    }
}

@end
