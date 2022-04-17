//**********************************************************************************************************************
//
//  Array+Exclude.swift
//	Various Array operations
//  Copyright ©2020-2022 Peter Baumgartner. All rights reserved.
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


// Taken from https://www.hackingwithswift.com/example-code/language/how-to-remove-duplicate-items-from-an-array

extension Array where Element: Hashable
{
	/// Removes duplicate elements from the array, preserving the original order of the elements.
	
    public func removingDuplicates() -> [Element]
    {
        var knownElements:[Element:Bool] = [:]

        return filter
        {
            knownElements.updateValue(true,forKey:$0) == nil
        }
    }

	/// Removes duplicate elements from the array, preserving the original order of the elements.
	
    public mutating func removeDuplicates()
    {
        self = self.removingDuplicates()
    }
}


//----------------------------------------------------------------------------------------------------------------------
