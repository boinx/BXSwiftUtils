//**********************************************************************************************************************
//
//  CVPixelBuffer+Extensions.swift
//	Adds convenience methods
//  Copyright ©2018-2024 Peter Baumgartner. All rights reserved.
//
//**********************************************************************************************************************


import CoreVideo
import Accelerate
import VideoToolbox


//----------------------------------------------------------------------------------------------------------------------


public extension CVPixelBuffer
{
	/// Creates an IOSurface backed CVPixelBuffer of the specified size.
	///
	/// When creating a MTLTexture from this CVPixelBuffer, you can render directly to this CVPixelBuffer.

	static func create(width:Int, height:Int, pixelFormat:OSType = kCVPixelFormatType_32BGRA) -> CVPixelBuffer?
	{
		guard width > 0 else { return nil }
		guard height > 0 else { return nil }
			
		let createIOSurfaceProperties:[String:Any] = [:] // This forces creation of an IOSurface

		let attributes:[String:Any] =
		[
			kCVPixelBufferPixelFormatTypeKey as String : NSNumber(value: kCVPixelFormatType_32BGRA),
			kCVPixelBufferWidthKey as String : width,
			kCVPixelBufferHeightKey as String : height,
			kCVPixelBufferMetalCompatibilityKey as String : true,
			kCVPixelBufferIOSurfacePropertiesKey as String : createIOSurfaceProperties
		]

		var pixelBuffer:CVPixelBuffer? = nil
		let result = CVPixelBufferCreate(nil, width, height, pixelFormat, attributes as CFDictionary, &pixelBuffer)
		guard result == kCVReturnSuccess else { return nil }
		return pixelBuffer
	}


//----------------------------------------------------------------------------------------------------------------------


	/// Returns a CGImage for a CVPixelBuffer
	
	@available(OSX 10.11, *)
	
	var CGImage : CGImage?
	{
    	var image:CGImage? = nil
		VTCreateCGImageFromCVPixelBuffer(self, options:nil, imageOut:&image)
		return image
	}


//----------------------------------------------------------------------------------------------------------------------


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


	
	/// Creates a deep copy a CVPixelBuffer
	
    func copy() -> CVPixelBuffer?
    {
    	guard CFGetTypeID(self) == CVPixelBufferGetTypeID() else { return nil }

		// Create a copy of the CVPixelBuffer
		
		#if !(targetEnvironment(simulator))
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
			kCFAllocatorDefault,
			CVPixelBufferGetWidth(self),
			CVPixelBufferGetHeight(self),
			CVPixelBufferGetPixelFormatType(self),
			attributes as CFDictionary,
			&copy)
		
