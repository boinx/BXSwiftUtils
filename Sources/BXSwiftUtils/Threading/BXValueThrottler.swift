//**********************************************************************************************************************
//
//  BXValueThrottler.swift
//  Adds coalescing and throttling to GCD queues
//  Copyright ©2022 Peter Baumgartner. All rights reserved.
//
//**********************************************************************************************************************


import Combine
import Foundation


//----------------------------------------------------------------------------------------------------------------------


/// BXValueThrottler can be used to throttle high-frequency events down to an acceptable number, so that dependent
/// code is not overpowered.
///
/// An example are DragGestures in SwiftUI, which in turn can trigger re-layout of SwiftUI view hierarchies.
/// On some machines (e.g. M1 Macs) the dragging events come in such high frequency, that the triggered
/// re-layouting causes the app to go spinning beachball. Throttling the event stream avoids this problem.

@available(macOS 10.15, iOS 13, *) public class BXValueThrottler<V>
{
	private var interval: DispatchQueue.SchedulerTimeType.Stride
	private var onBegan: (()->Void)? = nil
	private var onChanged: ((V)->Void)? = nil
	private var onEnded: (()->Void)? = nil
	private var publisher: PassthroughSubject<V,Never>? = nil
	private var subscriber: Any? = nil


	/// Creates a new BXValueThrottler with value type V
	
	public init(interval:DispatchQueue.SchedulerTimeType.Stride = 0.016, onBegan:@escaping ()->Void, onChanged:@escaping (V)->Void, onEnded:@escaping ()->Void)
	{
		self.interval = interval
		self.onBegan = onBegan
		self.onChanged = onChanged
		self.onEnded = onEnded
		
		self.onBegan?()
		
		self.publisher = PassthroughSubject<V,Never>()
		
		self.subscriber = self.publisher?
			.throttle(for:interval, scheduler:DispatchQueue.main, latest:true)
			.sink(
				receiveCompletion:
				{
					_ in self.onEnded?()
				},
				receiveValue:
				{
					v in self.onChanged?(v)
				})
	}
	
	
	/// Sends a new value of type V
	
	public func send(_ value:V)
	{
		self.publisher?.send(value)
	}
	
	
	/// Completes the publisher and then cleans up
	
	public func finish()
	{
		self.publisher?.send(completion:.finished)
	}
}


//----------------------------------------------------------------------------------------------------------------------
