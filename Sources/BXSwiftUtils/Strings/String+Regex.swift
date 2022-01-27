//**********************************************************************************************************************
//
//  String+Regex.swift
//	Simple regex functions
//  Copyright ©2018 Peter Baumgartner. All rights reserved.
//
//**********************************************************************************************************************


import Foundation


//----------------------------------------------------------------------------------------------------------------------


// MARK: -

public extension String
{

	/// Returns any matches for the supplied regex pattern
	/// - parameter pattern: A valid regex pattern
	/// - parameter options: The options inluence the behavior of the NSRegularExpression
	/// - returns: An array of strings matching the regex pattern
	
	func regexMatches(for pattern: String, options: NSRegularExpression.Options = []) -> [String]
	{
 		if let regex = try? NSRegularExpression(pattern:pattern, options:options)
        {
            let string = self as NSString
			let range = NSRange(location:0, length:string.length)
			
            return regex.matches(in:self, options:[], range:range).map
            {
                string.substring(with: $0.range)
            }
        }

        return []
	}
	
	
	/// Returns true if a string has at least one match for the supplied regex pattern
	
	static func ~= (_ string: String, _ pattern: String) -> Bool
	{
		return !string.regexMatches(for:pattern).isEmpty
	}
	
	
	/// Returns a version of the string that has all HTML tags stripped away
	
	func strippingHTMLTags() -> String
	{
		self.replacingOccurrences(of:"<[^>]+>", with:"", options:.regularExpression, range:nil)
	}
	
}


//----------------------------------------------------------------------------------------------------------------------