		if let copy = copy
		{
			CVBufferPropagateAttachments(self as CVBuffer, copy as CVBuffer)
			
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
    
    
//----------------------------------------------------------------------------------------------------------------------


	/// Returns a description string for debugging purposes
	
    var debugDescription:String
    {
		CVPixelBufferLockBaseAddress(self,.readOnly)
		defer { CVPixelBufferUnlockBaseAddress(self,.readOnly) }

		let w = CVPixelBufferGetWidth(self)
		let h = CVPixelBufferGetHeight(self)
		let rowBytes = CVPixelBufferGetBytesPerRow(self)
		let size = CVPixelBufferGetDataSize(self)
		let isPlanar = CVPixelBufferIsPlanar(self)
		let planeCount = CVPixelBufferGetPlaneCount(self)
		var description = "CVPixelBuffer  width=\(w)  height=\(h)"

		if isPlanar
		{
			for i in 0 ..< planeCount
			{
				let address = CVPixelBufferGetBaseAddressOfPlane(self,i)?.debugDescription ?? "nil"
				description += "  buffer\(i)=\(address)"
			}
			
			description += "  size=\(size)"
		}
		else
		{
			let address = CVPixelBufferGetBaseAddress(self)?.debugDescription ?? "nil"
			description += "  rowBytes=\(rowBytes)  address=\(address)  size=\(size)"
		}

		return description
    }
    
    /// Checks if the backing buffer is allocated and the size is the expected one
	
    func confirmAllocatedSize(_ size:CGSize) -> Bool
    {
		CVPixelBufferLockBaseAddress(self,.readOnly)
		defer { CVPixelBufferUnlockBaseAddress(self,.readOnly) }

		if CVPixelBufferIsPlanar(self)
		{
			let planeCount = CVPixelBufferGetPlaneCount(self)

			for i in 0 ..< planeCount
			{
				let address = CVPixelBufferGetBaseAddressOfPlane(self,i)
				guard address != nil else { return false }
			}

			return true
		}
		else
		{
			let address = CVPixelBufferGetBaseAddress(self)
			guard address != nil else { return false }
		}
		
		let w = CVPixelBufferGetWidth(self)
		let h = CVPixelBufferGetHeight(self)
		guard Int(size.width) == w && Int(size.height) == h else { return false }
		
		return true
    }
    
    
    /// Converts this CVPixelBuffer to a new one with specified CGColorSpace and CVPixelFormatType
    
    func convert(to colorSpace:CGColorSpace, pixelFormat:OSType, session:VTPixelTransferSession?) -> CVPixelBuffer?
    {
        guard let pixelTransferSession = session else {  return nil }

        // Create a new CVPixelBuffer with the desired pixel format and color space

        let srcBuffer = self
        var dstBuffer: CVPixelBuffer?
        
        let dstAttributes:[CFString:Any] =
        [
            kCVPixelBufferWidthKey: CVPixelBufferGetWidth(srcBuffer),
            kCVPixelBufferHeightKey: CVPixelBufferGetHeight(srcBuffer),
            kCVPixelBufferPixelFormatTypeKey: pixelFormat,
            kCVPixelBufferIOSurfacePropertiesKey: [:], // Necessary to enable hardware acceleration

//            kCVImageBufferCGColorSpaceKey: colorSpace,
//            kCVImageBufferColorPrimariesKey: kCVImageBufferColorPrimaries_P3_D65,
//            kCVImageBufferTransferFunctionKey: kCVImageBufferTransferFunction_sRGB,
//            kCVImageBufferYCbCrMatrixKey: kCVImageBufferYCbCrMatrix_ITU_R_2020,
            
            kVTPixelTransferPropertyKey_DestinationColorPrimaries: kCVImageBufferColorPrimaries_P3_D65,
            kVTPixelTransferPropertyKey_DestinationTransferFunction: kCVImageBufferTransferFunction_sRGB,
            kVTPixelTransferPropertyKey_DestinationYCbCrMatrix: kCVImageBufferYCbCrMatrix_ITU_R_2020,
        ]

//        kVTPixelTransferPropertyKey_DestinationColorPrimaries
//        kVTPixelTransferPropertyKey_DestinationTransferFunction
//        kVTPixelTransferPropertyKey_DestinationICCProfile
//        kVTPixelTransferPropertyKey_DestinationYCbCrMatrix
        

        
        
        let bufferStatus = CVPixelBufferCreate(kCFAllocatorDefault,
                                               CVPixelBufferGetWidth(srcBuffer),
                                               CVPixelBufferGetHeight(srcBuffer),
                                               pixelFormat,
                                               dstAttributes as CFDictionary,
                                               &dstBuffer)
        
        guard bufferStatus == kCVReturnSuccess, let dstBuffer = dstBuffer else
        {
            print("Error creating destination pixel buffer: \(bufferStatus)")
            return nil
        }
        
        // Transfer the source pixel buffer to the destination pixel buffer using VTPixelTransferSessionTransferImage
        
        let transferStatus = VTPixelTransferSessionTransferImage(pixelTransferSession, from:srcBuffer, to:dstBuffer)
        
        if transferStatus != noErr
        {
            print("Error transferring pixel buffer: \(transferStatus)")
            return nil
        }

        return dstBuffer
    }

    
    /// Returns the CGColorSpace of this CVPixelBuffer
    
    var colorSpace:CGColorSpace?
    {
        #if COREVIDEO_SUPPORTS_COLORSPACE
        return CVImageBufferGetColorSpace(self)?.takeUnretainedValue()
        #else
        return nil
        #endif
    }
}


//----------------------------------------------------------------------------------------------------------------------
