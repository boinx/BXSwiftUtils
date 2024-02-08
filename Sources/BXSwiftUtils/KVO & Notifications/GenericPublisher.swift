//**********************************************************************************************************************
//
//  GenericPublisher.swift
//	Adds convenience APIs for Combine publishers
//  Copyright ©2022 Peter Baumgartner. All rights reserved.
//
//**********************************************************************************************************************


#if canImport(Combine)

import Combine


//----------------------------------------------------------------------------------------------------------------------


/// GenericPublisher can be used at the call site to trigger work based on a event stream

@available(macOS 10.15, iOS 13, tvOS 13, *)
public typealias GenericPublisher = PassthroughSubject<Void,Never>

@available(macOS 10.15, iOS 13, tvOS 13, *)
public extension GenericPublisher
{
	// These function with different sames (but identical functionality) are provide better readbility at the call site
	
	func send()
	{
		self.send(())
	}
	
	func request()
	{
		self.send()
	}
	
	func setNeedsUpdate()
	{
		self.send()
	}
}


//----------------------------------------------------------------------------------------------------------------------


#endif
