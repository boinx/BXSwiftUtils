//**********************************************************************************************************************
//
//  Thread+NSException+catch.swift
//  Adds catching of NSExceptions to Swift
//  Copyright ©2025 Peter Baumgartner. All rights reserved.
//
//**********************************************************************************************************************


import Foundation


//----------------------------------------------------------------------------------------------------------------------


extension NSException
{
	/// This function catches Swift errors **and** NSException that are thrown inside the worker block.
	///
	/// NSExceptions are converted to Swift Error so that they can be handled by the calling Swift code in the regular fashion.
	
	public class func `catch`(_ block:() throws -> Void) throws
	{
		try NSException.toSwiftErrorThrowing
		{
			errorRef in
			
			do
			{
				try block()
			}
			catch
			{
				errorRef?.pointee = error as NSError
			}
		}
	}
	

}


//----------------------------------------------------------------------------------------------------------------------
