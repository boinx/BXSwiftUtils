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
        #if os(iOS)
		return NSStringFromCGSize(self)
        #else
		return NSStringFromSize(self)
        #endif
	}

	/// Creates a CGSize from a string
	
	public init(with string:String)
	{
        #if os(iOS)
		let tmp = CGSizeFromString(string)
        #else
		let tmp = NSSizeFromString(string)
        #endif
		
		self.init(width:tmp.width,height:tmp.height)
	}
}

	
//----------------------------------------------------------------------------------------------------------------------
