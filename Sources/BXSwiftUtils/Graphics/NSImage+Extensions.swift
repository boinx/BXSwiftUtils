//**********************************************************************************************************************
//
//  NSImage+Extensions.swift
//	Adds convenience methods
//  Copyright ©2020 Peter Baumgartner. All rights reserved.
//
//**********************************************************************************************************************


#if os(macOS)

import AppKit


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
	
}


//----------------------------------------------------------------------------------------------------------------------

#endif
