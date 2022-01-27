//
//  Dictionary+Accessors.swift
//  BXSwiftUtils
//
//  Created by Peter Baumgartner on 01.08.21.
//  Copyright ©2021 IMAGINE GbR. All rights reserved.
//

import Foundation


extension Dictionary where Key: StringProtocol
{
	public func value<T>(forKeyPath keyPath:String) -> T?
	{
		guard var dict = self as? [String:Any] else { return nil }
		
		for key in keyPath.components(separatedBy:".")
		{
			if let value = dict[key] as? T
			{
				return value
			}
			else if let subdict = dict[key] as? [String:Any]
			{
				dict = subdict
			}
		}
		
		return nil
	}
}
