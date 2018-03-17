//**********************************************************************************************************************
//
//  Date+Components.swift
//	Adds convenience to Date
//  Copyright ©2016 Peter Baumgartner. All rights reserved.
//
//**********************************************************************************************************************


import Foundation
import Darwin


//----------------------------------------------------------------------------------------------------------------------


extension Date
{

	/// Returns the year
	
	public var year: Int
	{
        let components = Calendar.current.dateComponents([.year], from:self)
        if let year = components.year { return year }
		return 0
	}


	/// Returns the month
	
	public var month: Int
	{
        let components = Calendar.current.dateComponents([.month], from:self)
        if let month =  components.month { return month }
		return 0
	}


	/// Returns the day
	
	public var day: Int
	{
        let components = Calendar.current.dateComponents([.day], from:self)
        if let day =  components.day { return day }
		return 0
	}

}


//----------------------------------------------------------------------------------------------------------------------


