//**********************************************************************************************************************
//
//  String+Numeric.swift
//	Helper function for numeric parsing
//  Copyright ©2019-2021 Peter Baumgartner. All rights reserved.
//
//**********************************************************************************************************************


import Foundation


//----------------------------------------------------------------------------------------------------------------------


// MARK: -

public extension String
{
	
	/// Strips all non numeric charactef from a string. This includes leading and trailing whitespaces, as well
	/// as any letters that make up units. En example would be "100%" -> "100". The resulting string can be easily
	/// converted to an Int or Double.

	func strippingNonNumericCharacters() -> String
	{
		let numericCharacters = Set("0123456789.,+-")
		return self.filter { numericCharacters.contains($0) }
	}
	
	var intValue : Int?
	{
		let str = self.strippingNonNumericCharacters()
		let formatter = NumberFormatter.forInteger()
		return formatter.number(from:str)?.intValue ?? Int(str)
	}
	
	var floatValue : Float?
	{
		let str = self.strippingNonNumericCharacters()
		let formatter = NumberFormatter.forFloatingPoint(numberOfDigits:6)
		return formatter.number(from:str)?.floatValue ?? Float(str)
	}

	var doubleValue : Double?
	{
		let str = self.strippingNonNumericCharacters()
		let formatter = NumberFormatter.forFloatingPoint(numberOfDigits:6)
		return formatter.number(from:str)?.doubleValue ?? Double(str)
	}
}


//----------------------------------------------------------------------------------------------------------------------
