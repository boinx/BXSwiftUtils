//
//  Comparable+Clip.swift
//  BXSwiftUtils
//
//  Created by Benjamin Federer on 21.11.18.
//  Copyright © 2018 Boinx Software Ltd. & Imagine GbR. All rights reserved.
//

import Foundation

extension Comparable
{
	/// Returns `self` clipped to the closed interval `[minValue, maxValue]`.
	///
	/// - Parameters:
	///   - minValue: The minimum allowed value. Will clip `self` if smaller.
	///   - maxValue: The maximum allowed value. Will clip `self` if greater.
	/// - Returns: `self` if `self` is within the interval `[minValue, maxValue]`, `minValue` or `maxValue` otherwise.
	public func clipped<T>(minValue: T, maxValue: T) -> T where T : Comparable
	{
		return min(maxValue, max(minValue, self as! T))
	}
	
	/// Clips to the closed interval `[minValue, maxValue]`.
	///
	/// - Parameters:
	///   - minValue: The minimum allowed value. Will clip `self` if smaller.
	///   - maxValue: The maximum allowed value. Will clip `self` if greater.
	public mutating func clip<T>(minValue: T, maxValue: T) where T : Comparable
	{
		self = min(maxValue, max(minValue, self as! T)) as! Self
	}
}
