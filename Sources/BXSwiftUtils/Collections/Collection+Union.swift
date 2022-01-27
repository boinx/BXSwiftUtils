//
//  Collection+Union.swift
//  BXSwiftUtils
//
//  Created by Peter Baumgartner on 24.07.19.
//  Copyright ©2019 IMAGINE GbR. All rights reserved.
//


import Foundation
import CoreGraphics


extension Collection where Element == CGRect
{

    /// Returns the bounds rect of all CGRects contained in this collection. If the collection is empty, then nil will be returned.

    public func boundingRect() -> CGRect?
    {
		var boundingRect: CGRect? = nil
		
		for rect in self
		{
			if boundingRect == nil
			{
				boundingRect = rect
			}
			else
			{
				boundingRect = boundingRect!.union(rect)
			}
		}
		
		return boundingRect
    }
}
