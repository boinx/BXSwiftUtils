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
	init(from:CGPoint, to:CGPoint)
	{
		let x = min(from.x,to.x)
		let y = min(from.y,to.y)
		let w = abs(from.x-to.x)
		let h = abs(from.y-to.y)
		self.init(x:x, y:y, width:w, height:h)
	}
	
	/// Returns the center point of a CGRect
	
	var center: CGPoint
	{
		return CGPoint( x:self.midX, y:self.midY )
	}

	/// Returns the left point of a CGRect
	
	var left: CGPoint
	{
		return CGPoint( x:self.minX, y:self.midY )
	}

	/// Returns the bottom point of a CGRect
	
	var right: CGPoint
	{
		return CGPoint( x:self.maxX, y:self.midY )
	}

	/// Returns the top point of a CGRect
	
	var top: CGPoint
	{
		return CGPoint( x:self.midX, y:self.maxY )
	}

	/// Returns the bottom point of a CGRect
	
	var bottom: CGPoint
	{
		return CGPoint( x:self.midX, y:self.minY )
	}

	/// Returns the top left point of a CGRect
	
	var topLeft: CGPoint
	{
		return CGPoint( x:self.minX, y:self.maxY )
	}

	/// Returns the top right point of a CGRect
	
	var topRight: CGPoint
	{
		return CGPoint( x:self.maxX, y:self.maxY )
	}

	/// Returns the bottom left point of a CGRect
	
	var bottomLeft: CGPoint
	{
		return CGPoint( x:self.minX, y:self.minY )
	}

	/// Returns the bottom right point of a CGRect
	
	var bottomRight: CGPoint
	{
		return CGPoint( x:self.maxX, y:self.minY )
	}

	/// Returns the length of the shorter edge
	
	var shorterEdge: CGFloat
	{
		return min( self.width, self.height )
	}
	
	/// Returns the length of the longer edge
	
	var longerEdge: CGFloat
	{
		return max( self.width, self.height )
	}
	
	/// Returns the length of the diagonal
	
	var diagonal: CGFloat
	{
		let w = self.width
		let h = self.height
		return sqrt(w*w + h*h)
	}
	
	/// Returns the area of this CGRect
	
	var area:CGFloat
	{
		self.width * self.height
	}
	
	/// Returns the aspect ratio of this CGRect
	
	var aspectRatio:CGFloat
	{
		self.width / self.height
	}
	
	/// Scales a rectangle so that its longer edge has the specified length. This preserves the aspect ratio of the rect.
	/// - parameter maxEdge: The length of the longer edge after scaling
	/// - returns: The scaled CGRect
	
	func scale(to maxEdge:CGFloat) -> CGRect
	{
		let fx = maxEdge / self.width
		let fy = maxEdge / self.height
		let f = min(fx,fy)
		
		var rect = self
		rect.origin.x *= f		// Not sure if we should
		rect.origin.y *= f		// scale the origin too?
		rect.size.width *= f
		rect.size.height *= f
		return rect
	}
	
	/// Similar to insetBy(dx:,dy:) except that it doesn't produce bogus Inf or NaN values if the insets are too large for the CGRect
	
	func safeInsetBy(dx:CGFloat, dy:CGFloat) -> CGRect
	{
		var rect = self
		
		if rect.width > 2*dx
		{
			rect.origin.x += dx
			rect.size.width -= 2*dx
		}
		else
		{
			rect.origin.x = self.midX
			rect.size.width = 0.0
		}
		
		if rect.height > 2*dy
		{
			rect.origin.y += dy
			rect.size.height -= 2*dy
		}
		else
		{
			rect.origin.y = self.midY
			rect.size.height = 0.0
		}
		
		return rect
	}
	
	/// Return false if any of the CGRect values contain invalid values like NaN or Inf
	
	var isValid:Bool
	{
		if self.origin.x.isInfinite || self.origin.x.isNaN || self.origin.x.isSignalingNaN { return false }
		if self.origin.y.isInfinite || self.origin.y.isNaN || self.origin.y.isSignalingNaN { return false }
		if self.size.width.isInfinite || self.size.width.isNaN || self.size.width.isSignalingNaN { return false }
		if self.size.height.isInfinite || self.size.height.isNaN || self.size.height.isSignalingNaN { return false }
		return true
	}
	
	/// Returns the bounds of a rect that has been rotated by the specified angle (in radians)
	
	func rotatedBounds(by radians:CGFloat) -> CGRect
	{
		// Get the 4 corner points and rotate them
		
		let center = self.center
		let p1 = center + (self.bottomLeft-center).rotated(by:radians)
		let p2 = center + (self.bottomRight-center).rotated(by:radians)
		let p3 = center + (self.topLeft-center).rotated(by:radians)
		let p4 = center + (self.topRight-center).rotated(by:radians)
		
		// Find horizontal range
		
		let xlist = [p1.x,p2.x,p3.x,p4.x]
		let xmin = xlist.min() ?? 0.0
		let xmax = xlist.max() ?? 0.0
		let dx = abs(xmax-xmin)

		// Find vertical range
		
		let ylist = [p1.y,p2.y,p3.y,p4.y]
		let ymin = ylist.min() ?? 0.0
		let ymax = ylist.max() ?? 0.0
		let dy = abs(ymax-ymin)
		
		return CGRect(x:xmin, y:ymin, width:dx, height:dy)
	}
}


//----------------------------------------------------------------------------------------------------------------------


extension Array where Element==CGRect
{
	/// Returns the union of an Array of CGRects
	
	public var union:CGRect
	{
		var result:CGRect? = nil
		
		for rect in self
		{
			if let r = result
			{
				result = r.union(rect)
			}
			else
			{
				result = rect
			}
		}
		
		return result ?? .zero
	}
}


//----------------------------------------------------------------------------------------------------------------------
