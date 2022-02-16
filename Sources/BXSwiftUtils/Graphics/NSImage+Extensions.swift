//**********************************************************************************************************************
//
//  NSImage+Extensions.swift
//	Adds convenience methods
//  Copyright ©2020 Peter Baumgartner. All rights reserved.
//
//**********************************************************************************************************************


#if os(macOS)

import AppKit
import CoreImage


//----------------------------------------------------------------------------------------------------------------------


public extension NSImage
{
	/// Returns a bitmap CGImage
	
	var CGImage:CGImage?
	{
		self.cgImage(forProposedRect:nil, context:nil, hints:nil)
	}

	/// Returns the icon for the app with the specified bundle identifier
	
	static func icon(for app:String) -> NSImage?
	{
		guard let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier:app) else { return nil }
		return NSWorkspace.shared.icon(forFile:url.path)
	}

	/// Returns a new image with the specified alpha. Can be used to make an image more transparent.
	
	func withAlpha(_ alpha:CGFloat) -> NSImage
	{
		let newImage = NSImage(size:self.size, flipped:false)
		{
			bounds in
			self.draw(in:bounds, from:bounds, operation:.sourceOver, fraction:alpha)
			return true
		}
		
		return newImage
	}
	
	
	/// Creates a new NSImage from a CIImage
	
	convenience init(with image:CIImage)
	{
		let rep = NSCIImageRep(ciImage:image)
        self.init(size:rep.size)
        self.addRepresentation(rep)
	}
	
	
	/// Generates a QR-Code image for the specified URL
	
	static func QRCode(for url:URL?) -> NSImage?
	{
		// Encode the URL
		
		guard let url = url else { return nil }
		let string = url.absoluteString
		let data = string.data(using:.utf8)
		
		// Create a CIImage
		
		guard let filter = CIFilter(name:"CIQRCodeGenerator") else { return nil }
		filter.setValue(data, forKey:"inputMessage")
		
		let transform = CGAffineTransform(scaleX:10, y:10)
		guard let output = filter.outputImage?.transformed(by:transform) else { return nil }
	
		// Convert to NSImage
		
		return NSImage(with:output)
	}
}


//----------------------------------------------------------------------------------------------------------------------

#endif
