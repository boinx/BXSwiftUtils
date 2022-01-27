//**********************************************************************************************************************
//
//  CGPoint+String.swift
//	Adds new methods to CGPoint
//  Copyright ©2018 Peter Baumgartner. All rights reserved.
//
//**********************************************************************************************************************


import Foundation
#if os(iOS)
import UIKit
#endif


//----------------------------------------------------------------------------------------------------------------------


extension CGPoint
{
	/// Converts a CGPoint to a string
	
	public var string:String
	{
        #if os(iOS)
		return NSCoder.string(for:self) //NSStringFromCGPoint(self)
        #else
		return NSStringFromPoint(self)
        #endif
	}

	/// Creates a CGPoint from a string
	
	public init(with string:String)
	{
        #if os(iOS)
		let tmp = NSCoder.cgPoint(for:string) //CGPointFromString(string)
        #else
		let tmp = NSPointFromString(string)
        #endif
		
		self.init(x:tmp.x,y:tmp.y)
	}
	
	/// Return false if any of the CGRect values contain invalid values like NaN or Inf
	
	var isValid:Bool
	{
		if self.x.isInfinite || self.x.isNaN || self.x.isSignalingNaN { return false }
		if self.y.isInfinite || self.y.isNaN || self.y.isSignalingNaN { return false }
		return true
	}
}

	
//----------------------------------------------------------------------------------------------------------------------
