//**********************************************************************************************************************
//
//  URL+ExtendedAttributes.swift
//	Adds convenience methods to access extended attributes of files
//  Copyright ©2016-2018 Peter Baumgartner. All rights reserved.
//
//**********************************************************************************************************************


import Foundation
import Darwin


//----------------------------------------------------------------------------------------------------------------------


public extension URL
{

	/// Set extended attribute

    func setExtendedAttribute<T>(_ value: T, forName name: String) throws
	{
		let data = try PropertyListSerialization.data(fromPropertyList:value,format:.binary,options:0)
		try self.setExtendedAttribute(data,forName:name)
	}

	
 	/// Get extended attribute

	func extendedAttribute<T>(forName name: String) -> T?
    {
    	if let data = self.extendedAttribute(forName:name),
    	   let any = try? PropertyListSerialization.propertyList(from:data, format:nil),
    	   let value = any as? T
    	{
			return value
		}
		
		return nil 
    }
	

//----------------------------------------------------------------------------------------------------------------------


    /// Set extended attribute
	
    func setExtendedAttribute(_ data: Data, forName name: String) throws
    {
        try self.withUnsafeFileSystemRepresentation
        {
        	fileSystemPath in
			
            let result = data.withUnsafeBytes
            {
                setxattr(fileSystemPath,name,$0,data.count,0,0)
            }
			
            guard result >= 0 else { throw URL.posixError(errno) }
        }
    }


//----------------------------------------------------------------------------------------------------------------------


	/// Get extended attribute
	
    func extendedAttribute(forName name: String) -> Data?
    {
        let data = try? self.withUnsafeFileSystemRepresentation
        {
        	fileSystemPath -> Data in

            // Determine attribute size
			
            let length = getxattr(fileSystemPath,name,nil,0,0,0)
            guard length >= 0 else { throw URL.posixError(errno) }

            // Create buffer with required size
			
            var data = Data(count:length)

            // Retrieve attribute
			
			let count = data.count
            let result =  data.withUnsafeMutableBytes
            {
                getxattr(fileSystemPath,name,$0,count,0,0)
            }
			
            guard result >= 0 else { throw URL.posixError(errno) }
            return data
        }
		
        return data
    }


//----------------------------------------------------------------------------------------------------------------------


	/// Checks if an extended attribute is present
	
    func hasExtendedAttribute(forName name: String) -> Bool
    {
        let result = self.withUnsafeFileSystemRepresentation
        {
        	fileSystemPath -> Bool in
            let length = getxattr(fileSystemPath,name,nil,0,0,0)
            return length >= 0
        }
		
        return result
    }


//----------------------------------------------------------------------------------------------------------------------


    /// Remove extended attribute
	
    func removeExtendedAttribute(forName name: String) throws
    {

        try self.withUnsafeFileSystemRepresentation { fileSystemPath in
            let result = removexattr(fileSystemPath, name, 0)
            guard result >= 0 else { throw URL.posixError(errno) }
        }
    }


//----------------------------------------------------------------------------------------------------------------------


    /// Get list of all extended attributes
	
    func listExtendedAttributes() throws -> [String]
    {
        let list = try self.withUnsafeFileSystemRepresentation
        {
        	fileSystemPath -> [String] in
			
            let length = listxattr(fileSystemPath, nil, 0, 0)
            guard length >= 0 else { throw URL.posixError(errno) }

            // Create buffer with required size
			
            var data = Data(count:length)

            // Retrieve attribute list
			
			let count = data.count
            let result = data.withUnsafeMutableBytes
            {
                listxattr(fileSystemPath,$0,count,0)
            }
            guard result >= 0 else { throw URL.posixError(errno) }

            // Extract attribute names
			
			let list = data.split(separator: 0).compactMap
            {
                String(data: Data($0), encoding: .utf8)
            }
			
            return list
        }
		
        return list
    }


//----------------------------------------------------------------------------------------------------------------------


    /// Helper function to create an NSError from a Unix errno
	
    private static func posixError(_ err: Int32) -> NSError
    {
        return NSError(
        	domain: NSPOSIXErrorDomain,
        	code: Int(err),
			userInfo: [NSLocalizedDescriptionKey:
			String(cString: strerror(err))])
    }


//----------------------------------------------------------------------------------------------------------------------


}
