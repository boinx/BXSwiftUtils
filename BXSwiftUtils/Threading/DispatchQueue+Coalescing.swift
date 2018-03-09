//**********************************************************************************************************************
//
//  DispatchQueue+Coalescing.swift
//	Adds coalesced dispatching to DispatchQueue
//  Copyright ©2017-2018 Peter Baumgartner. All rights reserved.
//
//**********************************************************************************************************************


import Foundation


//----------------------------------------------------------------------------------------------------------------------


public extension DispatchQueue
{
	/// asyncCoalesced() is similar to async(), but offers additional funtionality: If multiple blocks are submitted
	/// within a given time internal, only the last one will be executed. Please note that this method should only
	/// be called from the main thread.
	/// - parameter identifier: The identifier string that is used to coalesce multiple blocks together
	/// - parameter delay: The time interval (in seconds)
	/// - parameter block: The worker block (closure) to be submitted

	public func asyncCoalesced( identifier: String, delay: Double=0.0, block: @escaping ()->Void)
	{
		if Thread.isMainThread
		{
			let newItem = DispatchWorkItem
			{
				block()
				workItems[identifier] = nil
			}
			
			let oldItem = workItems[identifier]
			oldItem?.cancel()
			workItems[identifier] = newItem

			self.asyncAfter(deadline:.now()+delay,execute:newItem)
		}
		else
		{
			let stacktrace = Thread.callStackSymbols.joined(separator:"\n")
            // TODO: This line currently doesn't compile because log can't be found
			//log.error { "ERROR DispatchQueue.\(#function) must be called from the main thread! Offending stack trace is:\n\n\(stacktrace)\n" }
		}
	}
}

/// This lookup map dictionary stores the last submitted worker block for a given identifier string

private var workItems:[String:DispatchWorkItem] = [:]



//----------------------------------------------------------------------------------------------------------------------
