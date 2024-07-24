//**********************************************************************************************************************
//
//  CGImage+FileIO.swift
//	Adds convenience methods
//  Copyright ©2022-2024 Peter Baumgartner. All rights reserved.
//
//**********************************************************************************************************************


import AVFoundation

#if canImport(AppKit)
import AppKit
#endif

#if canImport(UIKit)
import UIKit
#endif

#if canImport(CoreGraphics)
import CoreGraphics
#endif


//----------------------------------------------------------------------------------------------------------------------


public extension CGImage
{
	/// Creates a CGImage from the specified image file.
	/// - parameter url: The url of the image file
	/// - returns: A CGImage
	
	class func load(from url:URL) -> CGImage?
	{
		guard let uti = url.uti else { return nil }
		
		if UTTypeConformsTo(uti as CFString,kUTTypePDF)
		{
			return loadPDF(from:url)
		}

		return loadImage(from:url)
	}


	class func loadImage(from url:URL) -> CGImage?
	{
		if let source = CGImageSourceCreateWithURL(url as CFURL,nil)
		{
			let (_,index) = CGImage.biggestSize(for:source)
		
			if let image = CGImageSourceCreateImageAtIndex(source,index,nil)
			{
				return image
			}
		}

		return nil
	}


	class func loadPDF(from url:URL) -> CGImage?
	{
		// Load the first page of the PDF
		
		guard let document = CGPDFDocument(url as CFURL) else { return nil }
		guard let page = document.page(at:1) else { return nil }

		// Get its size in points. Multiply by scale to get higher than 72dpi resolution
		
		let bounds = page.getBoxRect(.mediaBox)
		let scale:CGFloat = 4.0
		let width = Int(ceil(bounds.width * scale))
		let height = Int(ceil(bounds.height * scale))
		let format = CGBitmapInfo.byteOrder32Little.rawValue | CGImageAlphaInfo.premultipliedFirst.rawValue
		
		// Create a bitmap context
		
		guard let sRGB = CGColorSpace(name:CGColorSpace.sRGB) else { return nil }
		guard let bitmap = CGContext(data:nil,width:width,height:height,bitsPerComponent:8,bytesPerRow:width*4,space:sRGB,bitmapInfo:format) else { return  nil }

		// Render PDF into this context
		
		bitmap.setShouldAntialias(true)
		bitmap.setAllowsAntialiasing(true)
		bitmap.scaleBy(x:scale,y:scale)
		bitmap.drawPDFPage(page)

		// Extract image from bitmap context
		
		return bitmap.makeImage()
	}


//----------------------------------------------------------------------------------------------------------------------


	/// Loads a CGImage frame from a video file asset at the specified time. This method first tries to load the image
	/// at exactly the specified time. If that fails, it tries again with less precision and retrieve the closest
	/// available frame.
	/// - parameter asset: The asset for the video file
	/// - parameter time: The the timestamp in seconds
	/// - returns: A CGImage
	
	class func load(from asset:AVAsset?, at time:Double, appliesPreferredTrackTransform:Bool = true) -> CGImage?
	{
		guard let asset = asset else { return nil }
		let track = asset.tracks(withMediaType:.video).first
		let timescale = track?.naturalTimeScale ?? 600

		// First try exact time
		
		let generator = AVAssetImageGenerator(asset:asset)
		generator.appliesPreferredTrackTransform = appliesPreferredTrackTransform
		generator.requestedTimeToleranceBefore = CMTime.zero
		generator.requestedTimeToleranceAfter = CMTime.zero

		let t = CMTimeMakeWithSeconds(time,preferredTimescale:timescale)
		var image = try? generator.copyCGImage(at:t,actualTime:nil)

		// As fallback try closest available time
		
		if image == nil
		{
			generator.requestedTimeToleranceBefore = CMTime.positiveInfinity
			generator.requestedTimeToleranceAfter = CMTime.positiveInfinity
			image = try? generator.copyCGImage(at:t,actualTime:nil)
		}
		
		return image
	}
	

//----------------------------------------------------------------------------------------------------------------------


	/// Returns an opaque data buffer that can be written to a file or an archive.
	
	func data(type:CFString=kUTTypeJPEG, quality:Double=0.5) -> Data
	{
		let data = NSMutableData()
		
		if let dst = CGImageDestinationCreateWithData(data,type,1,nil)
		{
			let properties = [ kCGImageDestinationLossyCompressionQuality as String : quality ]
			CGImageDestinationAddImage(dst,self,properties as CFDictionary)
			CGImageDestinationFinalize(dst)
		}
		
		return data as Data
	}


	/// Saves the image to a file of specified type and quality.
	
	@discardableResult func save(to url:URL, type:CFString=kUTTypeJPEG, quality:Double=0.8) -> Bool
	{
		var success = false
		
		if let dst = CGImageDestinationCreateWithURL(url as CFURL,type,1,nil)
		{
			let properties = [ kCGImageDestinationLossyCompressionQuality as String : quality ]
			CGImageDestinationAddImage(dst,self,properties as CFDictionary)
			success = CGImageDestinationFinalize(dst)
		}
		
		return success
	}


	
//----------------------------------------------------------------------------------------------------------------------


	/// Returns the CGImage with the specified name from the Resources of a particular Bundle
	
	static func image(named name:String, in bundle:Bundle?) -> CGImage?
	{
		#if os(macOS)
		
		let bundle = bundle ?? Bundle.main
		return bundle.image(forResource:name)?.CGImage
		
		#else
		
		UIImage(named:name, in:bundle, compatibleWith:nil)?.cgImage
		
		#endif
	}
}


//----------------------------------------------------------------------------------------------------------------------
