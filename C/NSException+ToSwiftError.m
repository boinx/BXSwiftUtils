//
//  NSException+ToSwiftError.m
//  BXSwiftUtils
//
//  Created by Stefan Fochler on 27.03.18.
//  Copyright © 2018 Boinx Software Ltd. & Imagine GbR. All rights reserved.
//

#import "NSException+ToSwiftError.h"

@implementation NSException (ToSwiftError)


/// This function catches NSException that are thrown inside the (non-throwing) worker block.
///
/// NSExceptions are converted to Swift Error so that they can be handled by the calling Swift code in the regular fashion.

+ (BOOL) toSwiftError:(__attribute__((noescape)) void(^)(void))block error:(__autoreleasing NSError**)outError
{
	// Execute the worker block

    @try
    {
        block();
        return YES;
    }
    
    // If an Objective-C NSException was thrown (most likely by Foundation or AppKit), then
    // catch it, convert it to a Swift Error and pass this Error to the outside caller.
    // The calling Swift code and then handle it in the regular fahsion without crashing.
    
    @catch (NSException *exception)
    {
		NSDictionary* userInfo =
		@{
			NSLocalizedDescriptionKey: exception.description,
			NSLocalizedFailureReasonErrorKey: exception.reason,
			NSDebugDescriptionErrorKey: exception.debugDescription
		};
		
        *outError = [[NSError alloc] initWithDomain:exception.name code:0 userInfo:userInfo];
        return NO;
    }
}

/// This function catches NSException that are thrown inside the throwing worker block.
///
/// NSExceptions are converted to Swift Error so that they can be handled by the calling Swift code in the regular fashion.

+ (BOOL) toSwiftErrorThrowing:(__attribute__((noescape)) void(^)(__autoreleasing NSError**))block error:(__autoreleasing NSError**)outError
{
    @try
    {
		// Execute the worker block
		
		NSError* localError = nil;
        block(&localError);
        
        // If a Swift Error was thrown inside this block, then pass it on to the outside caller
        
        if (localError != nil)
        {
			*outError = localError;
			return NO;
        }
        
        return YES;
    }
    
    // If an Objective-C NSException was thrown (most likely by Foundation or AppKit), then
    // catch it, convert it to a Swift Error and pass this Error to the outside caller.
    // The calling Swift code and then handle it in the regular fahsion without crashing.
    
    @catch (NSException *exception)
    {
		NSDictionary* userInfo =
		@{
			NSLocalizedDescriptionKey: exception.description,
			NSLocalizedFailureReasonErrorKey: exception.reason,
			NSDebugDescriptionErrorKey: exception.debugDescription
		};
		
        *outError = [[NSError alloc] initWithDomain:exception.name code:0 userInfo:userInfo];
        return NO;
    }
}

@end
