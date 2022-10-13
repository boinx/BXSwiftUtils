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
		#if os(macOS)
	
		return try self.bookmarkData(
			options:[.withSecurityScope],
			includingResourceValuesForKeys:nil,
			relativeTo:nil)
		
		#else
		
		try self.bookmarkData(
			options:[],
			includingResourceValuesForKeys:nil,
			relativeTo:nil)
		
		#endif
	}
	
	init?(with bookmark:Data)
	{
		var isStale = false
		
		do
		{
			#if os(macOS)
	
			try self.init(
				resolvingBookmarkData:bookmark,
				options:[.withSecurityScope],
				relativeTo:nil,
				bookmarkDataIsStale:&isStale)
			
			#else
			
			try self.init(
				resolvingBookmarkData:bookmark,
				options: [.withoutUI],
				relativeTo:nil,
				bookmarkDataIsStale:&isStale)
			
			#endif
			
//			if isStale { return nil }
		}
		catch
		{
			return nil
		}
	}
}


//----------------------------------------------------------------------------------------------------------------------
