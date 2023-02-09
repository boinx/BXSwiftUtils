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
	/// Returns a (strongly typed) nested value inside a dictionary
	
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


	/// Returns an (untyped) nested value inside a dictionary

	public func untypedValue(for keyPath:String) -> Any?
	{
		guard var dict = self as? [String:Any] else { return nil }
		let keys = keyPath.components(separatedBy:".")

		var value:Any? = nil

		for key  in keys
		{
			value = dict[key]

			if let value = value as? [String:Value]
			{
				dict = value
			}
		}

		return value
	}
}
