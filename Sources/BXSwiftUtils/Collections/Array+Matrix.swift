//**********************************************************************************************************************
//
//  Array+Matrix.swift
//	Creates a 2D matrix
//  Copyright ©2023 Peter Baumgartner. All rights reserved.
//
//**********************************************************************************************************************


public extension Array
{
	/// Creates a 2D matrix of size width x height, with each element set to intitialValue
			
	static func matrix(width:Int, height:Int, initialValue:Element) -> [[Element]]
	{
		var matrix:[[Element]] = []
		
		for _ in 0 ..< height
		{
			matrix += Array<Element>(repeating:initialValue, count:width)
		}
		
		return matrix
	}
}


//----------------------------------------------------------------------------------------------------------------------
