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

	/// Returns the number of bytes per row in this MTLTexture. If this info is not available from the
	/// MTLTexture, a recommended value will be calculated.
	
	public var recommendedRowBytes:Int
	{
		let width = self.width
		let rowBytes = self.bufferBytesPerRow
		return rowBytes > 0 ? rowBytes : ((width * 4 + 15) / 16) * 16
	}
	
	
//----------------------------------------------------------------------------------------------------------------------


	/// Creates a CGImage from a Metal texture.
	
	public func createImage(with colorSpaceName: CFString, bitmapInfo: CGBitmapInfo) -> CGImage?
	{
		// Allocate memory
		
		let w = self.width
		let h = self.height
		let rowBytes = self.recommendedRowBytes
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
		let rowBytes = self.recommendedRowBytes
		let size = rowBytes * height
		
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
		self.getBytes(buffer, bytesPerRow:rowBytes, from:region, mipmapLevel:0)

		// Wrap the buffer in a CVPixelBuffer
		
		var pixelbuffer:CVPixelBuffer? = nil

		let err = CVPixelBufferCreateWithBytes(
			kCFAllocatorDefault,
			width,
			height,
			pixelFormat,
			buffer,
			rowBytes,
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


	/// Copies a Metal texture to a CVPixelBuffer

	public func copy(to pixelBuffer:CVPixelBuffer)
	{
		// Check that the texture and the pixelBuffer match in size
		
		let srcWidth = self.width
		let srcHeight = self.height
		let srcRowbytes = self.recommendedRowBytes
		
		let dstWidth = CVPixelBufferGetWidth(pixelBuffer)
		let dstHeight = CVPixelBufferGetHeight(pixelBuffer)
		let dstRowbytes = CVPixelBufferGetBytesPerRow(pixelBuffer)

		guard srcWidth == dstWidth else { return }
		guard srcHeight == dstHeight else { return }
//		guard srcRowbytes == srcRowbytes || srcRowbytes == 0 else { return }

		// Copy pixels from GPU texture to the buffer
		
		CVPixelBufferLockBaseAddress(pixelBuffer,[])
		defer { CVPixelBufferUnlockBaseAddress(pixelBuffer,[]) }
		
		guard let buffer = CVPixelBufferGetBaseAddress(pixelBuffer) else { return }
		let region = MTLRegionMake2D(0,0,srcWidth,srcHeight)
		self.getBytes(buffer, bytesPerRow:dstRowbytes, from:region, mipmapLevel:0)
	}
}


//----------------------------------------------------------------------------------------------------------------------
