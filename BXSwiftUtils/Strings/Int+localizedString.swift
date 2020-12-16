//**********************************************************************************************************************
//
//  Int+localizedString.swift
//	Localized strings for singular/plural values
//  Copyright ©2020 Peter Baumgartner. All rights reserved.
//
//**********************************************************************************************************************


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
}


//----------------------------------------------------------------------------------------------------------------------


public extension Bundle
{
	static let BXSwiftUtils = Bundle(identifier:"com.boinx.BXSwiftUtils")
}


//----------------------------------------------------------------------------------------------------------------------
