//
//  Collection+UniqueValue.swift
//  BXSwiftUtils
//
//  Created by Peter Baumgartner on 24.07.19.
//  Copyright ©2023 IMAGINE GbR. All rights reserved.
//


import Foundation
import CoreGraphics
#if os(macOS)
import AppKit
#endif


extension Collection where Element:Equatable
{
	/// Returns the Element value if all items in the Collection have the SAME value
	
	public var uniqueValue:Element?
	{
		var uniqueValue:Element? = nil
		
		for value in self
		{
			if let uniqueValue = uniqueValue
			{
				if value != uniqueValue
				{
					return nil
				}
			}
			else
			{
				uniqueValue = value
			}
		}
		
		return uniqueValue
	}

	#if os(macOS)

	/// Return the state for a NSMenuItem indicating if all items in this Collection have the desired value
	
	public func state(for desiredValue:Element) -> NSControl.StateValue
	{
		if let uniqueValue = self.uniqueValue
		{
			return uniqueValue == desiredValue ? .on : .off
		}
		
		return .mixed
	}

	#endif
}
