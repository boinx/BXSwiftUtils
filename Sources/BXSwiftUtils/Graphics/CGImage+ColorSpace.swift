//**********************************************************************************************************************
//
//  CGImage+ColorSpace.swift
//	Adds convenience methods
//  Copyright ©2022-2024 Peter Baumgartner. All rights reserved.
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

	/// If this image is not a 3-channel sRGB image, then convert it to sRGB colorspace.
	/// If it was already sRGB then the original image is returned.
	
	func convertTosRGB() -> CGImage?
	{
		self.convert(to:CGColorSpace.sRGB)
	}
	
	
	/// If this image is not a 3-channel DisplayP3 image, then convert it to DisplayP3 colorspace.
	/// If it was already DisplayP3 then the original image is returned.
	
	func convertToDisplayP3() -> CGImage?
	{
		self.convert(to:CGColorSpace.displayP3)
	}
	
	
	/// Converts this image to the RGB color space with the specified name
	
	func convert(to newColorSpaceName:CFString) -> CGImage?
	{
		let w = self.width
		let h = self.height
		var bitsPerComponent = 8
        var bytesPerPixel = 4
		var bitmapInfo:UInt32 = /*CGBitmapInfo.byteOrder32Big.rawValue*/ kCGBitmapByteOrder32Host.rawValue /*CGBitmapInfo.byteOrder32Little.rawValue*/ | CGImageAlphaInfo.premultipliedFirst.rawValue
		
		if newColorSpaceName.isEDR	// Does new colorspace require 16bit floats?
		{
			bitsPerComponent = 16
			bytesPerPixel = 8
			bitmapInfo = kCGBitmapByteOrder16Host.rawValue | CGImageAlphaInfo.premultipliedLast.rawValue | CGBitmapInfo.floatComponents.rawValue
		}

		return self.convert(
			to:newColorSpaceName,
			bitsPerComponent:bitsPerComponent,
			bytesPerPixel:bytesPerPixel,
			bitmapInfo:bitmapInfo)
	}
	
	
	func convert(to newColorSpaceName:CFString, bitsPerComponent:Int, bytesPerPixel:Int, bitmapInfo:UInt32) -> CGImage?
	{
		guard let colorSpace = self.colorSpace else { return nil }
		
		// If already in the correct color space then return the original image. This is the fast path.
		
		if let oldColorSpaceName = colorSpace.name,
		   colorSpace.model == .rgb && oldColorSpaceName == newColorSpaceName,
		   self.bitsPerComponent == bitsPerComponent,
		   self.bitmapInfo.rawValue == bitmapInfo
		{
			return self
		}

		// Otherwise create a bitmap context with identical memory layout, but with the correct color space
		
		guard var newColorSpace = CGColorSpace(name:newColorSpaceName) else { return nil }

		let w = self.width
		let h = self.height
		var bitsPerComponent = bitsPerComponent
        var bytesPerPixel = bytesPerPixel
        var bytesPerRow = bytesPerPixel * w
		var bitmapInfo:UInt32 = bitmapInfo
		
		guard let context = CGContext(
			data:nil,
			width:w,
			height:h,
			bitsPerComponent:bitsPerComponent,
			bytesPerRow:bytesPerRow,
			space:newColorSpace,
			bitmapInfo:bitmapInfo) else { return nil }

		// Draw this image into the new bitmap and return the new image
		
		let rect = CGRect(x:0, y:0, width:w, height:h)

		context.setAllowsAntialiasing(false)
		context.setShouldAntialias(false)
		context.draw(self, in:rect)
		return context.makeImage()
	}
}


//----------------------------------------------------------------------------------------------------------------------
