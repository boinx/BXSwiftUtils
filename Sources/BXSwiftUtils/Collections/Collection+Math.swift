//
//  Collection+Math.swift
//  BXSwiftUtils
//
//  Created by Peter Baumgartner on 21.11.23
//  Copyright ©2023 IMAGINE GbR. All rights reserved.
//


import Foundation


extension Collection where Element:FloatingPoint
{
    /// The sum of the elements in this Collection

    public func sum() -> Element
    {
		self.reduce(0,+)
    }

    /// The average of the elements in this Collection

    public func average() -> Element
    {
		let n = Element.init(count) 
		return self.sum() / n
    }
    
    
}
