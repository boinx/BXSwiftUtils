//**********************************************************************************************************************
//
//  String+Path.swift
//	Convenience function that make for more readable code at call site
//  Copyright ©2018 Peter Baumgartner. All rights reserved.
//
//**********************************************************************************************************************


import Foundation


//----------------------------------------------------------------------------------------------------------------------


// MARK: -

public extension String
{
	/// Returns the file or folder name of a path

	public var lastPathComponent : String
	{
 		return (self as NSString).lastPathComponent
	}
	
	/// Returns the extension of a path
	
	public var pathExtension : String
	{
 		return (self as NSString).pathExtension
	}
	
	/// Returns the parent of a path
	
	public var deletingLastPathComponent : String
	{
 		return (self as NSString).deletingLastPathComponent
	}

	/// Returns the parent of a path
	
	public func appendingPathComponent(_ str:String) -> String
	{
 		return (self as NSString).appendingPathComponent(str)
	}
	
	/// Returns the relative part of a path, given a basePath
	
	public func relativePath(to inBasePath:String) -> String?
	{
		var basePath = inBasePath
		if !basePath.hasSuffix("/") { basePath += "/" }

		if self.hasPrefix(basePath)
		{
			let subPath = self.replacingOccurrences(of:basePath, with:"")
			return subPath
		}
		
		return nil
	}

}


//----------------------------------------------------------------------------------------------------------------------
