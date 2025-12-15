//**********************************************************************************************************************
//
//  Thread+stackTrace.swift
//  Convenience function to log a stacktrace
//  Copyright ©2021 Peter Baumgartner. All rights reserved.
//
//**********************************************************************************************************************


import Foundation


//----------------------------------------------------------------------------------------------------------------------


public extension Thread
{
	static var stackTrace:String
	{
		Thread.callStackSymbols
			.dropFirst()
			.joined(separator:"\n")
	}
	
	static var icon:String
	{
		Thread.isMainThread ? "◼︎" : "☐"
	}
}


//----------------------------------------------------------------------------------------------------------------------
