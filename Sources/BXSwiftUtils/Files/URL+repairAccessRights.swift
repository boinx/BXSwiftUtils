//**********************************************************************************************************************
//
//  URL+repairAccessRights.swift
//	Helper function for debugging file access problems
//  Copyright ©2022 Peter Baumgartner. All rights reserved.
//
//**********************************************************************************************************************


import Foundation

#if canImport(AppKit)
import AppKit
#endif


//----------------------------------------------------------------------------------------------------------------------


public extension URL
{

	/// If the file at this URL is not readable, then try to repair the access rights (using the workaround
	/// described below)
	
	func repairAccessRightsIfNeeded(in function:StaticString = #function) throws
	{
		guard self.exists else { throw NSError(domain:NSCocoaErrorDomain, code:NSFileReadNoSuchFileError) }

		if !self.isReadable
		{
			log.warning {"\(Self.self).\(function) - FILE NOT READABLE - TRY REPAIRING at \(self.path)"}
			
			try repairAccessRights()
			
			let copy = self.copy
			
			if !copy.isReadable
			{
				log.error {"\(Self.self).\(function) - FILE NOT READABLE after renaming at \(copy.path)"}
				throw NSError(domain:NSCocoaErrorDomain, code:NSFileReadNoPermissionError)
			}
		}
	}
	

	/// This function uses a obscure workaround to repair (or self-heal) broken read access rights in FotoMagico 6.
	///
	/// In some situations read access to media files in the working directory (tmp/.../Files/file.jpg) was denied
	/// by the sandbox. Renaming the file to a tmp name and then renaming it again to the original filename seems
	/// to magically repair access rights. While this looks like a workaround for now, the original source of the
	/// problem has not been discovered yet.
	
	func repairAccessRights() throws
	{
		let srcFilename = self.lastPathComponent
		let dstFilename = srcFilename + ".tmp"
		
		let srcURL = self
		let dstURL = self.deletingLastPathComponent().appendingPathComponent(dstFilename)
				
		try FileManager.default.moveItem(at:srcURL, to:dstURL)
		try FileManager.default.moveItem(at:dstURL, to:srcURL)
	}
	
	
//----------------------------------------------------------------------------------------------------------------------


	/// Call this helper function to debug file access problems
	
	func checkAccessRights(in function:StaticString = #function) throws
	{
		do
		{
			if !self.exists
			{
				log.error {"\(Self.self).\(function) - FILE NOT FOUND at \(self.path)"}
				throw NSError(domain:NSCocoaErrorDomain, code:NSFileReadNoSuchFileError)
			}
			
			if !self.isReadable
			{
				log.error {"\(Self.self).\(function) - FILE NOT READABLE at \(self.path)"}
				throw NSError(domain:NSCocoaErrorDomain, code:NSFileReadNoPermissionError)
			}
		}
		catch
		{
			#if DEBUG
			#if os(macOS)
			DispatchQueue.main.async { NSWorkspace.shared.activateFileViewerSelecting([self]) }
			#endif
			#endif
			
			do
			{
				try self.repairAccessRightsIfNeeded(in:function)
			}
			catch
			{
				throw error
			}
		}
	}
	

//----------------------------------------------------------------------------------------------------------------------


	/// Creates a new file URL with the same path
	///
	/// The new instance doesn't carry the baggage (i.e. any cached data about access rights)
	
	var copy:URL
	{
		let path = self.path
		return URL(fileURLWithPath:path)
	}
}


//----------------------------------------------------------------------------------------------------------------------
