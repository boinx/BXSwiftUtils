//**********************************************************************************************************************
//
//  BXSignpostMixin.swift
//	Convenience function for using OSSignpost
//  Copyright ©2018 Peter Baumgartner. All rights reserved.
//
//**********************************************************************************************************************


import os.signpost


//----------------------------------------------------------------------------------------------------------------------


/// OSLog for signpost measuring

@available(OSX 10.12, *)
let signpostlog:OSLog =
{
	let identifier = Bundle.main.bundleIdentifier ?? "com.boinx.BXSwiftUtils"
	return OSLog(subsystem:identifier, category:identifier)
}()


//----------------------------------------------------------------------------------------------------------------------


public protocol BXSignpostMixin : class
{

}


extension BXSignpostMixin
{

	/// Begins a signpost for measuring the execution time of a function
	/// - parameter name: The name of the calling class
	/// - parameter function: the name of the calling function
	/// - returns: An identifier that can be passed to the endSignpost() function
	
	public func beginSignpost(in name:StaticString,_ function:String = #function) -> Any?
	{
		if #available(iOS 12.0, OSX 10.14, *)
		{
			let signpostID = OSSignpostID(log:signpostlog)
			os_signpost(.begin, log:signpostlog, name:name, signpostID:signpostID, "%@.begin",function)
			return signpostID as Any
		}
		
		return nil
	}


	/// Ends a signpost for measuring the execution time of a function
	/// - parameter identifier: The identifier that was returned by the beginSignpost() function
	/// - parameter name: The name of the calling class
	/// - parameter function: the name of the calling function
	
	public func endSignpost(with identifier:Any?,in name:StaticString,_ function:String = #function)
	{
		if #available(iOS 12.0, OSX 10.14, *)
		{
			guard let signpostID = identifier as? OSSignpostID else { return }
			os_signpost(.end, log:signpostlog, name:name, signpostID:signpostID, "%@.end",function)
		}
	}
	
}


//----------------------------------------------------------------------------------------------------------------------


