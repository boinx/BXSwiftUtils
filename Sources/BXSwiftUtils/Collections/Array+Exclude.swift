//**********************************************************************************************************************
//
//  Array+Exclude.swift
//	Various Array operations
//  Copyright ©2020 Peter Baumgartner. All rights reserved.
//
//**********************************************************************************************************************


import Foundation


//----------------------------------------------------------------------------------------------------------------------


extension Array where Element:AnyObject
{
	/// Removes the specified object from the receving array. Object instance equality === is used to determine whether an element should be removed.
	
	public func excluding(_ objects:[Element]) -> [Element]
	{
		return self.filter
		{
			for object in objects
			{
				if object === $0 { return false }
			}
			
			return true
		}
	}
}


//----------------------------------------------------------------------------------------------------------------------
