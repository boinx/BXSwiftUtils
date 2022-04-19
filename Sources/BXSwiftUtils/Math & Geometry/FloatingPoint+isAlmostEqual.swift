//**********************************************************************************************************************
//
//  FloatingPoint+isAlmostEqual.swift
//	Equality checks for floating point numbers
//  Copyright ©2022 Peter Baumgartner. All rights reserved.
//
//**********************************************************************************************************************


extension FloatingPoint
{
	/// Returns true if the two values are alomost equal, i.e. their difference is smaller than epsilon
	
//	public static func isAlmostEqual<T:FloatingPoint>(_ lhs:T, _ rhs:T, epsilon:T) -> Bool
//	{
//		guard !lhs.isNaN else { return false }
//		guard !rhs.isNaN else { return false }
//
//		guard !lhs.isInfinite else { return false }
//		guard !rhs.isInfinite else { return false }
//
//		return abs(lhs-rhs) < epsilon
//	}
	
	/// Returns an integer hash value that uses the same epsilon at the isAlmostEqual function above
	
//	public static func hashValue<T:FloatingPoint>(_ value:T, epsilon:T) -> Int
//	{
//		guard !value.isNaN else { return 0 }
//		guard !value.isInfinite else { return 0 }
//		let v = Double(value / epsilon)
//		return Int(v)
//	}
}


//----------------------------------------------------------------------------------------------------------------------


extension Double
{
	/// Returns true if the two values are alomost equal, i.e. their difference is smaller than epsilon
	
	public static func isAlmostEqual(_ lhs:Self, _ rhs:Self, epsilon:Self = 0.001) -> Bool
	{
		guard !lhs.isNaN else { return false }
		guard !rhs.isNaN else { return false }
		
		guard !lhs.isInfinite else { return false }
		guard !rhs.isInfinite else { return false }
		
		return abs(lhs-rhs) < epsilon
	}

	/// Returns an integer hash value that uses the same epsilon at the isAlmostEqual function above
	
	public func roundedHashValue(epsilon:Self = 0.001) -> Int
	{
		guard !self.isNaN else { return 0 }
		guard !self.isInfinite else { return 0 }
		return Int(self / epsilon)
	}
}


//----------------------------------------------------------------------------------------------------------------------


extension Float
{
	/// Returns true if the two values are alomost equal, i.e. their difference is smaller than epsilon
	
	public static func isAlmostEqual(_ lhs:Self, _ rhs:Self, epsilon:Self = 0.001) -> Bool
	{
		guard !lhs.isNaN else { return false }
		guard !rhs.isNaN else { return false }
		
		guard !lhs.isInfinite else { return false }
		guard !rhs.isInfinite else { return false }
		
		return abs(lhs-rhs) < epsilon
	}

	/// Returns an integer hash value that uses the same epsilon at the isAlmostEqual function above
	
	public func roundedHashValue(epsilon:Self = 0.001) -> Int
	{
		guard !self.isNaN else { return 0 }
		guard !self.isInfinite else { return 0 }
		return Int(self / epsilon)
	}
}


//----------------------------------------------------------------------------------------------------------------------


extension CGFloat
{
	/// Returns true if the two values are alomost equal, i.e. their difference is smaller than epsilon
	
	public static func isAlmostEqual(_ lhs:Self, _ rhs:Self, epsilon:Self = 0.001) -> Bool
	{
		guard !lhs.isNaN else { return false }
		guard !rhs.isNaN else { return false }
		
		guard !lhs.isInfinite else { return false }
		guard !rhs.isInfinite else { return false }
		
		return abs(lhs-rhs) < epsilon
	}

	/// Returns an integer hash value that uses the same epsilon at the isAlmostEqual function above
	
	public func roundedHashValue(epsilon:Self = 0.001) -> Int
	{
		guard !self.isNaN else { return 0 }
		guard !self.isInfinite else { return 0 }
		return Int(self / epsilon)
	}
}
	
	
//----------------------------------------------------------------------------------------------------------------------
