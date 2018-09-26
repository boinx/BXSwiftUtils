//**********************************************************************************************************************
//
//  CGVector+String.swift
//	Adds new methods to CGVector
//  Copyright ©2018 Peter Baumgartner. All rights reserved.
//
//**********************************************************************************************************************


import Foundation
#if os(iOS)
import UIKit
#endif


//----------------------------------------------------------------------------------------------------------------------


extension CGVector
{
	/// Converts a CGVector to a string
	
	public var string:String
	{
        #if os(iOS)
		return NSStringFromCGVector(self)
        #else
		return NSStringFromPoint(self)
        #endif
	}

	/// Creates a CGVector from a string
	
	public init(with string:String)
	{
        #if os(iOS)
		let tmp = CGVectorFromString(string)
        #else
		let tmp = NSPointFromString(string)
        #endif
		
		self.init(dx:tmp.dx,dy:tmp.dy)
	}
}

	
//----------------------------------------------------------------------------------------------------------------------
