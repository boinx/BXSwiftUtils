//**********************************************************************************************************************
//
//  Date+Compare.swift
//	Adds compare operators to Date
//  Copyright ©2025 Peter Baumgartner. All rights reserved.
//
//**********************************************************************************************************************


import Foundation


//----------------------------------------------------------------------------------------------------------------------


public extension Date
{
	/// Checks if two Dates are almost the same
	
    static func ~=(lhs:Date, rhs:Date) -> Bool
    {
        return abs(lhs.timeIntervalSince1970 - rhs.timeIntervalSince1970) < dateComparisonTolerance
    }
    
	private static let dateComparisonTolerance:TimeInterval = 1.0
}


//----------------------------------------------------------------------------------------------------------------------


