//**********************************************************************************************************************
//
//  Array+safeInsert.swift
//	Adds index checking to avoid crashes
//  Copyright ©2021 Peter Baumgartner. All rights reserved.
//
//**********************************************************************************************************************


import Foundation


//----------------------------------------------------------------------------------------------------------------------


extension Array
{
	/// This function is just like the regular insert(_,at:) function, except that it clips the specified index to the valid range before inserting, so that crashes
	/// due to index out-of bounds problems are avoided.
	///
	/// - parameter element: The element to be inserted
	/// - parameter index: The position where it should be inserted
	/// - parameter clipIndexToValidRange: When true an invalid index will be clipped to the valid range. When false an invalid index leads to the element not being inserted at all.
	
	@discardableResult public mutating func safeInsert(_ element:Element, at index:Int, clipIndexToValidRange:Bool = true) -> Int
	{
		var i = index
		let n = self.count
		
		if clipIndexToValidRange
		{
			i.clip(to:0...n)
		}
		
		if i >= 0 && i <= n
		{
			self.insert(element, at:i)
		}
		
		return i
	}
}


//----------------------------------------------------------------------------------------------------------------------
