//**********************************************************************************************************************
//
//  CGImage+Convert.swift
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
	/// Creates an CGImage from a data buffer.
	
	class func convert(from data:Data, index:Int=0) -> CGImage?
	{
		guard let source = CGImageSourceCreateWithData(data as CFData,nil)
		else { return nil }
		
		guard let image = CGImageSourceCreateImageAtIndex(source,index,nil)
		else { return nil }
		
		return image
	}


	/// If this CGImage was created from a bitmap CGContext, then the bitmap data is returned.

	var bitmapData:Data?
	{
		guard let dataProvider = self.dataProvider else { return nil }
		guard let cfdata = dataProvider.data else { return nil }
		return cfdata as Data
	}


//----------------------------------------------------------------------------------------------------------------------


	/// Converts a CGImage to the specified bitmap format
	/// - parameter bitmapInfo: Defines the byte order and alpha
	/// - returns: A CGImage with the desired byte order
	
	func convert(to bitmapInfo:UInt32) -> CGImage?
	{
		let w = self.width
		let h = self.height
        let bytesPerPixel = 4
        let bytesPerRow = bytesPerPixel * width
		
		if let colorSpace = self.colorSpace ?? CGColorSpace(name:CGColorSpace.sRGB),
		   let context = CGContext(data:nil, width:w, height:h, bitsPerComponent:8, bytesPerRow:bytesPerRow, space:colorSpace, bitmapInfo:bitmapInfo)
		{
			let rect = CGRect(x:0, y:0, width:w, height:h)
			
			context.setAllowsAntialiasing(false)
			context.setShouldAntialias(false)
			context.draw(self, in:rect)
			
			return context.makeImage()
        }
		
        return nil
	}


//----------------------------------------------------------------------------------------------------------------------


	/// Scales the image to the specified size
	
	func scale(to size:CGSize) -> CGImage?
	{
		// Create a bitmap context of the desired size
		
		let w = Int(ceil(size.width))
		let h = Int(ceil(size.height))
		let rowbytes = 4*w // ((4*w + 15) / 16) * 16
		let rect = CGRect(x:0, y:0, width:w, height:h)
		let bitmapInfo = CGImageAlphaInfo.premultipliedLast.rawValue
		
        guard let colorspace = self.colorSpace else { return nil }
		
        guard let context = CGContext(
        	data: nil,
        	width: w,
        	height: h,
        	bitsPerComponent: 8,
        	bytesPerRow: rowbytes,
        	space:colorspace,
        	bitmapInfo: bitmapInfo) else { return nil }
		
        // Draw image to the context thus resizing it
		
        context.interpolationQuality = .high
        context.draw(self, in:rect)
        return context.makeImage()
 	}


//----------------------------------------------------------------------------------------------------------------------


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
