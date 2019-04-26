//**********************************************************************************************************************
//
//  BXMainThreadDelegate.swift
//  Guarantees that a delegate that conforms to this protocol is always called on the main thread
//  Copyright ©2019 Imagine GbR. All rights reserved.
//
//**********************************************************************************************************************


import Foundation


//----------------------------------------------------------------------------------------------------------------------


/// Any delegate protocol that conforms to this protocol gets the mixin capabilty to automatically dispatch
/// to the main thread (e.g. for UI work)

public protocol BXMainThreadDelegate : class
{

}


//----------------------------------------------------------------------------------------------------------------------


public extension BXMainThreadDelegate
{

	/// Call delegate method through this helper function to guarantee that they are always called on the main thread.
    /// ## Example
  	///		self.delegate?.onMainThread { $0.willStartUpload() }
	///		self.delegate?.onMainThread { $0.didFinishUpload(error:nil) }
	/// - parameter closure: The closure performs that actual delegate call. The argument $0 is the reference to the delegate itself.

    func onMainThread(_ closure: @escaping (Self)->Void)
    {
        if Thread.isMainThread
        {
            closure(self)
        }
        else
        {
            DispatchQueue.main.async
            {
                [weak self] in self?.onMainThread(closure)
            }
        }
    }
}


//----------------------------------------------------------------------------------------------------------------------
