//**********************************************************************************************************************
//
//  Date+Formatted.swift
//	Adds convenience to Date
//  Copyright ©2022 Peter Baumgartner. All rights reserved.
//
//**********************************************************************************************************************


import Foundation


//----------------------------------------------------------------------------------------------------------------------


public extension String
{
	/// Creates a Date from an Exif string
	
	var date:Date?
	{
		let formatter = DateFormatter()
		formatter.dateFormat = "yyyy:MM:dd HH:mm:ss"
		return formatter.date(from:self)
	}
	
	/// Creates a nicely formatted String from a Date
	
	init(with date:Date)
	{
		let formatter = DateFormatter()
		formatter.dateStyle = .medium
		formatter.timeStyle = .short
		let str = formatter.string(from:date)
		
		self.init(str)
	}
}


//----------------------------------------------------------------------------------------------------------------------


