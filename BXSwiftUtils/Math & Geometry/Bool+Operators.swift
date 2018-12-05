//
//  Operators.swift
//  BXSwiftUtils
//
//  Created by Benjamin Federer on 05.12.18.
//  Copyright © 2018 Boinx Software Ltd. & Imagine GbR. All rights reserved.
//

import Foundation

infix operator ||= : AssignmentPrecedence
infix operator &&= : AssignmentPrecedence

extension Bool
{
	public static func ||= (lhs: inout Bool, rhs: @autoclosure () throws -> Bool) rethrows
	{
		if (!lhs)
		{
			lhs = try rhs()
		}
	}
	
	public static func &&= (lhs: inout Bool, rhs: @autoclosure () throws -> Bool) rethrows
	{
		if (lhs)
		{
			lhs = try rhs()
		}
	}
}
