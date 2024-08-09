//**********************************************************************************************************************
//
//  CGColorSpace+Extensions.swift
//	Adds convenience methods
//  Copyright ©2024 Peter Baumgartner. All rights reserved.
//
//**********************************************************************************************************************


#if canImport(CoreGraphics)
import CoreGraphics
#endif


//----------------------------------------------------------------------------------------------------------------------


public extension CGColorSpace
{
	/// Returns the sRGB color space

	static func sRGB() -> CGColorSpace
	{
		CGColorSpace(name:CGColorSpace.sRGB)!
	}

	/// Returns the DisplayP3 color space

	static func displayP3() -> CGColorSpace
	{
		CGColorSpace(name:CGColorSpace.displayP3)!
	}
}


//----------------------------------------------------------------------------------------------------------------------


extension CFString
{
	/// Returns true if the name of the CGColorSpace contains "extended"

	public var isEDR:Bool
	{
		(self as String).lowercased().contains("extended")
	}
}


//----------------------------------------------------------------------------------------------------------------------
