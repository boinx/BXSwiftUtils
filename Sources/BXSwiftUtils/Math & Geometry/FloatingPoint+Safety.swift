//**********************************************************************************************************************
//
//  FloatingPoint+Safety.swift
//	Safety checks for floating point numbers
//  Copyright ©2022-2026 Peter Baumgartner. All rights reserved.
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
		guard !self.isNaN else { return fallbackValue }
		guard self.isFinite else { return fallbackValue }
		return self
	}
}


//----------------------------------------------------------------------------------------------------------------------


public extension Int
{
	/// Creates an Int from a Double value, using the fallbackValue instead if values was NaN or Inf
	
	init(validating value:Double, fallbackValue:Double = 0.0)
	{
		self.init(value.safeInt(fallbackValue:fallbackValue))
	}
	
	/// Creates an Int from a Float value, using the fallbackValue instead if values was NaN or Inf
	
	init(validating value:Float, fallbackValue:Float = 0.0)
	{
		self.init(value.safeInt(fallbackValue:fallbackValue))
	}
	
	/// Creates an Int from a CGFloat value, using the fallbackValue instead if values was NaN or Inf
	
	init(validating value:CGFloat, fallbackValue:CGFloat = 0.0)
	{
		self.init(value.safeInt(fallbackValue:fallbackValue))
	}
}


//----------------------------------------------------------------------------------------------------------------------


extension Double
{
	/// Converts self to an Int value in a safe manner (without causing crashes)
	
	func safeInt(fallbackValue:Double = 0.0) -> Int
	{
		let value = self.validated(fallbackValue:fallbackValue)
		if value < Double(Int.min) { return Int.min }
		if value > Double(Int.max) { return Int.max }
		return Int(value)
	}
}


extension Float
{
	/// Converts self to an Int value in a safe manner (without causing crashes)
	
	func safeInt(fallbackValue:Float = 0.0) -> Int
	{
		let value = self.validated(fallbackValue:fallbackValue)
		if value < Float(Int.min) { return Int.min }
		if value > Float(Int.max) { return Int.max }
		return Int(value)
	}
}


extension CGFloat
{
	/// Converts self to an Int value in a safe manner (without causing crashes)
	
	func safeInt(fallbackValue:CGFloat = 0.0) -> Int
	{
		let value = self.validated(fallbackValue:fallbackValue)
		if value < CGFloat(Int.min) { return Int.min }
		if value > CGFloat(Int.max) { return Int.max }
		return Int(value)
	}
}


//----------------------------------------------------------------------------------------------------------------------
