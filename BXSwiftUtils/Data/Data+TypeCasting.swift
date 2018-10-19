//**********************************************************************************************************************
//
//  Data+TypeCasting.swift
//  Adds methods to convert between Array and Data
//  Copyright ©2018 Peter Baumgartner. All rights reserved.
//
//**********************************************************************************************************************


import Foundation


//----------------------------------------------------------------------------------------------------------------------


public extension Data
{

	/// Wraps an Array in a Data object WITHOUT copying the underlying memory
	/// - parameter array: An array of values of type T
	
	init<T>(usingMemoryOf array: inout [T])
    {
		let ptr = UnsafeMutableRawPointer(&array)
		let count = array.count * MemoryLayout<T>.stride
        self.init(bytesNoCopy:ptr, count:count, deallocator:.none)
    }


	/// Converts a Data object to an Array WITHOUT copying the underlying memory
	/// - parameter type: The type of the array elements

    func asArray<T>(ofType type: T.Type) -> [T]
    {
    	let count = self.count / MemoryLayout<T>.stride
		
        return self.withUnsafeBytes
        {
            [T](UnsafeBufferPointer(start:$0, count:count))
        }
    }

}


//----------------------------------------------------------------------------------------------------------------------
