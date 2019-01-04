//**********************************************************************************************************************
//
//  Int+Localized.swift
//	Adds localized methods to Int
//  Copyright ©2019 Peter Baumgartner. All rights reserved.
//
//**********************************************************************************************************************


import Foundation
import CoreGraphics


//----------------------------------------------------------------------------------------------------------------------


extension NumberFormatter
{
	/// Returns a NumberFormatter for Int numbers
	/// Parameter numberOfDigits: The number of digits after the decimal point
	/// Returns: The localized string for the number
	
	public static func forInteger(numberOfDigits: Int = 0) -> NumberFormatter
	{
		let formatter = NumberFormatter()
		formatter.locale = Locale.current
		formatter.minimumIntegerDigits = numberOfDigits
		return formatter
    }
}


//----------------------------------------------------------------------------------------------------------------------


extension Int
{
	/// Returns a localized string for an Int value
	/// Parameter numberOfDigits: The number of digits after the decimal point
	/// Returns: The localized string for the value
	
    public func localized(numberOfDigits: Int = 0) -> String
	{
		let formatter = NumberFormatter.forInteger(numberOfDigits:numberOfDigits)
		return formatter.string(from:NSNumber(value:self)) ?? "\(self)"
    }
}


//----------------------------------------------------------------------------------------------------------------------
