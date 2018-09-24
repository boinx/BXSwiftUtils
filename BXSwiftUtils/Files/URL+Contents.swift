//**********************************************************************************************************************
//
//  URL+Contents.swift
//	Adds convenience methods to URL
//  Copyright ©2016-2018 Peter Baumgartner. All rights reserved.
//
//**********************************************************************************************************************


import Foundation


//----------------------------------------------------------------------------------------------------------------------


// MARK: -

public extension URL
{
	/// Performs a shallow scan of the directory pointed to by a folder URL and returns the resulting child URLs.
	/// - returns: An array of URLs for all direct children
	
	public func shallowContentsOfDirectory() throws -> [URL]
	{
		let paths = try FileManager.default.contentsOfDirectory(atPath:self.path)
		let urls:[URL] = paths.map { self.appendingPathComponent($0) }
		return urls
	}
	
}


//----------------------------------------------------------------------------------------------------------------------
