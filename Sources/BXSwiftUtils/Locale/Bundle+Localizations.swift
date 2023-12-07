//**********************************************************************************************************************
//
//  Bundle+Localization.swift
//	Adds new methods to Bundle
//  Copyright ©2019 Peter Baumgartner. All rights reserved.
//
//**********************************************************************************************************************


import Foundation


//----------------------------------------------------------------------------------------------------------------------


extension Bundle
{
	/// Returns the code of the preferred user interface language for this application
	
	public var preferredLanguageCode:String
	{
		return Bundle.preferredLocalizations(from:Bundle.main.localizations).first ?? "en"
	}

	/// Returns the Bundle that contains the specified class
	
	public static func `for`(_ type:AnyClass) -> Bundle
	{
		Bundle(for:type)
	}
}


//----------------------------------------------------------------------------------------------------------------------
