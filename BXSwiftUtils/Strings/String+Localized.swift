//**********************************************************************************************************************
//
//  String+Localized.swift
//	Adds localized methods to String
//  Copyright ©2016 Peter Baumgartner. All rights reserved.
//
//**********************************************************************************************************************


import Foundation


//----------------------------------------------------------------------------------------------------------------------


public extension String
{

	/**
	
	Returns a localized string for the key contained in the receiver (self). If this key hasn't been localized
	in the strings files yet, then it will show up as the uppercased key enclosed in double angle brackets << KEY >>
	
	- Parameter tableName: The name of the .strings file. Provide nil to use the default Localized.strings.
	- Parameter comment: Provide help to the translator by explaining the context where this string is being used.
	- Parameter bundle: Provide nil to use the default Bundle.main().
	- Parameter value: The default string in the development language.
	- Returns: The localized string (or << KEY >> if the string isn't localized yet
	
	*/
	
    public func localized(from tableName: String?=nil, bundle: Bundle?=nil, comment: String="", value: String?=nil) -> String
	{
		let defaultName = self.uppercased()
		let defaultValue = value ?? "<< \(defaultName) >>"
		let bundle = bundle ?? Bundle.main
		
		var str = NSLocalizedString(
			self,
			tableName: tableName,
			bundle: bundle,
			value: defaultValue,
			comment: comment)
		
		// Fallback: If the string could not be found in the specified table, then try again with "tableName-custom"
		
		if str == defaultValue, let tableName = tableName
		{
			str = NSLocalizedString(
				self,
				tableName: tableName+"-custom",
				bundle: bundle,
				value: defaultValue,
				comment: comment)
		}
		
		return str
    }

}


//----------------------------------------------------------------------------------------------------------------------
