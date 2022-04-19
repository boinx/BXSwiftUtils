//**********************************************************************************************************************
//
//  FloatingPoint+Safety.swift
//	Safety checks for floating point numbers
//  Copyright ©2022 Peter Baumgartner. All rights reserved.
//
//**********************************************************************************************************************


import Foundation
import CoreGraphics // for CGFloat


//----------------------------------------------------------------------------------------------------------------------


public extension FloatingPoint
{
	/// If self is NaN or Inf then this function returns the fallbackValue instead. This is useful to avoid
	/// exceptions or crashes down the line, e.g. when creating an Int or calling CoreGraphics.
	
	func validated(fallbackValue:Self) -> Self
	{
		self.isFinite ? self : fallbackValue
	}
}


//----------------------------------------------------------------------------------------------------------------------


public extension Int
{
	/// Creates an Int from a Double value, using the fallbackValue instead if values was NaN or Inf
	
	init(validating value:Double, fallbackValue:Double = 0.0)
	{
		self.init(value.validated(fallbackValue:fallbackValue))
	}
	
	/// Creates an Int from a Float value, using the fallbackValue instead if values was NaN or Inf
	
	init(validating value:Float, fallbackValue:Float = 0.0)
	{
		self.init(value.validated(fallbackValue:fallbackValue))
	}
	
	/// Creates an Int from a CGFloat value, using the fallbackValue instead if values was NaN or Inf
	
	init(validating value:CGFloat, fallbackValue:CGFloat = 0.0)
	{
		self.init(value.validated(fallbackValue:fallbackValue))
	}
}


//----------------------------------------------------------------------------------------------------------------------


extension Double
{
	/// Converts self to an Int value in a safe manner (without causing crashes)
	
	func safeInt(fallbackValue:Double = 0.0) -> Int
	{
		Int(validating:self, fallbackValue:fallbackValue)
	}
}


extension Float
{
	/// Converts self to an Int value in a safe manner (without causing crashes)
	
	func safeInt(fallbackValue:Float = 0.0) -> Int
	{
		Int(validating:self, fallbackValue:fallbackValue)
	}
}


extension CGFloat
{
	/// Converts self to an Int value in a safe manner (without causing crashes)
	
	func safeInt(fallbackValue:CGFloat = 0.0) -> Int
	{
		Int(validating:self, fallbackValue:fallbackValue)
	}
}


//----------------------------------------------------------------------------------------------------------------------
