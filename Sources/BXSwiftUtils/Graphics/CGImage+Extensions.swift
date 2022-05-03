//**********************************************************************************************************************
//
//  CGImage+Extensions.swift
//	Adds convenience methods
//  Copyright ©2022 Peter Baumgartner. All rights reserved.
//
//**********************************************************************************************************************


#if canImport(AppKit)
import AppKit
#endif

#if canImport(UIKit)
import UIKit
#endif

#if canImport(CoreGraphics)
import CoreGraphics
#endif


//----------------------------------------------------------------------------------------------------------------------


public extension CGImage
{
	/// Returns the CGImage with the specified name from the Resources of a particular Bundle
	
	static func image(named name:String, in bundle:Bundle?) -> CGImage?
	{
		#if os(macOS)
		
		let bundle = bundle ?? Bundle.main
		return bundle.image(forResource:name)?.CGImage
		
		#else
		
		UIImage(named:name, in:bundle, compatibleWith:nil)?.cgImage
		
		#endif
	}
}


//----------------------------------------------------------------------------------------------------------------------
