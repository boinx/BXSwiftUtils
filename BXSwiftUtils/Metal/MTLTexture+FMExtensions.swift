//**********************************************************************************************************************
//
//  MTLTexture+FMExtensions.swift
//	Adds convenience methods
//  Copyright ©2017 Peter Baumgartner. All rights reserved.
//
//**********************************************************************************************************************


import Metal
import CoreGraphics


//----------------------------------------------------------------------------------------------------------------------


@available(iOS 11.0,macOS 10.11, *)

public extension MTLTexture
{

	/// Creates a CGImage from a Metal texture.
	
	public func createImage(with colorSpaceName: CFString, bitmapInfo: CGBitmapInfo) -> CGImage?
	{
		// Allocate memory
		
		let w = self.width
		let h = self.height
		let rowBytes = ((w * 4 + 15) / 16) * 16
		let size = rowBytes * h
		var buffer = [UInt8](repeating:1,count:size)
		
		// Copy pixels from GPU texture to CPU buffer
		
		let region = MTLRegionMake2D(0,0,w,h)
		self.getBytes(&buffer,bytesPerRow:rowBytes,from:region,mipmapLevel:0)

		// Create CGImage
		
		guard let data = CFDataCreate(nil,buffer,size) else { return nil }
		guard let dataProvider = CGDataProvider(data:data) else { return nil }
		guard let colorspace = CGColorSpace(name:colorSpaceName) else { return nil }

		return CGImage(
			width: w,
			height: h,
			bitsPerComponent: 8,
			bitsPerPixel: 32,
			bytesPerRow: rowBytes,
			space: colorspace,
			bitmapInfo: bitmapInfo,
			provider: dataProvider,
			decode: nil,
			shouldInterpolate: false,
			intent: .defaultIntent)
	}
}


//----------------------------------------------------------------------------------------------------------------------
