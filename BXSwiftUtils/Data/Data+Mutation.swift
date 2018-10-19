//**********************************************************************************************************************
//
//  Data+Mutation.swift
//  Adds data manipulation methods
//  Copyright ©2018 Peter Baumgartner. All rights reserved.
//
//**********************************************************************************************************************


import Foundation


//----------------------------------------------------------------------------------------------------------------------


public extension Data
{

	/// XORs the bytes of 'self' with the bytes of 'data'
	///
	/// If data is shorter than self, then the value of repeatCount controls the exact behavior of this method.
	/// If repeatCount is 0, then data will be repeated endlessly. If it has a non-zero value, data will be repeated
	/// for this maximum number.
	///
	/// - parameter data: The data to be xored onto self
	/// - parameter maximumRepeatCount: The maximum repetition of data (pass 0 for unlimited)

    public mutating func xor(with data: Data, maximumRepeatCount: Int = 0)
    {
    	let n1 = self.count
    	let n2 = data.count
		
		if maximumRepeatCount > 0
		{
			for i in 0..<n1
			{
				if i/n2 >= maximumRepeatCount { break }
				self[i] ^= data[i % n2]
			}
		}
		else
		{
			for i in 0..<n1
			{
				self[i] ^= data[i % n2]
			}
		}
     }


//----------------------------------------------------------------------------------------------------------------------


	/// Returns an inverted copy of self, i.e. where the bits are inverted with the NOT operator.
	/// - returns: A copy of the Data with inverted bits

    public func inverted() -> Data
    {
   		let n = self.count
    	var copy = self
		
		for i in 0..<n
		{
			copy[i] = ~self[i]
		}
		
		return copy
	}

}


//----------------------------------------------------------------------------------------------------------------------
