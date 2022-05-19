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
	private static var formatter:DateFormatter? = nil
	
	/// Creates a Date from an Exif string
	
	var date:Date?
	{
		if Self.formatter == nil { Self.formatter = DateFormatter() }
		guard let formatter = Self.formatter else { return nil }
		
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
		
		formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"    // 2019-03-10T15:59:49.00
		
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


