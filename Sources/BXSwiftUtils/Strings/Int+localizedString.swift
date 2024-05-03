//**********************************************************************************************************************
//
//  Int+localizedString.swift
//	Localized strings for singular/plural values
//  Copyright ©2020 Peter Baumgartner. All rights reserved.
//
//**********************************************************************************************************************


import Foundation


//----------------------------------------------------------------------------------------------------------------------


public extension Int
{
	var localizedTimesString : String
	{
		let format = "%d time(s)".localized(from:"Int+localizedString", bundle:Bundle.BXSwiftUtils)
		return String(format:format,self)
	}

	var localizedFilesString : String
	{
		let format = "%d file(s)".localized(from:"Int+localizedString", bundle:Bundle.BXSwiftUtils)
		return String(format:format,self)
	}

	var localizedItemsString : String
	{
		let format = "%d item(s)".localized(from:"Int+localizedString", bundle:Bundle.BXSwiftUtils)
		return String(format:format,self)
	}

	var localizedObjectsString : String
	{
		let format = "%d object(s)".localized(from:"Int+localizedString", bundle:Bundle.BXSwiftUtils)
		return String(format:format,self)
	}

	var localizedImagesString : String
	{
		let format = "%d image(s)".localized(from:"Int+localizedString", bundle:Bundle.BXSwiftUtils)
		return String(format:format,self)
	}

	var localizedVideosString : String
	{
		let format = "%d video(s)".localized(from:"Int+localizedString", bundle:Bundle.BXSwiftUtils)
		return String(format:format,self)
	}

	var localizedSecondsString : String
	{
		let format = "%d second(s)".localized(from:"Int+localizedString", bundle:Bundle.BXSwiftUtils)
		return String(format:format,self)
	}

	var localizedMinutesString : String
	{
		let format = "%d minute(s)".localized(from:"Int+localizedString", bundle:Bundle.BXSwiftUtils)
		return String(format:format,self)
	}

	var localizedHoursString : String
	{
		let format = "%d hour(s)".localized(from:"Int+localizedString", bundle:Bundle.BXSwiftUtils)
		return String(format:format,self)
	}

	var localizedDaysString : String
	{
		let format = "%d day(s)".localized(from:"Int+localizedString", bundle:Bundle.BXSwiftUtils)
		return String(format:format,self)
	}

	var localizedWeeksString : String
	{
		let format = "%d weeks(s)".localized(from:"Int+localizedString", bundle:Bundle.BXSwiftUtils)
		return String(format:format,self)
	}

	var localizedMonthsString : String
	{
		let format = "%d month(s)".localized(from:"Int+localizedString", bundle:Bundle.BXSwiftUtils)
		return String(format:format,self)
	}

	var localizedYearsString : String
	{
		let format = "%d year(s)".localized(from:"Int+localizedString", bundle:Bundle.BXSwiftUtils)
		return String(format:format,self)
	}

	var localizedLicensesString : String
	{
		let format = "%d license(s)".localized(from:"Int+localizedString", bundle:Bundle.BXSwiftUtils)
		return String(format:format,self)
	}

	var localizedSlidesString : String
	{
		let format = "%d slide(s)".localized(from:"Int+localizedString", bundle:Bundle.BXSwiftUtils)
		return String(format:format,self)
	}

	var localizedSongsString : String
	{
		let format = "%d song(s)".localized(from:"Int+localizedString", bundle:Bundle.BXSwiftUtils)
		return String(format:format,self)
	}
}


//----------------------------------------------------------------------------------------------------------------------


public extension Int
{
	/// Creates a formatted file size description for the number of bytes
	
	var fileSizeDescription:String
	{
		let bytes = self
		let kilobytes = Double(bytes) / 1000
		let megabytes = kilobytes / 1000
		let gigabytes = megabytes / 1000
		let terabytes = gigabytes / 1000
		
		if bytes < 1000
		{
			return"\(bytes) bytes"
		}
		else if kilobytes < 1000
		{
			return "\(kilobytes.string(digits:1)) KB"
		}
		else if megabytes < 1000
		{
			return "\(megabytes.string(digits:1)) MB"
		}
		else if gigabytes < 1000
		{
			return "\(gigabytes.string(digits:1)) GB"
		}

		return "\(terabytes.string(digits:1)) TB"
	}
}


//----------------------------------------------------------------------------------------------------------------------


public extension Double
{
	/// Formats a Double number with the specified precision
	
	func string(for format:String = "#.#", digits:Int = 1) -> String
	{
		let formatter = NumberFormatter.forFloatingPoint(with:format, numberOfDigits:digits)
		return formatter.string(from:NSNumber(value:self)) ?? "0"
	}
}


//----------------------------------------------------------------------------------------------------------------------
