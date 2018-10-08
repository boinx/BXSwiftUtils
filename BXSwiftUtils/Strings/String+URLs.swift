//**********************************************************************************************************************
//
//  String+URLs.swift
//	Parses text for any URLs it contains
//  Copyright ©2018 Peter Baumgartner. All rights reserved.
//
//**********************************************************************************************************************


import Foundation


//----------------------------------------------------------------------------------------------------------------------


// MARK: -

public extension String
{
	/// Parses the text and returns an array of all URLs contained in this string
	/// - returns: An array of URLs
	
	public var URLs : [URL]
	{
		var urls:[URL] = []
		
		let types: NSTextCheckingResult.CheckingType = .link

		if let detector = try? NSDataDetector(types:types.rawValue)
		{
			let range = NSMakeRange(0,self.count)
			let matches = detector.matches(in:self, options:.reportCompletion, range:range)
			urls = matches.compactMap { $0.url }
		}
		
		return urls
	}
	
}


//----------------------------------------------------------------------------------------------------------------------
