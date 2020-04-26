//**********************************************************************************************************************
//
//  Optional+logDescription.swift
//	Provides nice formatting for logging optional values
//  Copyright ©2020 Peter Baumgartner. All rights reserved.
//
//**********************************************************************************************************************


public extension Optional
{
	/// Returns a nicely formatted string that is suitable for logging an Optional value.
	
	var logDescription : String
	{
		if let value = self
		{
			return "\(value)"
		}
		
		return "nil"
	}
}


//----------------------------------------------------------------------------------------------------------------------
