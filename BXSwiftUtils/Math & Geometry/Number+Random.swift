//**********************************************************************************************************************
//
//  Number+Random.swift
//	Provides random number generation for pre Swift 4.2 code
//  Copyright ©2018 Peter Baumgartner. All rights reserved.
//
//**********************************************************************************************************************


import Foundation
import simd


//----------------------------------------------------------------------------------------------------------------------


#if !swift(>=4.2)

extension FloatingPoint
{

	/// Returns a random value in the range 0.0 ... 1.0
	
    static var random: Self
    {
        return self.init(arc4random()) / self.init(UInt32.max)
    }


	/// Returns a random value in the specified range
	
    public static func random(in range: Range<Self>) -> Self
    {
    	let minValue = range.lowerBound
    	let maxValue = range.upperBound
    	let delta = maxValue - minValue
    	return minValue + delta * self.random
     }
}

#endif


//----------------------------------------------------------------------------------------------------------------------


// MARK: -

#if !swift(>=4.2)

extension FixedWidthInteger
{

	/// Returns a random value in the range 0 ... Self.max
	
    static var random: Self
    {
        let max = self.max > UInt32.max ? UInt32.max : UInt32(self.max)
        var value = self.init(arc4random_uniform(max))
		
        if self.bitWidth > 32
        {
            value &<<= 32
            value += self.init(arc4random())
        }
		
        return value
    }


	/// Returns a random value in the specified range
	
    public static func random(in range: Range<Self>) -> Self
    {
    	let minValue = range.lowerBound
    	let maxValue = range.upperBound
		let max32 = self.init(UInt32.max)

    	let n = maxValue - minValue
		var max1:Self = n
		var max2:Self = 0
		
		if n > max32
		{
			max1 = max32
			max2 = n - max32
		}
		
		// This isn't correct yet for 64 bits. Too lazy to work on this today ;-)
		
		var value:Self = 0
		
		if n > max32
		{
			let value1 = self.init(arc4random_uniform(UInt32(max1)))
			let value2 = self.init(arc4random_uniform(UInt32(max2)))
			value = (value2 &<< 32) + value1
		}
		else
		{
			value = self.init(arc4random_uniform(UInt32(max1)))
		}

        return value + minValue
    }
}

#endif


//----------------------------------------------------------------------------------------------------------------------


// MARK: -

extension SIMD2 where Scalar == Float
{
    public static func random(in range: Range<Float>) -> SIMD2<Float>
    {
		var value = SIMD2<Float>(0.0,0.0)
		value.x = Float.random(in:range)
		value.y = Float.random(in:range)
    	return value
     }
}


extension SIMD3 where Scalar == Float
{
    public static func random(in range: Range<Float>) -> SIMD3<Float>
    {
		var value = SIMD3<Float>(0.0,0.0,0.0)
		value.x = Float.random(in:range)
		value.y = Float.random(in:range)
		value.z = Float.random(in:range)
    	return value
     }
}


extension SIMD4 where Scalar == Float
{
    public static func random(in range: Range<Float>) -> SIMD4<Float>
    {
		var value = SIMD4<Float>(0.0,0.0,0.0,0.0)
		value.x = Float.random(in:range)
		value.y = Float.random(in:range)
		value.z = Float.random(in:range)
		value.w = Float.random(in:range)
    	return value
     }
}


//----------------------------------------------------------------------------------------------------------------------


// MARK: -

extension SIMD2 where Scalar == Double
{
    public static func random(in range: Range<Double>) -> SIMD2<Double>
    {
		var value = SIMD2<Double>(0.0,0.0)
		value.x = Double.random(in:range)
		value.y = Double.random(in:range)
    	return value
     }
}


extension SIMD3 where Scalar == Double
{
    public static func random(in range: Range<Double>) -> SIMD3<Double>
    {
		var value = SIMD3<Double>(0.0,0.0,0.0)
		value.x = Double.random(in:range)
		value.y = Double.random(in:range)
		value.z = Double.random(in:range)
    	return value
     }
}


extension SIMD4 where Scalar == Double
{
    public static func random(in range: Range<Double>) ->  SIMD4<Double>
    {
		var value = SIMD4<Double>(0.0,0.0,0.0,0.0)
		value.x = Double.random(in:range)
		value.y = Double.random(in:range)
		value.z = Double.random(in:range)
		value.w = Double.random(in:range)
    	return value
     }
}


//----------------------------------------------------------------------------------------------------------------------
