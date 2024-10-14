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


//----------------------------------------------------------------------------------------------------------------------


	/// Creates a MTLTexture from bitmap data with the specified parameters. This call lets you choose the MTLPixelFormat, which the regular MTKTextureLoader
	/// function won't let you do. That way you can create 16bit textures.
	
	public static func newTexture(device:MTLDevice, bitmapData:Data, width:Int, height:Int, rowBytes:Int, pixelFormat:MTLPixelFormat, textureUsage:MTLTextureUsage, storageMode:MTLStorageMode, mipmapped:Bool) -> MTLTexture?
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
	
}



//----------------------------------------------------------------------------------------------------------------------
