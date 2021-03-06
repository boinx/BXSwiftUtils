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

	/// Wraps a value of type T in Data object WITHOUT copying the underlying memory
	/// - parameter value: The value or object to be wrapped

	init<T>(usingMemoryOf value: inout T)
	{
        self.init(buffer: UnsafeBufferPointer(start: &value, count: 1))
    }


	/// Converts a Data object to a value WITHOUT copying the underlying memory
	/// - parameter type: The type of the value

    func `as`<T>(type: T.Type) -> T
    {
        return self.withUnsafeBytes { $0.pointee }
    }
	
	
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

    func asArray<T>(ofType: T.Type) -> [T]
    {
    	let count = self.count / MemoryLayout<T>.stride
		
        return self.withUnsafeBytes
        {
            [T](UnsafeBufferPointer(start:$0, count:count))
        }
    }

}


//----------------------------------------------------------------------------------------------------------------------
