//
//  Dictionary+Concatenation.swift
//  BXSwiftUtils
//
//  Created by Peter Baumgartner on 20.02.20.
//  Copyright ©2020 IMAGINE GbR. All rights reserved.
//

import Foundation


extension Dictionary where Value : Any
{
	public static func +=(lhs: inout [Key:Value], rhs:[Key:Value])
	{
		rhs.forEach
		{
			lhs[$0] = $1
		}
	}
}
