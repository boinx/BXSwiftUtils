//**********************************************************************************************************************
//
//  CGPoint+Operators.swift
//	Point and vector operators
//  Copyright ©2016-2020 Peter Baumgartner. All rights reserved.
//
//**********************************************************************************************************************


import Foundation
import CoreGraphics


//----------------------------------------------------------------------------------------------------------------------


public typealias CGVector = CGPoint


//----------------------------------------------------------------------------------------------------------------------


/// This extension adds some vector math operators to CGPoint/NSPoint

extension CGPoint
{
	public static func + (l:CGPoint, r:CGPoint) -> CGPoint
	{
		return CGPoint(x:l.x+r.x,y:l.y+r.y)
	}
	
	public static func - (l:CGPoint, r:CGPoint) -> CGPoint
	{
		return CGPoint(x:l.x-r.x,y:l.y-r.y)
	}

	public static func * (l:CGPoint, r:CGPoint) -> CGFloat
	{
		return l.x*r.x + l.y*r.y
	}

	public static func * (l:CGPoint, r:CGFloat) -> CGPoint
	{
		return CGPoint(x:l.x*r,y:l.y*r)
	}

	public static func * (l:CGFloat, r:CGPoint) -> CGPoint
	{
		return CGPoint(x:l*r.x,y:l*r.y)
	}

	public static func * (l:CGPoint, r:Double) -> CGPoint
	{
		return CGPoint(x:l.x*CGFloat(r),y:l.y*CGFloat(r))
	}

	public static func * (l:Double, r:CGPoint) -> CGPoint
	{
		return CGPoint(x:CGFloat(l)*r.x,y:CGFloat(l)*r.y)
	}

	public static func / (l:CGPoint, r:CGFloat) -> CGPoint
	{
		return CGPoint(x:l.x/r,y:l.y/r)
	}

	public static func / (l:CGPoint, r:Double) -> CGPoint
	{
		return CGPoint(x:l.x/CGFloat(r),y:l.y/CGFloat(r))
	}

	public static func += (l:inout CGPoint, r:CGPoint)
	{
		l = CGPoint(x:l.x+r.x,y:l.y+r.y)
	}

	public static func *= (l:inout CGPoint, r:CGFloat)
	{
		l = CGPoint(x:l.x*r,y:l.y*r)
	}

	public static func *= (l:inout CGPoint, r:Double)
	{
		l = CGPoint(x:l.x*CGFloat(r),y:l.y*CGFloat(r))
	}
	
	/// Returns the length of a vector
	
	public var length: CGFloat
	{
		return sqrt(self.x*self.x + self.y*self.y)
	}
	
	/// Normalized a vector to length 1.0, keeping is direction intact
	
	public var normalized:CGPoint
	{
		return self / self.length
	}
	
	/// Returns the mid point between to points
	
	public static func midPoint(between p1:CGPoint, and p2:CGPoint) -> CGPoint
	{
		return self.interpolate( between:p1, and:p2, factor:0.5)
	}

	/// Returns the mid point between to points
	
	public static func interpolate(between p1:CGPoint, and p2:CGPoint, factor:CGFloat) -> CGPoint
	{
		return CGPoint(
			x: (1.0-factor) * p1.x + factor * p2.x,
			y: (1.0-factor) * p1.y + factor * p2.y )
	}

	/// Returns a vector from a point to a point
	
	public static func vector(from:CGPoint,to:CGPoint) -> CGPoint
	{
		return CGPoint( x:to.x-from.x, y:to.y-from.y )
	}

	/// Returns the normal vector (perpendicular) to the vector stored in the receiver
	
	public var normal: CGPoint
	{
		return CGPoint( x: -self.y, y: self.x ).normalized
	}
}


//----------------------------------------------------------------------------------------------------------------------
