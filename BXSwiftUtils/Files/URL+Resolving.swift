//**********************************************************************************************************************
//
//  URL+Resolving.swift
//	Convenience methods for working with AliasData
//  Copyright ©2018 Peter Baumgartner. All rights reserved.
//
//**********************************************************************************************************************


import Foundation


//----------------------------------------------------------------------------------------------------------------------


// MARK: -

public extension URL
{
	/// Creates a URL for the AliasRecord contained in the given Data
	///
	/// Warning: This function doesn't yield the expected result yet - still in development!
	/// - parameter aliasData: Data containing an AliasRecord
	/// - returns: The URL that aliasData was pointing to

	public static func resolving(aliasData: Data) throws -> URL?
	{
		#if os (iOS)

		// Since iOS doesn't support the CFURLCreateBookmarkDataFromAliasRecord function, we first write
		// the aliasData to a temporary file, which will be deleted after we are done using it.

		let folder = NSTemporaryDirectory()
		let tmpName = UUID().uuidString
		let tmpPath = "\(folder)/\(tmpName).alias"
		let tmpURL = URL(fileURLWithPath:tmpPath)

		try aliasData.write(to:tmpURL)

		defer
		{
			DispatchQueue.main.async { try? FileManager.default.removeItem(at:tmpURL) }
		}

		// Make sure that the OS recognizes it as an alias file

		var attrs:[UInt8] = [0x61,0x6C,0x69,0x73,0x4D,0x41,0x43,0x53,0x80,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00]
		let attrData = Data(buffer:UnsafeBufferPointer(start:&attrs,count:attrs.count))

		_ = tmpURL.withUnsafeFileSystemRepresentation
		{
			path in

			attrData.withUnsafeBytes
			{
				setxattr(path,"com.apple.FinderInfo",$0,attrData.count,0,0)
			}
		}

		// Then resolve the aliasFile (on disk) to a URL

		return try URL(resolvingAliasFileAt:tmpURL,options:[.withoutUI,.withoutMounting])
		
		#else
		
		// On macOS we can convert to a bookmark and then resolve that
		
		if let bookmarkRef = CFURLCreateBookmarkDataFromAliasRecord(kCFAllocatorDefault,aliasData as CFData)
		{
			let bookmarkData = bookmarkRef.takeRetainedValue() as Data
			defer { bookmarkRef?.release() }
			var isStale = false
			return try URL(resolvingBookmarkData:bookmarkData, options:[.withoutUI,.withoutMounting], relativeTo:nil, bookmarkDataIsStale:&isStale)
		}
		
		#endif
	}
	
}


//----------------------------------------------------------------------------------------------------------------------
