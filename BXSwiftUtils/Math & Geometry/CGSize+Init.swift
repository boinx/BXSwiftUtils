//**********************************************************************************************************************
//
//  CGSize+Init.swift
//	Convenience init functions without the annoying argument labels
//  Copyright ©2020 Peter Baumgartner. All rights reserved.
//
//**********************************************************************************************************************


import Foundation
import CoreGraphics


//----------------------------------------------------------------------------------------------------------------------


public extension CGSize
{
	init(_ w:CGFloat,_ h:CGFloat)
	{
		self.init(width:w, height:h)
	}
	
	init(_ w:Double,_ h:Double)
	{
		self.init(width:CGFloat(w), height:CGFloat(h))
	}
	
	init(_ w:Int,_ h:Int)
	{
		self.init(width:CGFloat(w), height:CGFloat(h))
	}
}


//----------------------------------------------------------------------------------------------------------------------


public extension CGPoint
{
	init(_ x:CGFloat,_ y:CGFloat)
	{
		self.init(x:x, y:y)
	}

	init(_ x:Double,_ y:Double)
	{
		self.init(x:CGFloat(x), y:CGFloat(y))
	}

	init(_ x:Int,_ y:Int)
	{
		self.init(x:CGFloat(x), y:CGFloat(y))
	}
}


//----------------------------------------------------------------------------------------------------------------------
