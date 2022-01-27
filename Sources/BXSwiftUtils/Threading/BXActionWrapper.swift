//**********************************************************************************************************************
//
//  BXActionWrapper.swift
//  Wraps an action closure in an NSObject
//  Copyright ©2020 Peter Baumgartner. All rights reserved.
//
//**********************************************************************************************************************


import Foundation


//----------------------------------------------------------------------------------------------------------------------


/// Helper class that wraps an async action block for later execution.

public class BXActionWrapper : NSObject
{
	private var action:()->Void
	
	public init(_ action: @escaping ()->Void)
	{
		self.action = action
	}
	
	@objc public func execute()
	{
		self.action()
	}
}


//----------------------------------------------------------------------------------------------------------------------
