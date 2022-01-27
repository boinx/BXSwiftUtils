//**********************************************************************************************************************
//
//  Bundle+Localization.swift
//	Adds new methods to Bundle
//  Copyright ©2019 Peter Baumgartner. All rights reserved.
//
//**********************************************************************************************************************


import Foundation


//----------------------------------------------------------------------------------------------------------------------


public extension Bundle
{
	/// Returns the code of the preferred user interface language for this application
	
	var preferredLanguageCode:String
	{
		return Bundle.preferredLocalizations(from:Bundle.main.localizations).first ?? "en"
	}

}


//----------------------------------------------------------------------------------------------------------------------
