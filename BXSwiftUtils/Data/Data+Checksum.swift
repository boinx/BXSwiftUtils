//**********************************************************************************************************************
//
//  Data+Checksum.swift
//  Adds a checksum property
//  Copyright ©2018 Peter Baumgartner. All rights reserved.
//
//**********************************************************************************************************************


import Foundation


//----------------------------------------------------------------------------------------------------------------------


public extension Data
{

	/// Calculates the checksum of the bytes contained in self
	///
	/// Please note that the checksum is masked with 0xFF, so it will always be in the range 0...255
	
    var checksum : Int
    {
        return self
        	.map { Int($0) }
        	.reduce(0,+)
        	& 0xff
    }
	
}

//----------------------------------------------------------------------------------------------------------------------
