//**********************************************************************************************************************
//
//  CGSize+String.swift
//	Adds new methods to CGSize
//  Copyright ©2018 Peter Baumgartner. All rights reserved.
//
//**********************************************************************************************************************


import Foundation
#if os(iOS)
import UIKit
#endif


//----------------------------------------------------------------------------------------------------------------------


extension CGSize
{
	/// Converts a CGSize to a string
	
	public var string:String
	{
		return NSStringFromCGSize(self)
	}

	/// Creates a CGSize from a string
	
	public init(with string:String)
	{
		let tmp = CGSizeFromString(string)
		self.init(width:tmp.width,height:tmp.height)
	}
}

	
//----------------------------------------------------------------------------------------------------------------------
