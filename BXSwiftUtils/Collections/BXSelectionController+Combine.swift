//**********************************************************************************************************************
//
//  BXSelectionController.swift
//	Adds SwiftUI support when running on modern systems
//  Copyright ©2020 Peter Baumgartner. All rights reserved.
//
//**********************************************************************************************************************


import Foundation

#if canImport(Combine)
import Combine


//----------------------------------------------------------------------------------------------------------------------


// Add support for Combine publishers when running on modern OS versions

@available(macOS 10.15.2, iOS 13.2, *) extension BXSelectionController : ObservableObject
{

}


//----------------------------------------------------------------------------------------------------------------------


public extension BXSelectionController
{
	// This function calls send on the objectWillChange publisher so that SwiftUI can rebuild its views.
	// On older system this function does nothing.
	
	func publishObjectWillChange()
	{
		if #available(macOS 10.15.2, iOS 13.2, *)
		{
			if shouldPublishObjectWillChange
			{
				self.objectWillChange.send()
			}
		}
	}

	/// A Combine publisher that broadcasts selection changes
	
	@available(macOS 10.15.2, iOS 13.2, *) var selectionDidChange : NotificationCenter.Publisher
	{
		NotificationCenter.default.publisher(for: Self.selectionDidChangeNotification, object:self)
	}
}


//----------------------------------------------------------------------------------------------------------------------


#else

public extension BXSelectionController
{
	@objc open func publishObjectWillChange()
	{
		// empty function needed for compiling on macOS 10.13
	}
}

#endif


//----------------------------------------------------------------------------------------------------------------------
