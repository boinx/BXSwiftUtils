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
	/**
	 Clips a value into the closed range `[min, max]` without modifying the original value.
	
	 The two bounds are an unordered pair - passing them the wrong way round gives the same answer as passing them
	 the right way round.
	
	 - Parameter minValue: One end of the allowed range.
	 - Parameter maxValue: The other end of the allowed range.
	 - Returns: A new value that lies within the closed range spanned by the two bounds.
	 */
	public func clipped(min minValue: Self, max maxValue: Self) -> Self
	{
		var copy = self
		copy.clip(min: minValue, max: maxValue)
		return copy
	}
	
	/**
	 Clips a value into the closed range `[min, max]` by modifying the original value.
	
	 The two bounds are an unordered pair - passing them the wrong way round gives the same answer as passing them
	 the right way round.
	
	 - Parameter minValue: One end of the allowed range.
	 - Parameter maxValue: The other end of the allowed range.
	 */
	public mutating func clip(min minValue: Self, max maxValue: Self)
	{
		// Order the bounds before using them. Inverted bounds used to return a value OUTSIDE the range the caller
		// asked for - and which of the two you got depended on the input, so the same pair of bounds could produce
		// either one. An NSException guarded against it until July 2023, when it was removed because crashing on a
		// customer machine is not an acceptable answer either. Swapping is: it is the only reading that treats the
		// bounds as the pair they are, and it cannot fail.
		//
		// Written as ONE comparison rather than with Swift.min and Swift.max, which would quietly change what a NaN
		// bound does: both of those answer 0 for the pair (0, NaN), turning a bound nothing can order into a hard
		// clamp to the other one. The comparison below is false for a NaN, so such bounds are left exactly as given
		// and the value passes through untouched, as it always has.
		
		let (lower,upper) = maxValue < minValue ? (maxValue,minValue) : (minValue,maxValue)
		
		if self < lower
		{
			self = lower
		}
		else if self > upper
		{
			self = upper
		}
	}
	
	/**
	 Clips a value into the given closed range without modifying the original value.
	
	 - Parameter range: Closed range that conveys the minimum and maximum allowed value.
	 - Returns: New value that lies within the closed range `range`.
	 */
	public func clipped(to range: ClosedRange<Self>) -> Self
	{
		var copy = self
		copy.clip(min: range.lowerBound, max: range.upperBound)
		return copy
	}
	
	/**
	 Clips a value into the given closed range by modifying the original value.
	
	 - Parameter range: Closed range that conveys the minimum and maximum allowed value.
	 */
	public mutating func clip(to range: ClosedRange<Self>)
	{
		self.clip(min: range.lowerBound, max: range.upperBound)
	}
}
