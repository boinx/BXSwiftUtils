//**********************************************************************************************************************
//
//  CGImage+Metadata.swift
//	Adds convenience methods
//  Copyright ©2022-2024 Peter Baumgartner. All rights reserved.
//
//**********************************************************************************************************************


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
	/// Returns the size of this CGImage
	
	var size:CGSize
	{
		let w = self.width
		let h = self.height
		return CGSize(w,h)
	}


	/// Returns the size and the index of the image at the specified URL. Since an image file may contain multiple
	/// representations of an image at different resolutions, only the biggest size (and its index) will be returned.
	/// - parameter url: The url of the image file
	/// - returns: A tuple containing the biggest image size and the zero-based index of that image representation
	
	class func biggestSize(for url:URL) -> (CGSize,Int)
	{
		guard let source = CGImageSourceCreateWithURL(url as CFURL,nil)
		else { return (CGSize.zero,-1) }
		
		return self.biggestSize(for:source)
	}


	/// Returns the size and the index of the image at the specified CGImageSource. Since an image file may contain
	/// multiple representations of an image at different resolutions, only the biggest size (and its index) will be returned.
	/// - parameter source: The CGImageSource for an image file
	/// - returns: A tuple containing the biggest image size and the zero-based index of that image representation
	
	class func biggestSize(for source:CGImageSource) -> (CGSize,Int)
	{
		var size = CGSize.zero
		var maxSize = CGSize.zero
		var index = 0
		
		let n = CGImageSourceGetCount(source)

		for i in 0..<n
		{
			guard let properties = CGImageSourceCopyPropertiesAtIndex(source,0,nil)
			else { return (size,-1) }
		
			let dict = properties as Dictionary
			
			if let w = dict[kCGImagePropertyPixelWidth]
			{
				size.width = CGFloat(w.doubleValue)
			}
			
			if let h = dict[kCGImagePropertyPixelHeight]
			{
				size.height = CGFloat(h.doubleValue)
			}

			if size.width > maxSize.width
			{
				maxSize = size
				index = i
			}
		}

		return (maxSize,index)
	}


	/// Returns the size of the image at its correct orientation
	
	class func rotatedSize(for url:URL) -> CGSize?
	{
		guard let source = CGImageSourceCreateWithURL(url as CFURL,nil) else { return nil }
		guard let properties = CGImageSourceCopyPropertiesAtIndex(source,0,nil) else { return nil }

		var size = CGSize.zero
		let dict = properties as Dictionary
		
		if let w = dict[kCGImagePropertyPixelWidth]
		{
			size.width = CGFloat(w.doubleValue)
		}
		
		if let h = dict[kCGImagePropertyPixelHeight]
		{
			size.height = CGFloat(h.doubleValue)
		}
		
		if let o = dict[kCGImagePropertyOrientation] as? Int, o > 4
		{
			let w = size.width
			let h = size.height
			size.width = h
			size.height = w
		}
		
		return size
	}
	

	/// Returns the image size for a PDF file.
	/// - parameter url: The URL of the PDF file
	/// - parameter pageIndex: The index of the page. The index starts counting at 1
	/// - parameter scaleFactor: Returned size is relative to rendering at 72dpi. If you require a higher resolution, then supply a scaleFactor > 1.0
	/// - returns: The image size in pixels. Note that the size is multiplied by the scaleFactor!

	static func sizeForPDF(at url:URL, pageIndex:Int=1, scaleFactor:CGFloat=3.0) -> CGSize
	{
		guard let document = CGPDFDocument(url as CFURL) else { return .zero }
		guard let page = document.page(at:pageIndex) else { return .zero }
		
		var bounds = page.getBoxRect(.mediaBox)
		bounds.size.width *= scaleFactor
		bounds.size.height *= scaleFactor
		
		return bounds.size
	}


	class func PDFBounds(for url:URL) -> CGRect
	{
		// Load the first page of the PDF
		
		guard let document = CGPDFDocument(url as CFURL) else { return .zero }
		guard let page = document.page(at:1) else { return .zero }

		// Get its size in points. Multiply by scale to get higher than 72dpi resolution
		
		let scale:CGFloat = 4.0
		var bounds = page.getBoxRect(.mediaBox)
		bounds.size.width *= scale
		bounds.size.height *= scale
		return bounds
	}


//----------------------------------------------------------------------------------------------------------------------


	/// Returns the aspect ratio of the image file at the specified URL
	
	class func aspectRatio(for url:URL) -> CGFloat
	{
		guard let size = Self.rotatedSize(for:url) else { return 1.0 }
		return size.width / size.height
	}
	
	
	/// Returns the orientation of the image file at the specified URL
	
	static func orientation(for url:URL) -> CGImagePropertyOrientation
	{
		guard let source = CGImageSourceCreateWithURL(url as CFURL,nil) else { return .up }
		guard let info = unsafeBitCast(CGImageSourceCopyPropertiesAtIndex(source,0,nil),to:CFDictionary.self) as? [CFString:Any] else { return .up }
		guard let number = info[kCGImagePropertyOrientation] as? NSNumber else { return .up }
		let value = number.intValue
		return CGImagePropertyOrientation(rawValue:UInt32(value)) ?? .up
	}
	
	
//----------------------------------------------------------------------------------------------------------------------


	/// Returns true if this image uses a colorspace with extended dynamic range
	
	var hasEDR:Bool
	{
		self.colorSpace?.isEDR ?? false
	}
	
	/// Returns true if this image has an alpha channel
	
	var hasAlpha:Bool
	{
		let info = self.alphaInfo
		let hasAlpha = info == .alphaOnly || info == .first || info == .last || info == .premultipliedFirst || info == .premultipliedLast
		return hasAlpha
	}
	
	/// Returns true if  the image file at the specified URL has an alpha channel
	
	class func hasAlphaChannel(for url:URL) -> Bool
	{
		guard let source = CGImageSourceCreateWithURL(url as CFURL,nil) else { return false }
		let index = CGImageSourceGetPrimaryImageIndex(source)
		guard let properties = CGImageSourceCopyPropertiesAtIndex(source,index,nil) as? [CFString:Any] else { return false }
		let hasAlpha = properties["HasAlpha" as CFString] as? Bool ?? false
		
		return hasAlpha
	}
	
	/// Returns true if the alphaInfo of this CGImage is one of the specified allowed pixel formats
	
	func hasAllowedAlphaInfo(_ allowedAlphaInfos:[CGImageAlphaInfo] = [.premultipliedLast,.last,.noneSkipLast]) -> Bool
	{
		let allowedRawValues = allowedAlphaInfos.map { $0.rawValue }
		let alphaInfo = self.bitmapInfo.intersection(.alphaInfoMask)
		return alphaInfo.rawValue.isContained(in:allowedRawValues)
	}


	/// Returns the metadata for the specified image file.
	/// - parameter url: The url of the image file
	/// - returns: A dictionary of type [String:Any]
	
	class func metadata(for url:URL) -> [String:Any]
	{
		if url.exists
		{
			if let source = CGImageSourceCreateWithURL(url as CFURL,nil)
			{
				let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil)
				
				if let dict = properties as? [String:Any]
				{
					return dict
				}
			}
		}
		
		return [:]
	}

}


//----------------------------------------------------------------------------------------------------------------------
