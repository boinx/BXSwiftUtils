//
//  ClosedRange+SafeInit.swift
//  BXSwiftUtils-macOS
//
//  Created by Peter Baumgartner on 22.08.23.
//  Copyright ©2023 IMAGINE GbR. All rights reserved.
//


extension ClosedRange
{
	public init(safe a:Bound,_ b:Bound)
    {
		let lower = Swift.min(a,b)
		let upper = Swift.max(a,b)
		self.init(uncheckedBounds:(lower,upper))
    }
}
