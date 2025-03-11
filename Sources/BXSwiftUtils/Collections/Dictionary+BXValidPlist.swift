//
//  Dictionary+BXValidPlist.swift
//  BXSwiftUtils
//
//  Created by Peter Baumgartner on 21.09.20.
//  Copyright ©2020 IMAGINE GbR. All rights reserved.
//


//----------------------------------------------------------------------------------------------------------------------


import Foundation
#if os(iOS)
import CoreGraphics // for CGFloat
#endif


//----------------------------------------------------------------------------------------------------------------------


public protocol BXValidPlist
{
	/// Returns true if the receiver represents a valid property list
	
	var isValidPlist:Bool { get }
}


//----------------------------------------------------------------------------------------------------------------------


// MARK: -

// Primitive Swift data types

extension String : BXValidPlist
{
	public var isValidPlist:Bool { true }
}

extension Bool : BXValidPlist
{
	public var isValidPlist:Bool { true }
}

extension Int : BXValidPlist
{
	public var isValidPlist:Bool { true }
}

extension Float : BXValidPlist
{
	public var isValidPlist:Bool { true }
}

extension CGFloat : BXValidPlist
{
	public var isValidPlist:Bool { true }
}

extension Double : BXValidPlist
{
	public var isValidPlist:Bool { true }
}

extension Date : BXValidPlist
{
	public var isValidPlist:Bool { true }
}

extension Data : BXValidPlist
{
	public var isValidPlist:Bool { true }
}


//----------------------------------------------------------------------------------------------------------------------


// MARK: -

// Primitive Foundation data types

extension NSString : BXValidPlist
{
	public var isValidPlist:Bool { true }
}

extension NSNumber : BXValidPlist
{
	public var isValidPlist:Bool { true }
}

extension NSDate : BXValidPlist
{
	public var isValidPlist:Bool { true }
}

extension NSData : BXValidPlist
{
	public var isValidPlist:Bool { true }
}


//----------------------------------------------------------------------------------------------------------------------


// MARK: -

// Compound data types

extension Dictionary : BXValidPlist
{
	public var isValidPlist:Bool
	{
		for (key,value) in self
		{
			if !(key is String)
			{
				log.error {"\(#function): Key \(key) is not a string!"}
				return false
			}
			
			if let value = value as? BXValidPlist
			{
				if !value.isValidPlist { return false }
			}
			else
			{
				log.error {"\(#function): Value \(value) (in dictionary for key \(key)) is not allowed in a plist!"}
				return false
			}
		}
		
		return true
	}
	
	public func validatedPlist() -> [String:Any] where Key==String, Value:Any
	{
		var plist:[String:Any] = self
		
		for (key,value) in plist
		{
			if let subdict = value as? [String:Any]
			{
				plist[key] = subdict.validatedPlist()
			}
			else if let subarray = value as? [Any]
			{
				plist[key] = subarray.validatedPlist()
			}
			else if let value = value as? BXValidPlist
			{
				if !value.isValidPlist { plist.removeValue(forKey:key) }
			}
			else
			{
				plist.removeValue(forKey:key)
			}
		}
		
		return plist
	}
}


extension NSDictionary : BXValidPlist
{
	public var isValidPlist:Bool
	{
		for (key,value) in self
		{
			if !(key is String)
			{
				log.error {"\(#function): Key \(key) is not a string!"}
				return false
			}
			
			if let value = value as? BXValidPlist
			{
				if !value.isValidPlist { return false }
			}
			else
			{
				log.error {"\(#function): Value \(value)  (in dictionary for key \(key)) is not allowed in a plist!"}
				return false
			}
		}
		
		return true
	}
}


extension Array : BXValidPlist
{
	public var isValidPlist:Bool
	{
		for element in self
		{
			if let value = element as? BXValidPlist
			{
				if !value.isValidPlist { return false }
			}
			else
			{
				log.error {"\(#function): Value \(element) (in array) is not allowed in a plist!"}
				return false
			}
		}
		
		return true
	}

	public func validatedPlist() -> [Any] where Element:Any
	{
		var plist:[Any] = self
		
		for (i,value) in plist.enumerated()
		{
			if let subdict = value as? [String:Any]
			{
				plist[i] = subdict.validatedPlist()
			}
			else if let subarray = value as? [Any]
			{
				plist[i] = subarray.validatedPlist()
			}
			else if let value = value as? BXValidPlist
			{
				if !value.isValidPlist { plist.remove(at:i) }
			}
			else
			{
				plist.remove(at:i)
			}
		}
		
		return plist
	}
}


extension NSArray : BXValidPlist
{
	public var isValidPlist:Bool
	{
		for element in self
		{
			if let value = element as? BXValidPlist
			{
				if !value.isValidPlist { return false }
			}
			else
			{
				log.error {"\(#function): Value \(element) (in array) is not allowed in a plist!"}
				return false
			}
		}
		
		return true
	}
}


//----------------------------------------------------------------------------------------------------------------------
