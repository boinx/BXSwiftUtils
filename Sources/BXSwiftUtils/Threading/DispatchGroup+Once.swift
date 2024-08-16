//**********************************************************************************************************************
//
//  DispatchGroup+Once.swift
//  Adds more notify methods to DispatchGroup
//  Copyright ©2018 Peter Baumgartner. All rights reserved.
//
//**********************************************************************************************************************


import Foundation


//----------------------------------------------------------------------------------------------------------------------


extension DispatchGroup
{
	/// Same as notify() except that the supplied worker block can fire only once, even if the group notifies multiple times.
	
    public func notifyOnce(qos: DispatchQoS = .default, flags: DispatchWorkItemFlags = [], queue: DispatchQueue, execute work: @escaping @convention(block) ()->Void)
	{
		// Wrap work item in an optional block
		
		var block:(()->Void)? =
		{
			work()
		}
		
		// Execute the wrapped block and then release nil it. That will release the wrapper block, and thus
		// also the work item. It can only be excuted once, even if the group notifies multiple times.
		
		self.notify(queue:queue)
		{
			block?()
			block = nil
		}
	}
	
	/// Returns true if this DispatchGroup is currently busy, i.e. not all enter() calls were balanced with leave() calls yet.
	
	public var isBusy:Bool
	{
		self.wait(timeout:.now()) == .timedOut
	}
}


//----------------------------------------------------------------------------------------------------------------------

