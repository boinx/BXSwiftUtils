//**********************************************************************************************************************
//
//  CVPixelBuffer+Extensions.swift
//	Adds convenience methods
//  Copyright ©2018 Peter Baumgartner. All rights reserved.
//
//**********************************************************************************************************************


import CoreVideo
import Accelerate
import VideoToolbox


//----------------------------------------------------------------------------------------------------------------------


public extension CVPixelBuffer
{

	/// Resizes the image in a CVPixelBuffer to the specified size, returning a new CVPixelBuffer
	///  - parameter size: The new size of the resulting CVPixelBuffer
	///  - returns: A new CVPixelBuffer with the scaled image
	
	public func resized(to size:CGSize) -> CVPixelBuffer?
	{
		// Lock the CVPixelBuffer (self)
		
		let flags = CVPixelBufferLockFlags(rawValue: 0)
		guard kCVReturnSuccess == CVPixelBufferLockBaseAddress(self,flags) else { return nil }
		defer { CVPixelBufferUnlockBaseAddress(self,flags) }

		// Wrap CVPixelBuffer in a vImage_Buffer
		
		guard let srcData = CVPixelBufferGetBaseAddress(self) else { return nil }
		let srcWidth = CVPixelBufferGetWidth(self)
		let srcHeight = CVPixelBufferGetHeight(self)
		let srcRowBytes = CVPixelBufferGetBytesPerRow(self)
		var srcBuffer = vImage_Buffer(data:srcData, height:vImagePixelCount(srcHeight), width:vImagePixelCount(srcWidth), rowBytes:srcRowBytes)

		// Allocate a destination vImage_Buffer
		
		let dstWidth:Int = Int(ceil(size.width))
		let dstHeight:Int = Int(ceil(size.height))
		let dstRowBytes = 4 * dstWidth
		guard let dstData = malloc(dstHeight*dstRowBytes) else { return nil }
		var dstBuffer = vImage_Buffer(data: dstData, height:vImagePixelCount(dstHeight), width:vImagePixelCount(dstWidth), rowBytes:dstRowBytes)

		// Scale the image from srcBuffer to dstBuffer
		
		let error = vImageScale_ARGB8888(&srcBuffer, &dstBuffer, nil, vImage_Flags(0))
		
		if error != kvImageNoError
		{
			free(dstData)
			return nil
		}

		// Wrap dstBuffer in a new CVPixelBuffer and return it
		
		let releaseCallback: CVPixelBufferReleaseBytesCallback =
		{
			_,ptr in
			if let ptr = ptr
			{
		  		free(UnsafeMutableRawPointer(mutating:ptr))
			}
		}

		let pixelFormat = CVPixelBufferGetPixelFormatType(self)
		var dstPixelBuffer: CVPixelBuffer? = nil
		
		let status = CVPixelBufferCreateWithBytes(
			nil,
			dstWidth,
			dstHeight,
			pixelFormat,
			dstData,
			dstRowBytes,
			releaseCallback,
			nil,nil,
			&dstPixelBuffer)
		
		if status != kCVReturnSuccess
		{
			free(dstData)
			return nil
		}
		
		return dstPixelBuffer
	}


	/// Returns a CGImage for a CVPixelBuffer
	
	public var CGImage : CGImage?
	{
    	var image:CGImage? = nil
		VTCreateCGImageFromCVPixelBuffer(self,nil,&image)
		return image
	}
}


//----------------------------------------------------------------------------------------------------------------------
