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
		
		if let date = formatter.date(from:self)
		{
			return date
		}
		
		formatter.dateFormat = "yyyy-MM-dd HH:mm:ssz"
		
		if let date = formatter.date(from:self)
		{
			return date
		}
		
		formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssz"
		
		if let date = formatter.date(from:self)
		{
			return date
		}
		
		return nil
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


