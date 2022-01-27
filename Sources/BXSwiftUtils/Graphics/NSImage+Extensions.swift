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
