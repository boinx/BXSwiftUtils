//**********************************************************************************************************************
//
//  CGRect+String.swift
//	Adds new methods to CGRect
//  Copyright ©2018 Peter Baumgartner. All rights reserved.
//
//**********************************************************************************************************************


import Foundation
#if os(iOS)
import UIKit
#endif


//----------------------------------------------------------------------------------------------------------------------


extension CGRect
{
	/// Converts a CGRect to a string
	
	public var string:String
	{
        #if os(iOS)
		return NSStringFromCGRect(self)
        #else
		return NSStringFromRect(self)
        #endif
	}

	/// Creates a CGRect from a string
	
	public init(with string:String)
	{
        #if os(iOS)
		let tmp = CGRectFromString(string)
        #else
		let tmp = NSRectFromString(string)
        #endif
		
		self.init(x:tmp.origin.x,y:tmp.origin.y,width:tmp.size.width,height:tmp.size.height)
	}
}

	
//----------------------------------------------------------------------------------------------------------------------
