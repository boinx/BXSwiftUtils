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
import MetalPerformanceShaders


//----------------------------------------------------------------------------------------------------------------------


@available(iOS 11.0,macOS 10.11, tvOS 13.0, *)

public extension MTLTexture
{

    /// Creates a MTLTexture from bitmap data with the specified parameters. This call lets you choose the MTLPixelFormat, which the regular MTKTextureLoader
    /// function won't let you do. That way you can create 16bit textures.
    
    static func newTexture(device:MTLDevice, bitmapData:Data, width:Int, height:Int, rowBytes:Int, pixelFormat:MTLPixelFormat, textureUsage:MTLTextureUsage, storageMode:MTLStorageMode, mipmapped:Bool) -> MTLTexture?
    {
        // Create a new texture
        
        let desc = MTLTextureDescriptor.texture2DDescriptor(
            pixelFormat:pixelFormat,
            width:width,
            height:height,
            mipmapped:mipmapped)
            
        desc.usage = textureUsage
        desc.storageMode = storageMode
        
        let region = MTLRegionMake2D(0,0,width,height)
        let texture = device.makeTexture(descriptor:desc)
        
        // Copy the pixel data into the texture
        
        bitmapData.withUnsafeBytes
        {
            (bytes:UnsafeRawBufferPointer) in
            guard let address = bytes.baseAddress else { return }
            
            texture?.replace(
                region:region,
                mipmapLevel:0,
                withBytes:address,
                bytesPerRow:rowBytes)
        }

//        bitmapData.withUnsafeBytes    // Old code is deprecated, but still works
//        {
//            bytes in
//
//            texture?.replace(
//                region:region,
//                mipmapLevel:0,
//                withBytes:bytes,
//                bytesPerRow:rowBytes)
//        }

        return texture
    }

    
    /// Creates a new MTLTexture with the same size and format
	
	func newTextureWithSameFormat() -> MTLTexture?
	{
		let desc = MTLTextureDescriptor.texture2DDescriptor(
			pixelFormat:pixelFormat,
			width:width,
			height:height,
			mipmapped:mipmapLevelCount>1)
			
		desc.storageMode = self.storageMode
		desc.usage = self.usage
		
		if #available(macOS 10.14, iOS 12.0, *)
		{
			desc.allowGPUOptimizedContents = self.allowGPUOptimizedContents
		}
		
		let texture = self.device.makeTexture(descriptor:desc)
		return texture
	}

    
    func newTexture(withPixelFormat pixelFormat:MTLPixelFormat) -> MTLTexture?
    {
        let desc = MTLTextureDescriptor.texture2DDescriptor(
            pixelFormat:pixelFormat,
            width:self.width,
            height:self.height,
            mipmapped:self.mipmapLevelCount>1)
            
        desc.storageMode = self.storageMode
        desc.usage = self.usage
        
        if #available(macOS 10.14, iOS 12.0, *)
        {
            desc.allowGPUOptimizedContents = self.allowGPUOptimizedContents
        }
        
        let texture = self.device.makeTexture(descriptor:desc)
        return texture
    }

    
    func convertColorSpace(srcSolorSpaceName:CFString, dstSolorSpaceName:CFString, dstPixelFormat:MTLPixelFormat, alphaType:MPSAlphaType) -> MTLTexture?
    {
        guard let srcColorSpace = CGColorSpace(name:srcSolorSpaceName) else { return nil }
        guard let dstColorSpace = CGColorSpace(name:dstSolorSpaceName) else { return nil }
        
        return self.convertColorSpace(
            srcColorSpace: srcColorSpace,
            dstColorSpace: dstColorSpace,
            dstPixelFormat: dstPixelFormat,
            alphaType: alphaType)
    }


    func convertColorSpace(srcColorSpace:CGColorSpace, dstColorSpace:CGColorSpace, dstPixelFormat:MTLPixelFormat, alphaType:MPSAlphaType) -> MTLTexture?
    {
        // If source and dest colorspaces match, then we can return the texture as is
        
        if srcColorSpace.name == dstColorSpace.name && self.pixelFormat == dstPixelFormat { return self }

        // Otherwise try to convert it to desired colorspace. In case of failure return nil
        
        let conversionInfo = CGColorConversionInfo(src:srcColorSpace,  dst:dstColorSpace)
        
        let imageConversion = MPSImageConversion(
            device: self.device,
            srcAlpha: alphaType,
            destAlpha: alphaType,
            backgroundColor: nil,
            conversionInfo: conversionInfo)
        
        let srcTexture = self
        guard let dstTexture = self.newTexture(withPixelFormat:dstPixelFormat) else { return nil }
        
        guard let commandQueue = device.makeCommandQueue() else { return nil }
        guard let commandBuffer = commandQueue.makeCommandBuffer() else { return nil }
        
        imageConversion.encode(
            commandBuffer: commandBuffer,
            sourceTexture: srcTexture,
            destinationTexture: dstTexture)
        
        commandBuffer.commit()
        commandBuffer.waitUntilCompleted()
        
        return dstTexture
    }


