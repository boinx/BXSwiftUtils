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
	
	@available(macOS 10.15.2, iOS 13.2, tvOS 13.0, *)

	public func onChanged<Value>(_ keypath:KeyPath<Self,Value>, options:NSKeyValueObservingOptions = .new, handler: @escaping ((Value)->Void)) -> AnyCancellable?
	{
		return self.publisher(for:keypath, options:options)
			.sink(receiveValue:handler)
	}


	/// Convenience API for creating a Combine publisher based KVO observer.
	///
	/// 	self.observers += object.onChanged(\.fileURL)
	///		{
	///		    newName in
	///		    // Do something
	///		}
	///
	/// - parameter keypath: Keypath to an optional property that is being observed
	/// - parameter options: The KVO oberservation options (default is .new)
	/// - parameter handler: The closure that is called when the value changes
	/// - returns: A token that should be retained. Release this token to deactivate the KVO observer.
	
	@available(macOS 10.15.2, iOS 13.2, tvOS 13.0, *)

	public func onChanged<Value>(_ keypath:KeyPath<Self,Value?>, options:NSKeyValueObservingOptions = .new, handler: @escaping ((Value?)->Void)) -> AnyCancellable?
	{
		return self.publisher(for:keypath, options:options)
			.sink(receiveValue:handler)
	}


//----------------------------------------------------------------------------------------------------------------------


	@available(macOS 10.15.2, iOS 13.2, tvOS 13.0, *)

	public func onChanged<Value:Equatable>(_ keypath:KeyPath<Self,Value>, options:NSKeyValueObservingOptions = .new, throttle interval:DispatchQueue.SchedulerTimeType.Stride, handler: @escaping ((Value)->Void)) -> AnyCancellable?
	{
		return self.publisher(for:keypath, options:options)
			.removeDuplicates { $0 == $1 }
			.throttle(for:interval, scheduler:DispatchQueue.main, latest:true)
			.sink(receiveValue:handler)
	}


	@available(macOS 10.15.2, iOS 13.2, tvOS 13.0, *)

	public func onChanged<Value:Equatable>(_ keypath:KeyPath<Self,Value?>, options:NSKeyValueObservingOptions = .new, throttle interval:DispatchQueue.SchedulerTimeType.Stride, handler: @escaping ((Value?)->Void)) -> AnyCancellable?
	{
		return self.publisher(for:keypath, options:options)
			.removeDuplicates { $0 == $1 }
			.throttle(for:interval, scheduler:DispatchQueue.main, latest:true)
			.sink(receiveValue:handler)
	}


//----------------------------------------------------------------------------------------------------------------------


	@available(macOS 10.15.2, iOS 13.2, tvOS 13.0, *)

	public func onChanged<Value:Equatable>(_ keypath:KeyPath<Self,Value>, options:NSKeyValueObservingOptions = .new, debounce interval:DispatchQueue.SchedulerTimeType.Stride, handler: @escaping ((Value)->Void)) -> AnyCancellable?
	{
		return self.publisher(for:keypath, options:options)
			.removeDuplicates { $0 == $1 }
			.debounce(for:interval, scheduler:DispatchQueue.main)
			.sink(receiveValue:handler)
	}


	@available(macOS 10.15.2, iOS 13.2, tvOS 13.0, *)

	public func onChanged<Value:Equatable>(_ keypath:KeyPath<Self,Value?>, options:NSKeyValueObservingOptions = .new, debounce interval:DispatchQueue.SchedulerTimeType.Stride, handler: @escaping ((Value?)->Void)) -> AnyCancellable?
	{
		return self.publisher(for:keypath, options:options)
			.removeDuplicates { $0 == $1 }
			.debounce(for:interval, scheduler:DispatchQueue.main)
			.sink(receiveValue:handler)
	}

}


#endif


//----------------------------------------------------------------------------------------------------------------------


