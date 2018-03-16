//**********************************************************************************************************************
//
//  CGPoint+FMExtensions.swift
//	Adds convenience methods
//  Copyright ©2016 Peter Baumgartner. All rights reserved.
//
//**********************************************************************************************************************


import Foundation
import CoreGraphics


//----------------------------------------------------------------------------------------------------------------------


/// This extension adds some vector math operators to CGPoint/NSPoint

extension CGPoint
{
	public static func + (l: CGPoint, r: CGPoint) -> CGPoint
	{
		return CGPoint(x:l.x+r.x,y:l.y+r.y)
	}
	
	public static func - (l: CGPoint, r: CGPoint) -> CGPoint
	{
		return CGPoint(x:l.x-r.x,y:l.y-r.y)
	}

	public static func * (l: CGPoint, r: CGFloat) -> CGPoint
	{
		return CGPoint(x:l.x*r,y:l.y*r)
	}

	public static func * (l: CGFloat, r: CGPoint) -> CGPoint
	{
		return CGPoint(x:l*r.x,y:l*r.y)
	}

	public static func * (l: CGPoint, r: Double) -> CGPoint
	{
		return CGPoint(x:l.x*CGFloat(r),y:l.y*CGFloat(r))
	}

	public static func * (l: Double, r: CGPoint) -> CGPoint
	{
		return CGPoint(x:CGFloat(l)*r.x,y:CGFloat(l)*r.y)
	}

	public static func / (l: CGPoint, r: CGFloat) -> CGPoint
	{
		return CGPoint(x:l.x/r,y:l.y/r)
	}

	public static func / (l: CGPoint, r: Double) -> CGPoint
	{
		return CGPoint(x:l.x/CGFloat(r),y:l.y/CGFloat(r))
	}

	public static func += (l:inout CGPoint, r: CGPoint)
	{
		l = CGPoint(x:l.x+r.x,y:l.y+r.y)
	}

	public static func *= (l:inout CGPoint, r: CGFloat)
	{
		l = CGPoint(x:l.x*r,y:l.y*r)
	}

	public static func *= (l:inout CGPoint, r: Double)
	{
		l = CGPoint(x:l.x*CGFloat(r),y:l.y*CGFloat(r))
	}
	
	/// Returns the length of a vector
	
	public var length: CGFloat
	{
		return sqrt(self.x*self.x + self.y*self.y)
	}
	
	/// Normalized a vector to length 1.0, keeping is direction intact
	
	public var normalized: CGPoint
	{
		return self / self.length
	}
}


//----------------------------------------------------------------------------------------------------------------------
