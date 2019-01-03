//**********************************************************************************************************************
//
//  Double+Localized.swift
//	Adds localized methods to Double, Float and CGFloat
//  Copyright ©2019 Peter Baumgartner. All rights reserved.
//
//**********************************************************************************************************************


import Foundation
import CoreGraphics


//----------------------------------------------------------------------------------------------------------------------


protocol NumberFormatting { }

extension NumberFormatting
{
	/// Returns a localized string for the Double value
	///
	/// Parameter format: The format string specifying how the number is displayed
	/// Parameter numberOfDigits: The number of digits after the decimal point
	/// Returns: The localized string for the number
	
	public func numberFormatter(with format: String, numberOfDigits: Int) -> NumberFormatter
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


extension Double : NumberFormatting
{
	/// Returns a localized string for the Double value
	///
	/// Parameter format: The format string specifying how the number is displayed
	/// Parameter numberOfDigits: The number of digits after the decimal point
	/// Returns: The localized string for the number
	
    public func localized(with format: String = "#.#", numberOfDigits: Int = 1) -> String
	{
		let formatter = self.numberFormatter(with:format, numberOfDigits:numberOfDigits)
		return formatter.string(from:NSNumber(value:self)) ?? "×"
    }
}


//----------------------------------------------------------------------------------------------------------------------


extension Float : NumberFormatting
{
	/// Returns a localized string for the Double value
	///
	/// Parameter format: The format string specifying how the number is displayed
	/// Parameter numberOfDigits: The number of digits after the decimal point
	/// Returns: The localized string for the number
	
    public func localized(with format: String = "#.#", numberOfDigits: Int = 1) -> String
	{
		let formatter = self.numberFormatter(with:format, numberOfDigits:numberOfDigits)
		return formatter.string(from:NSNumber(value:self)) ?? "×"
    }
}


//----------------------------------------------------------------------------------------------------------------------


extension CGFloat : NumberFormatting
{
	/// Returns a localized string for the Double value
	///
	/// Parameter format: The format string specifying how the number is displayed
	/// Parameter numberOfDigits: The number of digits after the decimal point
	/// Returns: The localized string for the number
	
    public func localized(with format: String = "#.#", numberOfDigits: Int = 1) -> String
	{
		return Double(self).localized(with:format, numberOfDigits:numberOfDigits)
    }
}


//----------------------------------------------------------------------------------------------------------------------
