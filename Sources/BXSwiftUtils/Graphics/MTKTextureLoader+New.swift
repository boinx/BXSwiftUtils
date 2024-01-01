//**********************************************************************************************************************
//
//  MTKTextureLoader+New.swift
//	Adds convenience methods
//  Copyright ©2018-2023 Peter Baumgartner. All rights reserved.
//
//**********************************************************************************************************************


import Metal
import MetalKit
import CoreGraphics
import MetalPerformanceShaders


//----------------------------------------------------------------------------------------------------------------------


@available(iOS 10.0, macOS 10.12, *)


extension MTKTextureLoader
{
	/// Loads a texture from an image file at the specified url
	
	public static func newTexture(url:URL, device:MTLDevice, allowSRGB:Bool = false, textureUsage:MTLTextureUsage = .shaderRead, storageMode:MTLStorageMode = .private, mipmap:Bool = false) throws -> MTLTexture
	{
		let options:[MTKTextureLoader.Option:NSObject] = self.createOptions(
			allowSRGB:allowSRGB,
			textureUsage:textureUsage,
			storageMode:storageMode,
			mipmap:mipmap)

		let loader = MTKTextureLoader(device:device)
		let texture = try loader.newTexture(URL:url,options:options)
		texture.label = url.lastPathComponent
		return texture
	}


	/// Loads a texture from an image
	
	public static func newTexture(image:CGImage, device:MTLDevice, allowSRGB:Bool = false, textureUsage:MTLTextureUsage = .shaderRead, storageMode:MTLStorageMode = .private, mipmap:Bool = false, highQuality:Bool = false, debug:Bool = false) throws -> MTLTexture
	{
		let options:[MTKTextureLoader.Option:NSObject] = self.createOptions(
			allowSRGB:allowSRGB,
			textureUsage:textureUsage,
			storageMode:storageMode,
			mipmap:mipmap)

		let loader = MTKTextureLoader(device:device)
		var texture = try loader.newTexture(cgImage:image,options:options)
		
		if debug
		{
			Self.setMipMapDebugColors(texture:texture)
		}
		else if highQuality
		{
			Self.createHighQualityMipmap(texture:&texture, device:device)
		}
		
		return texture
	}


	/// Creates an options dictionary depending on the supplied arguments
	
	private static func createOptions(allowSRGB:Bool, textureUsage:MTLTextureUsage, storageMode:MTLStorageMode, mipmap:Bool) -> [MTKTextureLoader.Option:NSObject]
	{
		var options:[MTKTextureLoader.Option:NSObject] = [:]

        options[MTKTextureLoader.Option.SRGB] = allowSRGB as NSNumber
        options[MTKTextureLoader.Option.textureUsage] = textureUsage.rawValue as NSNumber
        options[MTKTextureLoader.Option.textureStorageMode] = storageMode.rawValue as NSNumber

        if mipmap
        {
            options[MTKTextureLoader.Option.allocateMipmaps] = true as NSNumber
            options[MTKTextureLoader.Option.generateMipmaps] = true as NSNumber
        }
		
		return options
	}
	
	
	/// Fills a mipmap texture with different colors in each level, so that shadert code can be visually debugged.
	
	public static func setMipMapDebugColors(texture:MTLTexture)
	{
		let W = texture.width
		let H = texture.height
		let n = texture.mipmapLevelCount
		
		let colors:[[UInt8]] =
		[
			[255,0,0,255],
			[0,255,0,255],
			[0,0,255,255],
			[255,0,255,255],
			[255,255,0,255],
			[0,255,255,255],
			[255,255,255,255],
		]

		for level in 1...n
		{
			let w = W >> level
			let h = H >> level
			let rowBytes = w * 4
			let count = h * rowBytes
			guard count >= 4 else { continue }
			var buffer = [UInt8](repeating:0, count:count)
			let j = (level-1) % colors.count
			
print("level=\(level) color \(j) = \(colors[j])")

			for i in 0 ..< count/4
			{
				buffer[i*4+0] = colors[j][0]
				buffer[i*4+1] = colors[j][1]
				buffer[i*4+2] = colors[j][2]
				buffer[i*4+3] = colors[j][3]
			}
			
			let region = MTLRegionMake2D(0,0,w,h)
			texture.replace(region:region, mipmapLevel:level, withBytes:&buffer, bytesPerRow:rowBytes)
		}
	}
	
	
	/// Fills a mipmap texture with different colors in each level, so that shadert code can be visually debugged.
	
	public static func createHighQualityMipmap(texture:inout MTLTexture, device:MTLDevice)
	{
		guard let commandQueue = device.makeCommandQueue() else { return }
		guard let commandBuffer = commandQueue.makeCommandBuffer() else { return }
		
		// Do a minimal blur on level 0 to reduce the highest image frequencies
		
		let blur = MPSImageGaussianBlur(device:device, sigma:0.9)
		blur.edgeMode = .clamp
		blur.encode(commandBuffer:commandBuffer, inPlaceTexture:&texture)

		// Create the mipmap levels 1 and lower with high quality gaussian interpolation
		
		if texture.mipmapLevelCount > 1
		{
			let gaussianPyramid = MPSImageGaussianPyramid(device:device)
			gaussianPyramid.encode(commandBuffer:commandBuffer, inPlaceTexture:&texture, fallbackCopyAllocator:nil)
		}
		
		// Wait until done
		
		commandBuffer.commit()
		commandBuffer.waitUntilCompleted()
	}
	

}



//----------------------------------------------------------------------------------------------------------------------
