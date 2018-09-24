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
*/
public extension ComparableEnum where Self: RawRepresentable, Self.RawValue: Comparable
{
    public static func <(lhs: Self, rhs: Self) -> Bool
    {
        return lhs.rawValue < rhs.rawValue
    }
}
