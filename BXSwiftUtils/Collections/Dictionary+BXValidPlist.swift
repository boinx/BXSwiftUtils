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
				log.error {"\(#function): Value \(value) is not allowed in a plist!"}
				return false
			}
		}
		
		return true
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
				log.error {"\(#function): Value \(value) is not allowed in a plist!"}
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
				log.error {"\(#function): Value \(element) is not allowed in a plist!"}
				return false
			}
		}
		
		return true
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
				log.error {"\(#function): Value \(element) is not allowed in a plist!"}
				return false
			}
		}
		
		return true
	}
}


//----------------------------------------------------------------------------------------------------------------------
