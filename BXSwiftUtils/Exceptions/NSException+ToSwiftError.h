//
//  NSException+ToSwiftError.h
//  BXSwiftUtils
//
//  Created by Stefan Fochler on 27.03.18.
//  Copyright © 2018 Boinx Software Ltd. & Imagine GbR. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSException (ToSwiftError)

+ (BOOL)toSwiftError:(__attribute__((noescape)) void(^)(void))block error:(__autoreleasing NSError **)error;

@end

NS_ASSUME_NONNULL_END
