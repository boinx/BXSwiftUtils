//**********************************************************************************************************************
//
//  URL+Bookmark.swift
//	Creates sandbox-safe bookmarks for saving URLs across app sessions
//  Copyright ©2022 Peter Baumgartner. All rights reserved.
//
//**********************************************************************************************************************


import Foundation


//----------------------------------------------------------------------------------------------------------------------


public extension URL
{
	func bookmarkData() throws -> Data
	{
		try self.bookmarkData(
			options:[.withSecurityScope],
			includingResourceValuesForKeys:nil,
			relativeTo:nil)
	}
	
	init?(with bookmark:Data)
	{
		var isStale = false
		
		do
		{
			try self.init(
				resolvingBookmarkData:bookmark,
				options:[.withSecurityScope],
				relativeTo:nil,
				bookmarkDataIsStale:&isStale)
			
			if isStale { return nil }
		}
		catch
		{
			return nil
		}
	}
}


//----------------------------------------------------------------------------------------------------------------------
