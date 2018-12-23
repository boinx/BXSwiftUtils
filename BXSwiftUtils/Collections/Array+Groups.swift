//
//  Array+Groups.swift
//  BXSwiftUtils
//
//  Created by Peter Baumgartner on 24.04.18.
//  Copyright ©2018 Imagine GbR. All rights reserved.
//

import Foundation


extension Array
{
	/// Groups an array into multiple chunks of specified size. The last chunk may contain fewer items.
	
    public func grouped(toSize size: Int) -> [[Element]]
    {
        return stride(from:0, to:count, by:size).map
        {
        	let i1 = $0
        	let i2 = Swift.min($0+size,self.count)
            return Array(self[i1 ..< i2])
        }
    }
}
