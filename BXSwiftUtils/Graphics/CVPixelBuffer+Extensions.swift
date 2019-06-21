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
	
	func resized(to size:CGSize) -> CVPixelBuffer?
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


//----------------------------------------------------------------------------------------------------------------------


	/// Returns a CGImage for a CVPixelBuffer
	
	@available(OSX 10.11, *)
	var CGImage : CGImage?
	{
    	var image:CGImage? = nil
		VTCreateCGImageFromCVPixelBuffer(self,options:nil,imageOut:&image)
		return image
	}


//----------------------------------------------------------------------------------------------------------------------


	
	/// Creates a deep copy a CVPixelBuffer
	
    func copy() -> CVPixelBuffer?
    {
    	guard CFGetTypeID(self) == CVPixelBufferGetTypeID() else { return nil }

		// Create a copy of the CVPixelBuffer
		
		#if !(targetEnvironment(simulator)) // Not sure why this is necessary to make unit test work?
		let attributes:[CFString:Any] =
		[
			kCVPixelBufferIOSurfaceCoreAnimationCompatibilityKey: true,
			kCVPixelBufferMetalCompatibilityKey: true
		]
		#else
		let attributes:[CFString:Any] =
		[
			kCVPixelBufferMetalCompatibilityKey: true
		]
		#endif

		var copy:CVPixelBuffer? = nil

		CVPixelBufferCreate(
			nil,
			CVPixelBufferGetWidth(self),
			CVPixelBufferGetHeight(self),
			CVPixelBufferGetPixelFormatType(self),
			attributes as CFDictionary,
			&copy)
		
		if let copy = copy
		{
			// Lock buffers while we are copying the pixel data
			
			CVPixelBufferLockBaseAddress(self,.readOnly)
			CVPixelBufferLockBaseAddress(copy,[])
			
			defer
			{
				CVPixelBufferUnlockBaseAddress(copy,[])
				CVPixelBufferUnlockBaseAddress(self,.readOnly)
			}
			
			// Copy planar image data
			
			if CVPixelBufferIsPlanar(self)
			{
				for planeIndex in 0 ..< CVPixelBufferGetPlaneCount(self)
				{
					var srcBuffer = self.vImageBuffer(forPlane:planeIndex)
					var dstBuffer = copy.vImageBuffer(forPlane:planeIndex)
					let error = vImageCopyBuffer(&srcBuffer, &dstBuffer, 1, vImage_Flags(kvImageNoFlags))
					
					if error != kvImageNoError
					{
						NSLog("CVPixelBuffer.copy() - Error \(error) from vImageCopyBuffer")
					}
				}
			}
			
			// Copy interleaved image data
			
			else
			{
				var srcBuffer = self.vImageBuffer()
				var dstBuffer = copy.vImageBuffer()
				let error = vImageCopyBuffer(&srcBuffer, &dstBuffer, 4, vImage_Flags(kvImageNoFlags))
				
				if error != kvImageNoError
				{
					NSLog("CVPixelBuffer.copy() - Error \(error) from vImageCopyBuffer")
				}
			}
		}
		
		return copy
    }

	
	
//----------------------------------------------------------------------------------------------------------------------


	/// Returns a vImage_Buffer struct for an interleaved CVPixelBuffer
	
    func vImageBuffer() -> vImage_Buffer
    {
		let ptr = CVPixelBufferGetBaseAddress(self)
		let width = vImagePixelCount(CVPixelBufferGetWidth(self))
		let height = vImagePixelCount(CVPixelBufferGetHeight(self))
		let rowBytes = CVPixelBufferGetBytesPerRow(self)
		
		return vImage_Buffer(data:ptr, height:height, width:width, rowBytes:rowBytes)
    }


	/// Returns a vImage_Buffer struct for an planar CVPixelBuffer
	
    func vImageBuffer(forPlane plane:Int) -> vImage_Buffer
    {
		let ptr = CVPixelBufferGetBaseAddressOfPlane(self,plane)
		let width = vImagePixelCount(CVPixelBufferGetWidthOfPlane(self,plane))
		let height = vImagePixelCount(CVPixelBufferGetHeightOfPlane(self,plane))
		let rowBytes = CVPixelBufferGetBytesPerRowOfPlane(self,plane)
		
		return vImage_Buffer(data:ptr, height:height, width:width, rowBytes:rowBytes)
    }
}


//----------------------------------------------------------------------------------------------------------------------
