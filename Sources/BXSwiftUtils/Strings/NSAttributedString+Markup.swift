//**********************************************************************************************************************
//
//  NSAttributedString+Markup.swift
//  Convenience functions to create attributed strings with custom markup
//  Copyright ©2024 Peter Baumgartner. All rights reserved.
//
//**********************************************************************************************************************


import Foundation

#if os(macOS)
import AppKit
#else
import UIKit
#endif


//----------------------------------------------------------------------------------------------------------------------


extension NSAttributedString
{
	#if os(macOS)

	/// Creates an NSAttributedString with the specified string. It uses the regular system font, but any occurances of "[AI]" will be styled in a special way.
	
	public convenience init(with string:String)
	{
		let regularFont = NSFont.systemFont(ofSize:NSFont.systemFontSize)
		let regularAttrs = [NSAttributedString.Key.font:regularFont]

		let smallFont = NSFont.systemFont(ofSize:9)
		let smallAttrs:[NSAttributedString.Key:Any] = [NSAttributedString.Key.font:smallFont, NSAttributedString.Key.foregroundColor:NSColor.systemYellow, NSAttributedString.Key.baselineOffset:3]
		
		let parts = string.components(separatedBy:"[AI]")
		
		let text = NSMutableAttributedString()
		
		for (i,part) in parts.enumerated()
		{
			text.append(NSMutableAttributedString(string:part, attributes:regularAttrs))
			
			if i < parts.count-1
			{
				let AI = NSLocalizedString("AI", tableName:"NSAttributedString+Markup", bundle:.BXSwiftUtils, comment:"AI abbreviation")
				text.append(NSMutableAttributedString(string:AI, attributes:smallAttrs))
			}
		}
		
		self.init(attributedString:text)
	}

	#else

	#endif
}

	
//----------------------------------------------------------------------------------------------------------------------
