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
	
	- Parameter tableName: The name of the .strings file. Provide nil to use the default Localized.strings
	- Parameter tableSuffix: An optional suffix that get appended to the tableName
	- Parameter comment: Provide help to the translator by explaining the context where this string is being used
	- Parameter bundle: Provide nil to use the default Bundle.main()
	- Parameter value: The default string in the development language
	- Returns: The localized string (or << KEY >> if the string isn't localized yet)
	
	*/
	
    public func localized(from tableName: String?=nil, tableSuffix: String?="-custom", bundle: Bundle?=nil, comment: String="", value: String?=nil) -> String
	{
		let defaultName = self.uppercased()
		let defaultValue = value ?? "<< \(defaultName) >>"
		let bundle = bundle ?? Bundle.main
		
		// If tableName and tableSuffix are both speficied then look there first to save time
		
		var str = defaultValue
		
		if let tableName = tableName, let tableSuffix = tableSuffix
		{
			str = NSLocalizedString(
				self,
				tableName: tableName+tableSuffix,
				bundle: bundle,
				value: defaultValue,
				comment: comment)
		}

		// If the string was not found, then just in tableName as fallback
		
		if str == defaultValue
		{
			str = NSLocalizedString(
				self,
				tableName: tableName,
				bundle: bundle,
				value: defaultValue,
				comment: comment)
		}
		
		return str
    }

}


//----------------------------------------------------------------------------------------------------------------------
