//**********************************************************************************************************************
//
//  Date+Components.swift
//	Adds convenience to Date
//  Copyright ©2016-2022 Peter Baumgartner. All rights reserved.
//
//**********************************************************************************************************************


import Foundation
import Darwin


//----------------------------------------------------------------------------------------------------------------------


public extension Date
{
	/// Returns the year
	
	var year: Int
	{
		Calendar.current.component(.year, from:self)
	}

	/// Returns the month
	
	var month: Int
	{
		Calendar.current.component(.month, from:self)
	}

	/// Returns the day
	
	var day: Int
	{
		Calendar.current.component(.day, from:self)
	}
}


//----------------------------------------------------------------------------------------------------------------------


public extension Date
{
	/// Returns the current year
	
    static var currentYear:Int
    {
        Date().year
    }

	/// Create a Date for the specified year, month, day
	
	static func fromComponents(year:Int, month:Int, day:Int) -> Date?
	{
		DateComponents(calendar:Calendar.current, year:year, month:month, day:day).date
	}
}


//----------------------------------------------------------------------------------------------------------------------


public extension Calendar
{
    var currentYear:Int
    {
        self.component(.year, from:Date())
    }
    
    func startOf(year:Int) -> Date?
    {
        self.date(from:DateComponents(year:year))
    }
    
    func startOf(year:Int, month:Int) -> Date?
    {
        self.date(from:DateComponents(year:year, month:month))
    }
}


//----------------------------------------------------------------------------------------------------------------------


@available(macOS 10.12, *)

public extension Calendar
{
    /// Returns the DateInterval for the specified year
	
    func dateInterval(year:Int) -> DateInterval?
    {
		guard let start = self.startOf(year:year) else { return nil }
		return self.dateInterval(of:.year, for:start)
    }
    
    /// Returns the DateInterval for the specified month
	
    func dateInterval(year:Int, month:Int) -> DateInterval?
    {
		guard let start = self.startOf(year:year, month:month) else { return nil }
		return self.dateInterval(of:.month, for:start)
    }
    
    /// Returns the DateInterval for the specified day
	
    func dateInterval(year:Int, month:Int, day:Int) -> DateInterval?
    {
		guard let start = Date.fromComponents(year:year, month:month, day:day) else { return nil }
		return self.dateInterval(of:.day, for:start)
    }
}


//----------------------------------------------------------------------------------------------------------------------


public extension Calendar
{
	/// Returns the short month name at the specified index
	
	mutating func localizedShortMonthName(at index:Int) -> String
	{
		self.locale = Locale.autoupdatingCurrent
		let names = self.shortMonthSymbols
		guard index >= 1 && index <= names.count else { return "" }
		return names[index-1]
	}
	
	/// Returns the month name at the specified index
	
	mutating func localizedMonthName(at index:Int) -> String
	{
		self.locale = Locale.autoupdatingCurrent
		let names = self.monthSymbols
		guard index >= 1 && index <= names.count else { return "" }
		return names[index-1]
	}
}


//----------------------------------------------------------------------------------------------------------------------


