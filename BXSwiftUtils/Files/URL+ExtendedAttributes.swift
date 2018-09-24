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

//    public func setExtendedAttribute<T>(value:T, forName name: String) throws
//	{
//		var tmp = value
//		let data = Data(buffer:UnsafeBufferPointer(start:&tmp,count:1))
//		try self.setExtendedAttribute(data:data,forName:name)
//	}
//
//    public func extendedAttribute<T>(type:T.Type, forName name: String) throws -> T
//    {
//    	let data = try self.extendedAttribute(forName:name)
//		let value:T = data.withUnsafeBytes { $0.pointee }
//		return value
//    }


//----------------------------------------------------------------------------------------------------------------------


    func setExtendedAttribute(string: String, forName name: String) throws
	{
		if let data = string.data(using:.utf8)
		{
			try self.setExtendedAttribute(data:data,forName:name)
		}
	}

    func extendedAttributeString(forName name: String) throws -> String?
    {
    	let data = try self.extendedAttribute(forName:name)
    	return String(data:data,encoding:.utf8)
    }
	

//----------------------------------------------------------------------------------------------------------------------


    func setExtendedAttribute(int: Int, forName name: String) throws
	{
		var tmp = int
		let data = Data(buffer:UnsafeBufferPointer(start:&tmp,count:1))
		try self.setExtendedAttribute(data:data,forName:name)
	}

    func extendedAttributeInt(forName name: String) throws -> Int
    {
    	let data = try self.extendedAttribute(forName:name)
		let value:Int = data.withUnsafeBytes { $0.pointee }
		return value
    }
	

//----------------------------------------------------------------------------------------------------------------------


    /// Set extended attribute
	
    public func setExtendedAttribute(data: Data, forName name: String) throws
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

	/// Get extended attribute
	
    public func extendedAttribute(forName name: String) throws -> Data
    {
        let data = try self.withUnsafeFileSystemRepresentation
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

    /// Remove extended attribute
	
    public func removeExtendedAttribute(forName name: String) throws
    {

        try self.withUnsafeFileSystemRepresentation { fileSystemPath in
            let result = removexattr(fileSystemPath, name, 0)
            guard result >= 0 else { throw URL.posixError(errno) }
        }
    }

    /// Get list of all extended attributes
	
    public func listExtendedAttributes() throws -> [String]
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
