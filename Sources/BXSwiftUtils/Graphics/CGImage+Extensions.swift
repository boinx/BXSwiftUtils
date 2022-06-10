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


	/// Returns a tinted version of this image
	/// - parameter tintColor: The color for tinting the image
	/// - returns: A monochrome version of the image
	
	func tinted(with tintColor:CGColor) -> CGImage?
	{
		let w = self.width
		let h = self.height
        let bytesPerPixel = 4
        let bytesPerRow = bytesPerPixel * width
		let bitmapInfo = self.bitmapInfo.rawValue
		let rect = CGRect(x:0, y:0, width:w, height:h)
		
		// Create a bitmap buffer
		
		if let colorSpace = self.colorSpace ?? CGColorSpace(name:CGColorSpace.sRGB),
		   let context = CGContext(data:nil, width:w, height:h, bitsPerComponent:8, bytesPerRow:bytesPerRow, space:colorSpace, bitmapInfo:bitmapInfo)
		{
			// Draw the image into the bitmap
			
			context.setAllowsAntialiasing(false)
			context.setShouldAntialias(false)
			context.draw(self, in:rect)
			
			// Draw the tintColor on top, preserving the alpha channel
			
			context.setBlendMode(.sourceIn) // R = S*Da
			context.setFillColor(tintColor)
			context.fill(rect)
			
			return context.makeImage()
        }
		
        return nil
	}
}


//----------------------------------------------------------------------------------------------------------------------