   //----------------------------------------------------------------------------------------------------------------------


	/// Returns the number of bytes per row in this MTLTexture. If this info is not available from the
	/// MTLTexture, a recommended value will be calculated.
	
	var recommendedRowBytes:Int
	{
		let width = self.width
		var rowBytes = ((width * 4 + 15) / 16) * 16
		
		if #available(macOS 10.12,*)
		{
			let rb = self.bufferBytesPerRow
			if rb > 0 { rowBytes = rb }
		}
		
		return rowBytes
	}
	
	
//----------------------------------------------------------------------------------------------------------------------


	/// Creates a CGImage from a Metal texture.
	
	func createImage(with colorSpaceName: CFString, bitmapInfo: CGBitmapInfo) -> CGImage?
	{
		// Get dimensions
		
		let w = self.width
		let h = self.height
		let rowBytes = self.recommendedRowBytes

		guard w > 0 && h > 0 && rowBytes > 0 else { return nil }
		
		// Allocate buffer
		
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
	
//	func createPixelBuffer(with pixelFormat:OSType = kCVPixelFormatType_32ARGB) -> CVPixelBuffer?
//	{
//		// Allocate a new buffer
//		
//		let width = self.width
//		let height = self.height
//		let rowBytes = self.recommendedRowBytes
//		let size = rowBytes * height
//		
//		guard let buffer = malloc(size) else
//		{
//			log.error {"MTLTexture.\(#function) ERROR out of memory"}
//    		return nil
//  		}
//		
//		// Free the buffer again once the CVPixelBuffer is deallocated
//		
//		let releaseCallback:CVPixelBufferReleaseBytesCallback =
//		{
//			_, ptr in
//    		guard let ptr = ptr else { return }
//    		free(UnsafeMutableRawPointer(mutating:ptr))
//		}
//		
//		// Copy pixels from GPU texture to the buffer
//		
//		let region = MTLRegionMake2D(0,0,width,height)
//		self.getBytes(buffer, bytesPerRow:rowBytes, from:region, mipmapLevel:0)
//#warning("TODO: Max: eliminate GPU-CPU-GPU roundtrip - user iosurface instead to make direct conversion")
//
//		// Wrap the buffer in a CVPixelBuffer
//		
//		var pixelbuffer:CVPixelBuffer? = nil
//
//		let err = CVPixelBufferCreateWithBytes(
//			kCFAllocatorDefault,
//			width,
//			height,
//			pixelFormat,
//			buffer,
//			rowBytes,
//			releaseCallback,
//			nil,
//			nil,
//			&pixelbuffer)
//		
//		if err != noErr
//		{
//			log.error {"MTLTexture.\(#function) ERROR \(err) trying to create CVPixelBuffer"}
//		}
//
//		return pixelbuffer
//	}


	/// Copies a Metal texture to a CVPixelBuffer

//	func copy(to pixelBuffer:CVPixelBuffer)
//	{
//		// Check that the texture and the pixelBuffer match in size
//
//		let srcWidth = self.width
//		let srcHeight = self.height
////		let srcRowbytes = self.recommendedRowBytes
//
//		let dstWidth = CVPixelBufferGetWidth(pixelBuffer)
//		let dstHeight = CVPixelBufferGetHeight(pixelBuffer)
//		let dstRowbytes = CVPixelBufferGetBytesPerRow(pixelBuffer)
//
//		guard srcWidth == dstWidth && srcHeight == dstHeight else
//		{
//			log.error {"MTLTexture.\(#function) ERROR srcWidth=\(srcWidth) dstWidth=\(dstWidth) srcHeight=\(srcHeight) dstHeight=\(dstHeight)"}
//			return
//		}
//
//		// Copy pixels from GPU texture to the buffer
//
//		CVPixelBufferLockBaseAddress(pixelBuffer,[])
//		defer { CVPixelBufferUnlockBaseAddress(pixelBuffer,[]) }
//
//		guard let buffer = CVPixelBufferGetBaseAddress(pixelBuffer) else
//		{
//			log.error {"MTLTexture.\(#function) ERROR pixelBuffer.baseAddress = nil"}
//			return
//		}
//
//		let region = MTLRegionMake2D(0,0,srcWidth,srcHeight)
//		self.getBytes(buffer, bytesPerRow:dstRowbytes, from:region, mipmapLevel:0)
//	}
	
	
//----------------------------------------------------------------------------------------------------------------------

	
	/// If the specified texture doesn't match the allowed pixel formats (alpha position), then this function returns a new texture with swizzled channels
	/// so that the byte order matches what is required for use in subsequent processing steps.
	
	@available(macOS 10.15,iOS 13,*) func fixPixelFormatIfNeeded(for srcImage:CGImage, allowedAlphaInfo:[CGImageAlphaInfo] = [.premultipliedLast,.last,.noneSkipLast]) -> MTLTexture
	{
		#if os(macOS)
		
		let alphaInfo = srcImage.bitmapInfo.intersection(.alphaInfoMask)
		let allowedRawValues = allowedAlphaInfo.map { $0.rawValue }

		if !alphaInfo.rawValue.isContained(in:allowedRawValues)
		{
			// Nvidia GPUs crash with the following exception:
			// *** Terminating app due to uncaught exception 'NSInvalidArgumentException', reason: '-[NVMTLTexture newTextureViewWithPixelFormat:textureType:levels:slices:swizzle:]: unrecognized selector sent to instance 0x7fc43d678cc0'
			// That is why we try to guard the call with a responds(to:selector)
			
			let selector = NSSelectorFromString("newTextureViewWithPixelFormat:textureType:levels:slices:swizzle:")

			if self.responds(to:selector)
			{
				let swizzle = MTLTextureSwizzleChannels(red:.green, green:.red, blue:.alpha, alpha:.blue)
				return self.makeTextureView(pixelFormat:.bgra8Unorm, textureType:.type2D, levels:0..<1, slices:0..<1, swizzle:swizzle) ?? self
			}
		}
		
		#endif
		
		return self
	}


	/// Byte-order for video textures is broken on macOS with Intel processors, so swizzle the texture channels in this case. Note that Nvidia GPU crash when trying this, so skip on Nvidia
	
	@available(macOS 10.15, iOS 13, *) func swizzleIfNeeded() -> MTLTexture
	{
		#if os(macOS)
		
		// We have reports of a user using macOS Sequoia 15.3.3 on an Intel MacBook Pro. He reported incorrect colors
		// for video textures, which seems to suggest that swiztling is no longer necessary. Maybe Apple has fixed
		// the problem a while ago (we can't be sure), so starting with 15.0 we will just skip the swizzling.
		// Let's see if any other user will complain, but I guess that there aren't that many user who still work on
		// Intel machines, so this issue might become moot anyway.
		
		if #available(macOS 15,*)
		{
			return self
		}
		
		// On older version of macOS we'll still perform swizzling
		
		if self.usage.contains(.pixelFormatView)
		{
			// Nvidia GPUs crash with the following exception:
			// *** Terminating app due to uncaught exception 'NSInvalidArgumentException', reason: '-[NVMTLTexture newTextureViewWithPixelFormat:textureType:levels:slices:swizzle:]: unrecognized selector sent to instance 0x7fc43d678cc0'
			// That is why we try to guard the call with a responds(to:selector)
			
			let selector = NSSelectorFromString("newTextureViewWithPixelFormat:textureType:levels:slices:swizzle:")

			if self.responds(to:selector)
			{
				let swizzle = MTLTextureSwizzleChannels(red:.green, green:.red, blue:.alpha, alpha:.blue)
				return self.makeTextureView(pixelFormat:.bgra8Unorm, textureType:.type2D, levels:0..<1, slices:0..<1, swizzle:swizzle) ?? self
			}
		}
		
		#endif
		
		return self
	}
}


//----------------------------------------------------------------------------------------------------------------------


public extension MTLDevice
{
	/// Creates a shared MTLTexture from the IOSurface of the supplied CVPixelBuffer.
	///
	/// This texture can be used to render directly to the CVPixelBuffer, without having to copy any bytes.

	func newTexture(with pixelBuffer:CVPixelBuffer, pixelFormat:MTLPixelFormat = .bgra8Unorm, usage:MTLTextureUsage = .renderTarget) -> MTLTexture?
	{
		guard let ioSurface = CVPixelBufferGetIOSurface(pixelBuffer)?.takeUnretainedValue() else { return nil }
		let width = CVPixelBufferGetWidth(pixelBuffer)
		let height = CVPixelBufferGetHeight(pixelBuffer)
		
		let desc = MTLTextureDescriptor()
		desc.pixelFormat = pixelFormat
		desc.width = width
		desc.height = height
		desc.usage = usage
		#if os(macOS)
		desc.storageMode = .managed
		#else
		desc.storageMode = .shared
		#endif
		
		return self.makeTexture(descriptor:desc, iosurface:ioSurface, plane:0)
	}
}


//----------------------------------------------------------------------------------------------------------------------
