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
	/// Returns the DisplayP3 color space

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
