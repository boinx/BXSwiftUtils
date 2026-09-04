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

    mutating func xor(with data: Data, maximumRepeatCount: Int = 0)
    {
    	// Index from startIndex rather than from zero. Data has SLICE semantics: `data[2...]` keeps its parent's
    	// indices, so subscripting a slice with 0..<count either reads the wrong bytes or runs off the end and traps.
    	// The same applies to the key, which can just as easily be a slice of a larger buffer.
    	
    	let n1 = self.count
    	let n2 = data.count
    	
    	// An empty key would make `i % n2` a division by zero, which traps rather than doing nothing
    	
    	guard n2 > 0 else { return }
    	
    	let start = self.startIndex
    	let keyStart = data.startIndex
    	
		for i in 0..<n1
		{
			if maximumRepeatCount > 0 && i/n2 >= maximumRepeatCount { break }
			
			self[start + i] ^= data[keyStart + (i % n2)]
		}
     }


//----------------------------------------------------------------------------------------------------------------------


	/// Returns an inverted copy of self, i.e. where the bits are inverted with the NOT operator.
	/// - returns: A copy of the Data with inverted bits

    func inverted() -> Data
    {
    	// Iterating `indices` rather than 0..<count, for the same slice reason as xor(with:) above
    	
    	var copy = self
    	
		for i in copy.indices
		{
			copy[i] = ~copy[i]
		}
		
		return copy
	}

}


//----------------------------------------------------------------------------------------------------------------------
