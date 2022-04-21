//**********************************************************************************************************************
//
//  FloatingPoint+isEqual.swift
//	Equality checks for floating point numbers
//  Copyright ©2022 Peter Baumgartner. All rights reserved.
//
//**********************************************************************************************************************


import Foundation

#if os(iOS)
import CoreGraphics // for CGFloat
#endif


//----------------------------------------------------------------------------------------------------------------------


extension Double
{
	/// Returns true if the two values are alomost equal, i.e. their difference is smaller than epsilon
	
	public static func isEqual(_ lhs:Self, _ rhs:Self, precision:Self = 0.001) -> Bool
	{
		guard !lhs.isNaN else { return false }
		guard !rhs.isNaN else { return false }
		
		guard !lhs.isInfinite else { return false }
		guard !rhs.isInfinite else { return false }
		
		return abs(lhs-rhs) < precision
	}

	/// Returns an integer hash value that uses the same epsilon at the isAlmostEqual function above
	
	public func roundedHashValue(precision:Self = 0.001) -> Int
	{
		guard !self.isNaN else { return 0 }
		guard !self.isInfinite else { return 0 }
		return Int(validating:self/precision, fallbackValue:0)
	}
}


//----------------------------------------------------------------------------------------------------------------------


extension Float
{
	/// Returns true if the two values are alomost equal, i.e. their difference is smaller than epsilon
	
	public static func isEqual(_ lhs:Self, _ rhs:Self, precision:Self = 0.001) -> Bool
	{
		guard !lhs.isNaN else { return false }
		guard !rhs.isNaN else { return false }
		
		guard !lhs.isInfinite else { return false }
		guard !rhs.isInfinite else { return false }
		
		return abs(lhs-rhs) < precision
	}

	/// Returns an integer hash value that uses the same epsilon at the isAlmostEqual function above
	
	public func roundedHashValue(precision:Self = 0.001) -> Int
	{
		guard !self.isNaN else { return 0 }
		guard !self.isInfinite else { return 0 }
		return Int(validating:self/precision, fallbackValue:0)
	}
}


//----------------------------------------------------------------------------------------------------------------------


extension CGFloat
{
	/// Returns true if the two values are alomost equal, i.e. their difference is smaller than epsilon
	
	public static func isEqual(_ lhs:Self, _ rhs:Self, precision:Self = 0.001) -> Bool
	{
		guard !lhs.isNaN else { return false }
		guard !rhs.isNaN else { return false }
		
		guard !lhs.isInfinite else { return false }
		guard !rhs.isInfinite else { return false }
		
		return abs(lhs-rhs) < precision
	}

	/// Returns an integer hash value that uses the same epsilon at the isAlmostEqual function above
	
	public func roundedHashValue(precision:Self = 0.001) -> Int
	{
		guard !self.isNaN else { return 0 }
		guard !self.isInfinite else { return 0 }
		return Int(validating:self/precision, fallbackValue:0)
	}
}
	
	
//----------------------------------------------------------------------------------------------------------------------
