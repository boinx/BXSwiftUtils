//
//  Enum+Comparable.swift
//  BXSwiftUtils
//
//  Created by Stefan Fochler on 24.09.18.
//  Copyright © 2018 Boinx Software Ltd. & Imagine GbR. All rights reserved.
//


public protocol ComparableEnum: Comparable {}

/**
 Protocol that can be adapted by raw-representable enums to adapt comparability by comparing the raw values.
 
 Version that uses the raw value of the numeric values.
*/
public extension ComparableEnum where Self: RawRepresentable, Self.RawValue == Int
{
    public static func <(lhs: Self, rhs: Self) -> Bool
    {
        return lhs.rawValue < rhs.rawValue
    }
}


// CaseIterable is a Xcode 10.0+ feature, however, this can't be checked directly. So since Xcode 10 shipped with Swift
// 4.2, we check if that is being used to compile the project.
#if swift(>=4.2)

/**
 Non-integer enums must not be ordered by their raw values (i.e. by performing string comparisons), but instead by the
 order of their cases, which is only possible if the enum adapts the `CaseIterable` protocol.
 */
public extension ComparableEnum where Self: RawRepresentable, Self.RawValue == String, Self: CaseIterable
{
    public static func <(lhs: Self, rhs: Self) -> Bool
    {
        let allCases = self.allCases
        return allCases.firstIndex(of: lhs)! < allCases.firstIndex(of: rhs)!
    }
}

#endif
