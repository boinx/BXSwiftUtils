//
//  Set+Concatenation.swift
//  BXSwiftUtils
//
//  Created by Peter Baumgartner on 20.03.20
//  Copyright ©2020 Imagine GbR. All rights reserved.
//

import Foundation


extension Set where Element : Hashable
{
	public static func +=(lhs:inout Set<Element>, rhs:Element)
	{
        lhs.insert(rhs)
	}

	public static func +=(lhs:inout Set<Element>, rhs:Set<Element>)
	{
		for element in rhs
		{
			lhs.insert(element)
		}
 	}
}
