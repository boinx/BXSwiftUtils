//**********************************************************************************************************************
//
//  URL+Bookmark.swift
//	Creates sandbox-safe bookmarks for saving URLs across app sessions
//  Copyright ©2022 Peter Baumgartner. All rights reserved.
//
//**********************************************************************************************************************


import Foundation


//----------------------------------------------------------------------------------------------------------------------


public extension NSURL
{
	/// Tries to convert this file URL to a file reference URL, i.e. one that survives moving and renaming
	
	var fileReferenceURL : NSURL
	{
		guard self.isFileURL else { return self }
		guard let fileReference = self.fileReferenceURL() as NSURL? else { return self } // The typecast fixes a bug described at https://christiantietze.de/posts/2018/09/nsurl-filereferenceurl-swift/
		return fileReference
	}
	
	/// Returns true if this is a file reference URL
	
	var isFileReferenceURL:Bool
	{
		self.isFileReferenceURL()
	}

	/// Return true if the file exists
	
	var exists: Bool
	{
		if self.isFileURL, let path = self.path
		{
			return FileManager.default.fileExists(atPath:path)
		}
		
		return false
	}

	/// Converts to a Swift URL (struct)
	
	var swiftURL : URL
	{
		self as URL
	}
}


//----------------------------------------------------------------------------------------------------------------------
