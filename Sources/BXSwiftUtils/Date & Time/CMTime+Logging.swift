//**********************************************************************************************************************
//
//  CMTime+Logging.swift
//	Adds logging description to CMTime
//  Copyright ©2016 Peter Baumgartner. All rights reserved.
//
//**********************************************************************************************************************


import CoreMedia


//----------------------------------------------------------------------------------------------------------------------


extension CoreMedia.CMTime : Swift.CustomDebugStringConvertible
{

	/// Returns a string that is suitable for logging
	
	public var debugDescription : String
	{
		let value = self.value
		let timescale = self.timescale
		return "CMTime(\(value),\(timescale))"
	}

}


//----------------------------------------------------------------------------------------------------------------------


