//**********************************************************************************************************************
//
//  String+Numeric.swift
//	Helper function for numeric parsing
//  Copyright ©2019 Peter Baumgartner. All rights reserved.
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
		let numbericCharacters = Set("0123456789.,")
		return self.filter { numbericCharacters.contains($0) }
	}
	
	var intValue : Int?
	{
		return Int(self.strippingNonNumericCharacters())
	}
	
	var floatValue : Float?
	{
		return Float(self.strippingNonNumericCharacters())
	}

	var doubleValue : Double?
	{
		return Double(self.strippingNonNumericCharacters())
	}
}


//----------------------------------------------------------------------------------------------------------------------
