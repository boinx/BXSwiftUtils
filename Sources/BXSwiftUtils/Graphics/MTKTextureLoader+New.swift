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
	
	public static func newTexture(image:CGImage, device:MTLDevice, allowSRGB:Bool = false, textureUsage:MTLTextureUsage = .shaderRead, storageMode:MTLStorageMode = .private, mipmap:Bool = false, blur:Double = 0.0) throws -> MTLTexture
	{
		let options:[MTKTextureLoader.Option:NSObject] = self.createOptions(
			allowSRGB:allowSRGB,
			textureUsage:textureUsage,
			storageMode:storageMode,
			mipmap:mipmap)

		let loader = MTKTextureLoader(device:device)
		let texture = try loader.newTexture(cgImage:image,options:options)
		
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
//            options[MTKTextureLoader.Option.generateMipmaps] = true as NSNumber
        }
		
		return options
	}
}



//----------------------------------------------------------------------------------------------------------------------
