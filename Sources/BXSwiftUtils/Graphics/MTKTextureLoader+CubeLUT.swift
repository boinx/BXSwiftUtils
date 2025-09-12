//**********************************************************************************************************************
//
//  MTKTextureLoader+CubeLUT.swift
//	Load .cube files into a 3D MTLtexture
//  Copyright ©2025 Peter Baumgartner. All rights reserved.
//
//**********************************************************************************************************************


import Metal
import MetalKit


//----------------------------------------------------------------------------------------------------------------------


@available(iOS 10.0, macOS 10.12, *)


extension MTKTextureLoader
{
	public enum LUTError : Swift.Error
	{
		case fileNotFound
		case parseError(String)
		case unsupportedFormat
		case memoryError
	}

	public struct CubeLUT
	{
		let size:Int
		
		// RGB entries in file order (R fastest, then G, then B), length = size*size*size*3
		
		let floats:[Float]
	}
	
	
	/// Loads a .cube file into a CubeLUT struct
	
	public static func loadCubeLUT(url:URL) throws -> CubeLUT
	{
		var size:Int?
		var data:[Float] = []
			
		// Load the cube file, which is essentially just a text file and break it into lines
		
		let raw = try String(contentsOf:url, encoding:.utf8)
		let lines = raw.components(separatedBy:CharacterSet.newlines)

		// Go through the text files line by line, skipping all empty lines or comments
		
		for line in lines
		{
			let trimmed = line.trimmingCharacters(in:.whitespacesAndNewlines)
			if trimmed.isEmpty { continue }
			if trimmed.hasPrefix("#") { continue }
			
			// Break a line into components, separated by whitespace
			
			let parts = trimmed
				.components(separatedBy:CharacterSet.whitespaces)
				.filter { !$0.isEmpty }
				
			if parts.count == 0 { continue }
			
			// Find and parse LUT_3D_SIZE
			
			let first = parts[0].uppercased()
			if first == "LUT_3D_SIZE"
			{
				if parts.count >= 2, let n = Int(parts[1])
				{
					size = n
				}
				else
				{
					throw LUTError.parseError("Invalid LUT_3D_SIZE line")
				}
				
				continue
			}
			
			// Find and parse DOMAIN_MIN and DOMAIN_MAX
			
			if first == "DOMAIN_MIN" || first == "DOMAIN_MAX"
			{
				// Ignored for now; assuming 0..1 domain. If nonstandard domain is used, rescale entries.
				continue
			}
			
			// If line looks like three floats, parse as data
			
			if parts.count >= 3, let r = Float(parts[0]), let g = Float(parts[1]), let b = Float(parts[2])
			{
				data.append(contentsOf:[r,g,b])
			}
		}

		// Confirm that we did get LUT_3D_SIZE
		
		guard let n = size else
		{
			throw LUTError.parseError("Missing LUT_3D_SIZE in .cube")
		}

		// Check that the array has the correct number of entries
		
		let expected = n * n * n * 3
		
		if data.count != expected
		{
			throw LUTError.parseError("Expected \(expected) float components but found \(data.count). File order may be unusual or file contains extra data.")
		}
		
		// Wrap it in a CubeLUT struct
		
		return CubeLUT(size:n, floats:data)
	}


	/// Create a 3D MTLTexture from the parsed CubeLUT.
	/// Uses rgba32Float for simplicity and correctness (can be swapped to rgba16Float for memory).
	
	public static func newCubeLUT(device:MTLDevice, url:URL) throws -> MTLTexture
	{
		let cubeLUT = try Self.loadCubeLUT(url:url)
		let texture = try Self.newCubeLUT(device:device, cube:cubeLUT)
		return texture
	}
	
	
	/// Create a 3D MTLTexture from the parsed CubeLUT.
	/// Uses rgba32Float for simplicity and correctness (can be swapped to rgba16Float for memory).
	
	public static func newCubeLUT(device:MTLDevice, cube:CubeLUT) throws -> MTLTexture
	{
		let size = cube.size
		let pixelCount = size * size * size
		let floatsPerPixel = 4 // r,g,b,a

		// Allocate a flat array of RGBA values for the whole cube

		var texelData = [Float](repeating:0, count:pixelCount*floatsPerPixel)

		// .cube file convention: entries are ordered with R fastest, then G, then B:
		// for b in 0..<N { for g in 0..<N { for r in 0..<N { write r g b } } }
		// The data array is consequently in that same order. We'll keep that same ordering when filling the 3D texture memory.

		let src = cube.floats
		var srcOffset = 0
		
		for b in 0..<size
		{
			for g in 0..<size
			{
				for r in 0..<size
				{
					let dstIndex = (b * size * size + g * size + r) * floatsPerPixel
					texelData[dstIndex+0] = src[srcOffset+0]	// R
					texelData[dstIndex+1] = src[srcOffset+1]	// G
					texelData[dstIndex+2] = src[srcOffset+2]	// B
					texelData[dstIndex+3] = 1.0            		// A
					srcOffset += 3
				}
			}
		}

		// Create 3D texture descriptor (width=height=depth=size).
		
		let descriptor = MTLTextureDescriptor.textureCubeDescriptor(pixelFormat:MTLPixelFormat.rgba32Float, size:size, mipmapped:false)
		descriptor.usage = [.shaderRead]
		
		// Allocate texture memory
		
		guard let texture = device.makeTexture(descriptor:descriptor) else
		{
			throw LUTError.unsupportedFormat
		}

		// Calculate the size of a single plane in the cube. Memory layout rules for a 3D texture upload:
		// - bytesPerPixel = sizeof(Float) * 4
		// - bytesPerRow   = bytesPerPixel * width
		// - bytesPerImage = bytesPerRow   * height
		// With these strides, texelData is laid out as [depth][row][column].
		
		let bytesPerPixel = floatsPerPixel * MemoryLayout<Float>.size  // 4 * 4 = 16 bytes
		let bytesPerRow = bytesPerPixel * size
		let bytesPerImage = bytesPerRow * size

		// Upload the cube data
		
		try texelData.withUnsafeBytes
		{
			bufferPtr in
			guard let base = bufferPtr.baseAddress else { throw LUTError.memoryError }
			
			// Define a 3D region that spans the entire cube:
			// origin.z = 0, depth = size → updates all slices from z=0 to z=size-1
			
			let region = MTLRegion(
				origin: MTLOrigin(x:0, y:0, z:0),
				size: MTLSize(width:size, height:size, depth:size))
			
			// Upload the whole array with the 3D region
			
			texture.replace(
				region:region,
				mipmapLevel:0,
				slice:0,
				withBytes:base,
				bytesPerRow:bytesPerRow,
				bytesPerImage:bytesPerImage)
		}

		return texture
	}
}


//----------------------------------------------------------------------------------------------------------------------
