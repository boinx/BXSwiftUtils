//**********************************************************************************************************************
//
//  URL+Info.swift
//	Adds new methods to URL
//  Copyright ©2016-2018 Peter Baumgartner. All rights reserved.
//
//**********************************************************************************************************************


import Foundation
import Darwin


//----------------------------------------------------------------------------------------------------------------------


// MARK: -

extension URL
{

	// Status
	
	public enum Status : Int
	{
		case doesNotExist
		case accessDenied
		case readOnly
		case readWrite
	}

	/// Gets the file status
	
	public var status: Status
	{
		let cpath = self.path.cString(using: String.Encoding.utf8)
		let exists = access(cpath,F_OK) == 0
		let readable = access(cpath,R_OK) == 0
		let writeable = access(cpath,W_OK) == 0
		
		if !exists
		{
			return Status.doesNotExist
		}
		else  if !readable
		{
			return Status.accessDenied
		}
		else if !writeable
		{
			return Status.readOnly
		}
		
		return Status.readWrite
	}

}


//----------------------------------------------------------------------------------------------------------------------


// MARK: -

extension URL
{

	// FIXME: The following methods could also be implemented on the basis of status
	
	/// Checks if the file exists
	
	public var exists: Bool
	{
		if self.isFileURL
		{
			return FileManager.default.fileExists(atPath: self.path)
		}
		
		return false
	}

	/// Checks if the file is readable
	
	public var isReadable: Bool
	{
		do
		{
			let key = URLResourceKey.isReadableKey
			let values = try self.resourceValues(forKeys: [key])
			if let readable = values.isReadable
			{
				return readable
			}
			else
			{
				return false
			}
		}
		catch
		{
			return false
		}
	}

	/// Checks if the file is writable
	
	public var isWritable: Bool
	{
		do
		{
			let key = URLResourceKey.isWritableKey
			let values = try self.resourceValues(forKeys: [key])
			if let readable = values.isReadable
			{
				return readable
			}
			else
			{
				return false
			}
		}
		catch
		{
			return false
		}
	}
		
}


//----------------------------------------------------------------------------------------------------------------------


// MARK: -

extension URL
{

	/// Checks if the URL points to a directory
	
	public var isDirectory: Bool
	{
		do
		{
			let key = URLResourceKey.isDirectoryKey
			let values = try self.resourceValues(forKeys: [key])
			if let directory = values.isDirectory
			{
				return directory
			}
			else
			{
				return false
			}
		}
		catch
		{
			return false
		}
	}
	
	/// Checks if the URL points to a package directory
	
	public var isPackage: Bool
	{
		do
		{
			let key = URLResourceKey.isPackageKey
			let values = try self.resourceValues(forKeys: [key])
			if let package = values.isPackage
			{
				return package
			}
			else
			{
				return false
			}
		}
		catch
		{
			return false
		}
	}
	
	/// Checks if the URL points to a symlink

	public var isSymbolicLink: Bool
	{
		do
		{
			let key = URLResourceKey.isSymbolicLinkKey
			let values = try self.resourceValues(forKeys: [key])
			if let package = values.isSymbolicLink
			{
				return package
			}
			else
			{
				return false
			}
		}
		catch
		{
			return false
		}
	}

	/// Returns the UTI of a file URL
	
	public var uti: String?
	{
		do
		{
			let key = URLResourceKey.typeIdentifierKey
			let values = try self.resourceValues(forKeys: [key])
			let uti = values.typeIdentifier
			return uti
		}
		catch // let error
		{
			return nil
		}
	}
 
 	/// Returns the fileSize in bytes
	
	public var fileSize: Int?
	{
		do
		{
			let key = URLResourceKey.fileSizeKey
			let values = try self.resourceValues(forKeys: [key])
			let fileSize = values.fileSize
			return fileSize
		}
		catch // let error
		{
			return nil
		}
	}


	/// Returns the creation date of a file URL
	
	public var creationDate: Date?
	{
		do
		{
			let key = URLResourceKey.creationDateKey
			let values = try self.resourceValues(forKeys: [key])
			let date = values.creationDate
			return date
		}
		catch
		{
			return nil
		}
	}

	/// Returns the modification date of a file URL
	
	public var modificationDate: Date?
	{
		do
		{
			let key = URLResourceKey.contentModificationDateKey
			let values = try self.resourceValues(forKeys: [key])
			let date = values.contentModificationDate
			return date
		}
		catch
		{
			return nil
		}
	}

	/// Does the volume for this URL support hardlinking?
	
	public var volumeSupportsHardlinking: Bool
	{
		let key = URLResourceKey.volumeSupportsHardLinksKey
		let values = try? self.resourceValues(forKeys: [key])
		return values?.volumeSupportsHardLinks ?? false
	}

	/// Is this a readonly volume?
	
	public var volumeIsReadOnly: Bool
	{
		let key = URLResourceKey.volumeIsReadOnlyKey
		let values = try? self.resourceValues(forKeys: [key])
		return values?.volumeIsReadOnly ?? false
	}

	/// Return the URL of the volume
	
	public var volumeURL: URL?
	{
		let key = URLResourceKey.volumeURLKey
		let values = try? self.resourceValues(forKeys: [key])
		return values?.volume
	}

	/// Return the UUID of the volume
	
	public var volumeUUID: String?
	{
		let key = URLResourceKey.volumeUUIDStringKey
		let values = try? self.resourceValues(forKeys: [key])
		return values?.volumeUUIDString
	}
	
}


//----------------------------------------------------------------------------------------------------------------------


// MARK: -

#if os(iOS)

extension URL
{
	/// Returns true if this is an URL like ipod-library://item/item.m4a?id=9211483178757089008, which is returned
	/// by the MediaPlayer framework. Unfortunately URLs like this cannot be used with FileManager and other system
	/// level APIs.
	
	public var isiPodLibraryURL:Bool
	{
		return self.scheme == "ipod-library"
	}
}

#endif


//----------------------------------------------------------------------------------------------------------------------


// MARK: -

extension URL
{
	/// Updates the modification date of the file to now
	
	public func touch() throws
	{
		let now = Date()
		let attributes:[FileAttributeKey:Any] = [.modificationDate:now]
		try FileManager.default.setAttributes(attributes, ofItemAtPath:self.path)
	}
}


//----------------------------------------------------------------------------------------------------------------------

