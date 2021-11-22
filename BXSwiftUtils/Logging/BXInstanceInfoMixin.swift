//**********************************************************************************************************************
//
//  BXInstanceInfoMixin.swift
//	Provides info about class instances
//  Copyright ©2018 Peter Baumgartner. All rights reserved.
//
//**********************************************************************************************************************


public protocol BXInstanceInfoMixin : AnyObject
{
	/// Returns the class name for this object
	
	var instanceClassName: String { get }
	
	/// Returns the address for this object instance
	
	var instanceAddress: UnsafeMutableRawPointer { get }
	
	/// Returns a unique identifier string for this object instance
	
	var instanceIdentifier: String { get }
}


//----------------------------------------------------------------------------------------------------------------------


// Provide a shared mixin implementation that all Swift classes can use

extension BXInstanceInfoMixin
{
	public var instanceClassName: String
	{
		return String(describing:type(of:self))
	}

	public var instanceAddress: UnsafeMutableRawPointer
	{
		return Unmanaged.passUnretained(self).toOpaque()
	}
	
	public var instanceIdentifier: String
	{
		return "\(instanceClassName).\(instanceAddress)"
	}
}


//----------------------------------------------------------------------------------------------------------------------


