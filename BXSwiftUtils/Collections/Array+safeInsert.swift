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

	public mutating func safeInsert(element:Element, at index:Int, clipIndexToValidRange:Bool = true)
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
	}
}


//----------------------------------------------------------------------------------------------------------------------
