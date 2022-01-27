//**********************************************************************************************************************
//
//  NSLocale+FMExtensions.swift
//	Adds new methods to NSLocale
//  Copyright ©2016 Peter Baumgartner. All rights reserved.
//
//**********************************************************************************************************************


import Foundation


//----------------------------------------------------------------------------------------------------------------------


public extension NSLocale
{
	/// Returns the language code ("en","de",etc) of the preferred language the user has selected
	
	static var preferredUserLanguage : String
	{
		var languageCode = "en"
		
		// Due to a change in macOS 10.12 preferredLanguages no longer just returns an array of language identifiers,
		// but rather an array of full specifiers, like "en-UK" or de-AT". We want just the language like "en" and "de".
		// For this reason this function filters for just the language code.
	
		if let preferredLanguage = NSLocale.preferredLanguages.first
		{
			let components = NSLocale.components(fromLocaleIdentifier:preferredLanguage)
			
			if let value = components[NSLocale.Key.languageCode.rawValue]
			{
				languageCode = value
			}
		}
		
		return languageCode
	}

}


//----------------------------------------------------------------------------------------------------------------------
