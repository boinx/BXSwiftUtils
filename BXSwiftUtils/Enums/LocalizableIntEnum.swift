//**********************************************************************************************************************
//
//  LocalizableIntEnum.swift
//	Protocol for an int based enum that provides a localizedName accessor
//  Copyright ©2020 Peter Baumgartner. All rights reserved.
//
//**********************************************************************************************************************


import Foundation


//----------------------------------------------------------------------------------------------------------------------


/// Returns a localized name (and optionally an icon) for displaying an enum datatype in the user interface

public protocol LocalizableIntEnum
{
	/// The rawValue of this enum case. Can be used to attach to UI items as metadata.
	
	var rawValue : Int { get }
	
	/// The intValue of this enum case. Can be used to attach to UI items as metadata.
	
	var intValue : Int { get }

	/// The localized name of this enum case for displaying in the user interface
	
	var localizedName : String { get }
}


//----------------------------------------------------------------------------------------------------------------------


public extension LocalizableIntEnum
{
	// intValue is just a synonym for rawValue
	
	var intValue:Int
	{
		return self.rawValue
	}
	
	// Default string if localization was not provided
	
	var localizedName:String
	{
		return "<<NOT LOCALIZED>>"
	}
}


//----------------------------------------------------------------------------------------------------------------------
