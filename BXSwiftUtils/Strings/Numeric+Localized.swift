//**********************************************************************************************************************
//
//  Numeric+Localized.swift
//	Adds localized methods for numeric values (Int, Float, Double)
//  Copyright ©2019 Peter Baumgartner. All rights reserved.
//
//**********************************************************************************************************************


import Foundation
import CoreGraphics


//----------------------------------------------------------------------------------------------------------------------


extension NumberFormatter
{
	/// Returns a NumberFormatter for Int numbers
	/// - Parameter numberOfDigits: The number of leading digits (filled with 0)
	/// - Returns: The localized string for the number
	
	public static func forInteger(numberOfDigits: Int = 0) -> NumberFormatter
	{
		let formatter = NumberFormatter()
		formatter.locale = Locale.current
		formatter.minimumIntegerDigits = numberOfDigits
		return formatter
    }

	/// Returns a NumberFormatter for Double values
	/// - Parameter format: The format string specifying how the number is displayed
	/// - Parameter numberOfDigits: The number of digits after the decimal point
	/// - Returns: The NumberFormatter
	
	public static func forFloatingPoint(with format: String, numberOfDigits: Int) -> NumberFormatter
	{
		let formatter = NumberFormatter()
		
		formatter.locale = Locale.current
		formatter.maximumFractionDigits = numberOfDigits
		formatter.positiveFormat = format
		formatter.negativeFormat = "-\(format)"

		return formatter
    }
}


//----------------------------------------------------------------------------------------------------------------------


extension Int
{
	/// Returns a localized string for an Int value
	/// - Parameter numberOfDigits: The number of digits after the decimal point
	/// - Returns: The localized string for the value
	
    public func localized(numberOfDigits: Int = 0) -> String
	{
		let formatter = NumberFormatter.forInteger(numberOfDigits:numberOfDigits)
		return formatter.string(from:NSNumber(value:self)) ?? "\(self)"
    }
}


//----------------------------------------------------------------------------------------------------------------------


extension Double
{
	/// Returns a localized string for the Double value
	/// - Parameter format: The format string specifying how the number is displayed
	/// - Parameter numberOfDigits: The number of digits after the decimal point
	/// - Returns: The localized string for the number
	
    public func localized(with format: String = "#.#", numberOfDigits: Int = 1) -> String
	{
		let formatter = NumberFormatter.forFloatingPoint(with:format, numberOfDigits:numberOfDigits)
		return formatter.string(from:NSNumber(value:self)) ?? "\(self)"
    }
}


//----------------------------------------------------------------------------------------------------------------------


extension Float
{
	/// Returns a localized string for the Double value
	/// - Parameter format: The format string specifying how the number is displayed
	/// - Parameter numberOfDigits: The number of digits after the decimal point
	/// - Returns: The localized string for the number
	
    public func localized(with format: String = "#.#", numberOfDigits: Int = 1) -> String
	{
		let formatter = NumberFormatter.forFloatingPoint(with:format, numberOfDigits:numberOfDigits)
		return formatter.string(from:NSNumber(value:self)) ?? "\(self)"
    }
}


//----------------------------------------------------------------------------------------------------------------------


extension CGFloat
{
	/// Returns a localized string for the Double value
	/// - Parameter format: The format string specifying how the number is displayed
	/// - Parameter numberOfDigits: The number of digits after the decimal point
	/// - Returns: The localized string for the number
	
    public func localized(with format: String = "#.#", numberOfDigits: Int = 1) -> String
	{
		return Double(self).localized(with:format, numberOfDigits:numberOfDigits)
    }
}


//----------------------------------------------------------------------------------------------------------------------


extension String
{
	/// Converts a (possibly localized) string to an Int value (using the supplied NumberFormatter)
	/// - Parameter formatter: An optional NumberFormatter that gets the first try to extract the value
	/// - Parameter defaultValue: If value extraction fails then this default value will be returned
	/// - Returns: The extracted number value

    public func intValue(with formatter: NumberFormatter?, defaultValue: Int = 0) -> Int
	{
		return formatter?.number(from:self)?.intValue ?? Int(self) ?? defaultValue
    }

 	/// Converts a (possibly localized) string to a Double value (using the supplied NumberFormatter)
	/// - Parameter formatter: An optional NumberFormatter that gets the first try to extract the value
	/// - Parameter defaultValue: If value extraction fails then this default value will be returned
	/// - Returns: The extracted number value

	public func doubleValue(with formatter: NumberFormatter?, defaultValue: Double = 0.0) -> Double
	{
		return formatter?.number(from:self)?.doubleValue ?? Double(self) ?? defaultValue
    }
	
 	/// Converts a (possibly localized) string to a Float value (using the supplied NumberFormatter)
	/// - Parameter formatter: An optional NumberFormatter that gets the first try to extract the value
	/// - Parameter defaultValue: If value extraction fails then this default value will be returned
	/// - Returns: The extracted number value

    public func floatValue(with formatter: NumberFormatter?, defaultValue: Float = 0.0) -> Float
	{
		return formatter?.number(from:self)?.floatValue ?? Float(self) ?? defaultValue
    }
}


//----------------------------------------------------------------------------------------------------------------------
