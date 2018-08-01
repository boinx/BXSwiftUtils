//**********************************************************************************************************************
//
//  CGRect+FMExtensions.swift
//	Adds convenience methods
//  Copyright ©2016-2018 Peter Baumgartner. All rights reserved.
//
//**********************************************************************************************************************


import Foundation
import CoreGraphics


//----------------------------------------------------------------------------------------------------------------------


/// This extension adds convenience accessors to NSRect

public extension CGRect
{
	/// Returns the center point of a CGRect
	
	public var center: CGPoint
	{
		return CGPoint( x:self.midX, y:self.midY )
	}

	/// Returns the left point of a CGRect
	
	public var left: CGPoint
	{
		return CGPoint( x:self.minX, y:self.midY )
	}

	/// Returns the bottom point of a CGRect
	
	public var right: CGPoint
	{
		return CGPoint( x:self.maxX, y:self.midY )
	}

	/// Returns the top point of a CGRect
	
	public var top: CGPoint
	{
		return CGPoint( x:self.midX, y:self.maxY )
	}

	/// Returns the bottom point of a CGRect
	
	public var bottom: CGPoint
	{
		return CGPoint( x:self.midX, y:self.minY )
	}

	/// Returns the top left point of a CGRect
	
	public var topLeft: CGPoint
	{
		return CGPoint( x:self.minX, y:self.maxY )
	}

	/// Returns the top right point of a CGRect
	
	public var topRight: CGPoint
	{
		return CGPoint( x:self.maxX, y:self.maxY )
	}

	/// Returns the bottom left point of a CGRect
	
	public var bottomLeft: CGPoint
	{
		return CGPoint( x:self.minX, y:self.minY )
	}

	/// Returns the bottom right point of a CGRect
	
	public var bottomRight: CGPoint
	{
		return CGPoint( x:self.maxX, y:self.minY )
	}

	/// Returns the length of the shorter edge
	
	public var shorterEdge: CGFloat
	{
		return min( self.width, self.height )
	}
	
	/// Returns the length of the longer edge
	
	public var longerEdge: CGFloat
	{
		return max( self.width, self.height )
	}
	
	/// Returns the length of the diagonal
	
	public var diagonal: CGFloat
	{
		let w = self.width
		let h = self.height
		return sqrt(w*w + h*h)
	}
}


//----------------------------------------------------------------------------------------------------------------------
