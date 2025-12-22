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
	
	static var SDKVersionString:String
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

	static var SDKVersionMajor:Int
	{
		let parts = SDKVersionString.components(separatedBy:".")
		guard parts.count >= 1 else { return 0 }
		return Int(parts[0]) ?? 0
	}

	/// Returns the minor version of the SDK that was used for linking the app

	static var SDKVersionMinor:Int
	{
		let parts = SDKVersionString.components(separatedBy:".")
		guard parts.count >= 2 else { return 0 }
		return Int(parts[1]) ?? 0
	}

	/// Returns the revision version of the SDK that was used for linking the app

	static var SDKVersionRevision:Int
	{
		let parts = SDKVersionString.components(separatedBy:".")
		guard parts.count >= 3 else { return 0 }
		return Int(parts[2]) ?? 0
	}

	/// Returns the version number of the SDK that was used for linking the app as a Double

	static var SDKVersionNumber:Double
	{
		Double(SDKVersionMajor) + Double(SDKVersionMinor)/10 + Double(SDKVersionRevision)/1000
	}
}


//----------------------------------------------------------------------------------------------------------------------
