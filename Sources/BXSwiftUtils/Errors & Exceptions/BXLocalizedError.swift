//**********************************************************************************************************************
//
//  Thread+stackTrace.swift
//  Convenience function to log a stacktrace
//  Copyright ©2021 Peter Baumgartner. All rights reserved.
//
//**********************************************************************************************************************


import Foundation


//----------------------------------------------------------------------------------------------------------------------


public protocol BXLocalizedError : LocalizedError
{
	var localizedTitle:String { get }

	var localizedDescription:String { get }
}


public extension BXLocalizedError
{
	var localizedTitle:String
	{
		self.errorDescription ?? ""
	}

	var localizedDescription:String
	{
		self.failureReason ?? self.recoverySuggestion ?? ""
	}
}


//----------------------------------------------------------------------------------------------------------------------
