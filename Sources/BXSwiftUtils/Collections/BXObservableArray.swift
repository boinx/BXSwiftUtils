//**********************************************************************************************************************
//
//  BXObservableArray.swift
//	Merges an array of ObservableObjects into a single ObservableObject, which can be used in SwiftUI
//  Copyright ©2025 Peter Baumgartner. All rights reserved.
//
//**********************************************************************************************************************


import Combine


//----------------------------------------------------------------------------------------------------------------------


//	The following code was inspired by ChatGPT. The central three lines of code are:
//
//	Let’s say array is [T] where T:ObservableObject.
//
//	1.  array.map { $0.objectWillChange }
//
//		This creates an array of publishers: [Publisher, Publisher, Publisher, ...] Each
//		objectWillChange is a Publisher<Void,Never> that emits just before any @Published
// 	 	property changes in its associated object.
//
//	2. .publisher
//
//		Turns the array into a Publishers.Sequence, a Combine publisher that emits each
//		element of the array (i.e., each objectWillChange) one by one.
//
//	3. .flatMap { $0 }
//
//		This flattens the nested publishers into a single stream, so whenever any of the
//		inner objectWillChange publishers emits, it bubbles through as a single event.
//		In effect: “When any object in the array emits objectWillChange, trigger this.”


//----------------------------------------------------------------------------------------------------------------------


///	This class wraps an array of ObservableObjects and is a ObservableObject itself.
///
///	Whenever any array element changes the wrapper class fires its objectWillChange publisher.

public class BXObservableArray<T:ObservableObject> : ObservableObject
{
	/// The array whose elements will be observed
	
    @Published public private(set) var array:[T]
    
    /// The optional debounce interval
	
	private var debounceInterval:TimeInterval? = nil
    
    /// The optional throttling interval
	
    private var throttleInterval:TimeInterval? = nil
    
    /// Internal housekeeping
	
    private var observer:Any? = nil


	/// Wraps an array of ObservableObjects into a single ObservableObject.
	///
	/// Whenever any array element fires its objectWillChange publisher, the wrapper will also fire its objectWillChange publisher. That
	/// way a SwiftUI view can be re-rendered when any object in an array changes any of its published properties.
	
    public init(_ array:[T], debounceInterval:TimeInterval? = nil, throttleInterval:TimeInterval? = nil)
    {
        self.array = array
        self.debounceInterval = debounceInterval
        self.throttleInterval = throttleInterval
        self.observeElements(of:array)
    }


    /// Call this method when the array itself changes, i.e. when elements have been added or removed.
	
    public func updateArray(_ array:[T])
    {
        self.array = array
        self.observeElements(of:array)
    }
    
    
    /// This function merges changes in in any array element into a single objectWillChange publisher
    
    private func observeElements(of array:[T])
    {
        // Merge all objectWillChange publishers into one
        
		let mergedChanges = array
			.map { $0.objectWillChange }
			.publisher
			.flatMap { $0 }

		// Apply optional debouncing
		
		if let debounceInterval = debounceInterval
		{
			self.observer = mergedChanges
				.debounce(for:.seconds(debounceInterval), scheduler:DispatchQueue.main)
				.sink
				{
					[weak self] _ in self?.objectWillChange.send() // Notify SwiftUI
				}
		}
		
		// Apply optional throttling
		
		else if let throttleInterval = throttleInterval
		{
			self.observer = mergedChanges
				.throttle(for:.seconds(throttleInterval), scheduler:DispatchQueue.main, latest: true)
				.sink
				{
					[weak self] _ in self?.objectWillChange.send() // Notify SwiftUI
				}
		}
		
		// Or use directly
		
		else
		{
			self.observer = mergedChanges
				.sink
				{
					[weak self] _ in self?.objectWillChange.send() // Notify SwiftUI
				}
		}
    }
}


//----------------------------------------------------------------------------------------------------------------------
