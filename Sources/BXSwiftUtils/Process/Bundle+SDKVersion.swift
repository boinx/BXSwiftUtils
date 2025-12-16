//**********************************************************************************************************************
//
//  Bundle+SDKVersion.swift
//	Adds new methods to Bundle
//  Copyright ©2025 Peter Baumgartner. All rights reserved.
//
//**********************************************************************************************************************


import Foundation


//----------------------------------------------------------------------------------------------------------------------


public extension Bundle
{
	/// Returns the version string of the SDK that was used for linking the app
	
	static var SDKVersion:String
	{
		guard let info = Bundle.main.infoDictionary else { return "" }
		guard let sdkName = info["DTSDKName"] as? String else { return "" }
		
		#if os(macOS)
		return sdkName.replacingOccurrences(of:"macosx", with:"")
		#else
		return sdkName.replacingOccurrences(of:"iOS", with:"")
		#endif
	}

	/// Returns the major version of the SDK that was used for linking the app

	static var SDKMajorVersion:Int
	{
		Int(SDKVersion.doubleValue ?? 0.0)
	}
}


//----------------------------------------------------------------------------------------------------------------------
