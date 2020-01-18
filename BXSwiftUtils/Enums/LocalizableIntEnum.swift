//**********************************************************************************************************************
//
//  LocalizableIntEnum.swift
//	Protocol for an int based enum that provides a localizedName accessor
//  Copyright ©2020 Peter Baumgartner. All rights reserved.
//
//**********************************************************************************************************************


import Foundation


//----------------------------------------------------------------------------------------------------------------------


public protocol LocalizableIntEnum
{
	var intValue : Int { get }
	var rawValue : Int { get }
	var localizedName : String { get }
}

public extension LocalizableIntEnum
{
	var intValue:Int { self.rawValue }
	
	var localizedName:String { "<<MISSING LOCALIZED NAME>>" }
}


//----------------------------------------------------------------------------------------------------------------------
