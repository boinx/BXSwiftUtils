//**********************************************************************************************************************
//
//  Double+clusteredDuration.swift
//	UndoManager extensions
//  Copyright ©2021-2023 Peter Baumgartner. All rights reserved.
//
//**********************************************************************************************************************


import Foundation


//----------------------------------------------------------------------------------------------------------------------


extension Double
{
	/// Clusters the duration in self into several groups to make statistics easier
	
	public var clusteredDuration:String
	{
		let duration = self
		var clustered = "unknown"
		
		if duration < 10*60
		{
			clustered = "< 10 min"
		}
		else if duration < 30*60
		{
			clustered = "< 30 min"
		}
		else if duration < 60*60
		{
			clustered = "< 1h"
		}
		else
		{
			let n = Int(duration / 3600.0 + 0.5)
			clustered = "about \(n)h"
		}
		
		return clustered
	}
}


//----------------------------------------------------------------------------------------------------------------------
