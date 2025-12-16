//**********************************************************************************************************************
//
//  ProcessInfo+Version.swift
//	Adds new methods to ProcessInfo
//  Copyright ©2021 Peter Baumgartner. All rights reserved.
//
//**********************************************************************************************************************


import Foundation


//----------------------------------------------------------------------------------------------------------------------


public extension ProcessInfo
{
	/// Returns the major version of the OS we are running on
	
	static var osMajorVersion:Int
	{
		ProcessInfo.processInfo.operatingSystemVersion.majorVersion
	}

	#if os(macOS)
	
	static var isRunningOnBigSurOrNewer:Bool
	{
		Self.osMajorVersion >= 11
	}

	static var isRunningOnMontereyOrNewer:Bool
	{
		Self.osMajorVersion >= 12
	}
	
	#endif
}


//----------------------------------------------------------------------------------------------------------------------
