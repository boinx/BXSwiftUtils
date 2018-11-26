//**********************************************************************************************************************
//
//  MTLTexture+Extensions.swift
//	Adds convenience methods
//  Copyright ©2017 Peter Baumgartner. All rights reserved.
//
//**********************************************************************************************************************


import Metal
import CoreGraphics
import CoreVideo


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
		let rowBytes = self.bufferBytesPerRow //((w * 4 + 15) / 16) * 16
		let size = rowBytes * h
		var buffer = [UInt8](repeating:0,count:size)
		
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
	
	
//----------------------------------------------------------------------------------------------------------------------


	/// Creates a CVPixelBuffer from a Metal texture
	
	public func createPixelBuffer(with pixelFormat:OSType = kCVPixelFormatType_32ARGB) -> CVPixelBuffer?
	{
		// Allocate a new buffer
		
		let width = self.width
		let height = self.height
		let rowbytes = self.bufferBytesPerRow
		let size = rowbytes * height
		
		guard let buffer = malloc(size) else
		{
			log.error {"MTLTexture.\(#function) ERROR out of memory"}
    		return nil
  		}
		
		// Free the buffer again once the CVPixelBuffer is deallocated
		
		let releaseCallback:CVPixelBufferReleaseBytesCallback =
		{
			_, ptr in
    		guard let ptr = ptr else { return }
    		free(UnsafeMutableRawPointer(mutating:ptr))
		}
		
		// Copy pixels from GPU texture to the buffer
		
		let region = MTLRegionMake2D(0,0,width,height)
		self.getBytes(buffer, bytesPerRow:rowbytes, from:region, mipmapLevel:0)

		// Wrap the buffer in a CVPixelBuffer
		
		var pixelbuffer:CVPixelBuffer? = nil

		let err = CVPixelBufferCreateWithBytes(
			kCFAllocatorDefault,
			width,
			height,
			pixelFormat,
			buffer,
			rowbytes,
			releaseCallback,
			nil,
			nil,
			&pixelbuffer)
		
		if err != noErr
		{
			log.error {"MTLTexture.\(#function) ERROR \(err) trying to create CVPixelBuffer"}
		}

		return pixelbuffer
	}
}


//----------------------------------------------------------------------------------------------------------------------
