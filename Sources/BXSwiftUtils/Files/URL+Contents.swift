//**********************************************************************************************************************
//
//  URL+Contents.swift
//	Convenience methods to query the contents of folder or files
//  Copyright ©2018 Peter Baumgartner. All rights reserved.
//
//**********************************************************************************************************************


import Foundation


//----------------------------------------------------------------------------------------------------------------------


// MARK: -

public extension URL
{
	/// Performs a shallow scan of the directory pointed to by a folder URL and returns the resulting child URLs.
	/// - returns: An array of URLs for all direct children
	
	func shallowContentsOfDirectory() throws -> [URL]
	{
		let paths = try FileManager.default.contentsOfDirectory(atPath:self.path)
		let urls:[URL] = paths.map { self.appendingPathComponent($0) }
		return urls
	}
	
	
	/// Updates the contents of a file on disk using the supplied handler closure.
	///
	/// This method can be used to modify the content of a file on disk - withour the need to read the whole file
	/// into memory. This is useful for very large file (e.g. image or video files) and loading just small chunks
	/// at a time is feasible.
	///
	/// - parameter offset: The offset from the start of the file where updating should begin
	/// - parameter length: The number of bytes to be updated. Pass 0 to update all bytes up to end of file.
	/// - parameter transformDataHandler: This block receives the original Data from the file and modifies it as needed
	/// - returns: The number of bytes that were written back to the file

	@discardableResult func updateFileContents(offset: UInt64, length: Int, using transformDataHandler: (inout Data)->() ) throws -> Int
	{
		// Open the file for reading & writing
		
		let handle = try FileHandle(forUpdating: self)

		// Read the data from the file and transform it with the transformDataHandler
		
		handle.seek(toFileOffset: offset)
		var data = length>0 ? handle.readData(ofLength:length) : handle.readDataToEndOfFile()
		transformDataHandler(&data)

		// Write the modified data back to file at correct offset
		
		handle.seek(toFileOffset: offset)
		handle.write(data)
		handle.synchronizeFile()
		handle.closeFile()
		
		// Return the number of bytes that were written
		
		return data.count
	}
}


//----------------------------------------------------------------------------------------------------------------------
