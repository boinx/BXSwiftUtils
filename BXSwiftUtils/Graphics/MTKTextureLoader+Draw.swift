//**********************************************************************************************************************
//
//  MTKTextureLoader+Draw.swift
//	Convenience method for drawing CoreGraphics to a MTLTexture
//  Copyright ©2020 Peter Baumgartner. All rights reserved.
//
//**********************************************************************************************************************


import Metal
import MetalKit
import CoreGraphics
import CoreVideo


//----------------------------------------------------------------------------------------------------------------------


public extension MTKTextureLoader
{
	@available(iOS 10.0, macOS 10.12, *)
	static func draw(to device:MTLDevice, pixelFormat:MTLPixelFormat = .rgba8Unorm, usage:MTLTextureUsage = .shaderRead, size:CGSize, drawHandler:(CGContext)->Void) -> MTLTexture?
	{
		// Create a IOSurface of specified size
		
		let w = Int(size.width)
		let h = Int(size.height)
		let align = 256
		let rowBytes = (w * 4 + align - 1) & ~(align - 1)

		let surfaceProperties: [IOSurfacePropertyKey:Any] =
		[
			.width: w,
			.height: h,
			.bytesPerElement: 4,
			.bytesPerRow: rowBytes,
			.pixelFormat: kCVPixelFormatType_32RGBA,
		]
		
		guard let surface = IOSurface(properties:surfaceProperties) else { return nil }
		
		// Lock the IOSurface
		
		let result1 = surface.lock(options:[], seed:nil)
		assert(result1 == KERN_SUCCESS)
		
		// Create a bitmap CGContext for the IOSurface
		
		guard let colorspace = CGColorSpace(name:CGColorSpace.sRGB) else { return nil }

		guard let context = CGContext(
			data:surface.baseAddress,
			width:w,
			height:h,
			bitsPerComponent:8,
			bytesPerRow:rowBytes,
			space:colorspace,
			bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else { return nil }
		
		// Draw to the bitmap context. This will happen on the CPU, but the memory is shared with the GPU via
		// the IOSurface.
		
		drawHandler(context)
		
		// Unlock the IOSurface again
		
		let result2 = surface.unlock(options:[], seed:nil)
		assert(result2 == KERN_SUCCESS)

		// Wrap the IOSurface in a MTLTexture. This does not cause the contents to be copied, they are referenced
		// directly. When you encode GPU accesses for this MTLTexture, that will cause the IOSurface to be locked
		// by the GPU for the duration of rendering. Thus, the contents encoded by the CPU are synchronized
		// automatically to the GPU.
		
		let textureDescriptor = MTLTextureDescriptor.texture2DDescriptor(
			pixelFormat:pixelFormat,
			width:w,
			height:h,
			mipmapped:false)
			
		textureDescriptor.usage = usage
		
		let texture = device.makeTexture(
			descriptor:textureDescriptor,
			iosurface:unsafeBitCast(surface,to:IOSurfaceRef.self),
			plane:0)
			
		return texture
	}
}
		

//----------------------------------------------------------------------------------------------------------------------


// Sample code from the WWDC 2020 lab appointment:

/*

	func shapeLayerContentsAsTexture(shapeLayer: CAShapeLayer, device: MTLDevice, usage: MTLTextureUsage = .shaderRead) -> MTLTexture
	{
		// Create an IOSurface to hold the results of the drawing
		let width = Int(shapeLayer.bounds.width)
		let height = Int(shapeLayer.bounds.height)
		let align = 256
		let rowStride = (width * 4 + align - 1) & ~(align - 1)
		let surfaceProperties: [IOSurfacePropertyKey: Any] = [
			.width: width,
			.height: height,
			.bytesPerElement: 4,
			.bytesPerRow: rowStride,
			.pixelFormat: kCVPixelFormatType_32RGBA,
		]
		let surface = IOSurface(properties: surfaceProperties)!

		// Draw the CAShapeLayer on the CPU
		// Note that we use CGContext, and we pass in the components of the shape layer
		// It would be better to not create the CAShapeLayer at all (or use a different container for this data)
		// While drawing, the IOSurface must be locked by the CPU
		let lockResult = surface.lock(options: [], seed: nil)
		assert(lockResult == KERN_SUCCESS)
		if let cpuContext = CGContext(data: surface.baseAddress, width: width, height: height, bitsPerComponent: 8, bytesPerRow: rowStride, space: CGColorSpace(name: CGColorSpace.sRGB)!, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) {
			cpuContext.setFillColor(shapeLayer.fillColor!)
			cpuContext.setStrokeColor(shapeLayer.strokeColor!)
			cpuContext.setLineWidth(shapeLayer.lineWidth)
			cpuContext.beginPath()
			cpuContext.addPath(shapeLayer.path!)
			cpuContext.drawPath(using: .eoFillStroke)
		}
		let unlockResult = surface.unlock(options: [], seed: nil)
		assert(unlockResult == KERN_SUCCESS)

		// Wrap the IOSurface in a MTLTexture
		// This does not cause the contents to be copied, they are referenced directly.
		// When you encode GPU accesses for this MTLTexture, that will cause the IOSurface to be locked by the GPU for the duration of rendering.
		// Thus, the contents encoded by the CPU are synchronized automatically to the GPU.
		let textureDescriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .rgba8Unorm_srgb,
																		 width: width,
																		 height: height,
																		 mipmapped: false)
		textureDescriptor.usage = usage
		let texture = device.makeTexture(descriptor: textureDescriptor, iosurface: unsafeBitCast(surface, to: IOSurfaceRef.self), plane: 0)!
		return texture
	}

*/


//----------------------------------------------------------------------------------------------------------------------
