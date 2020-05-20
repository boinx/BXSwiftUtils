//**********************************************************************************************************************
//
//  NSObject+onChanged.swift
//	Adds convenience API for KVO Combine publishers
//  Copyright ©2020 Peter Baumgartner. All rights reserved.
//
//**********************************************************************************************************************


import Foundation

#if canImport(Combine)
import Combine
#endif


//----------------------------------------------------------------------------------------------------------------------


#if canImport(Combine)

extension NSObjectProtocol where Self:NSObject
{
	/// Convenience API for creating a Combine publisher based KVO observer.
	///
	/// 	self.observers += object.onChanged(\.name)
	///		{
	///		    newName in
	///		    // Do something
	///		}
	///
	/// - parameter keypath: Keypath to the property that is being observed
	/// - parameter options: The KVO oberservation options (default is .new)
	/// - parameter handler: The closure that is called when the value changes
	/// - returns: A token that should be retained. Release this token to deactivate the KVO observer.
	
	@available(macOS 10.15.2, iOS 13.2, *)

	public func onChanged<Value>(_ keypath:KeyPath<Self,Value>, options:NSKeyValueObservingOptions = .new, handler: @escaping ((Value)->Void)) -> AnyCancellable?
	{
		return self.publisher(for:keypath, options:options).sink(receiveValue:handler)
	}
}

//publisher<Value>(for keyPath: KeyPath<FMTransitionObject, Value>, options: NSKeyValueObservingOptions = [.initial, .new]) -> NSObject.KeyValueObservingPublisher<FMTransitionObject, Value>


#endif


//----------------------------------------------------------------------------------------------------------------------


