//**********************************************************************************************************************
//
//  NSObject+retain+release.swift
//	Lightweight wrapper class that provides closure based API around KVO
//  Copyright ©2022 Peter Baumgartner. All rights reserved.
//
//**********************************************************************************************************************


import Foundation


//----------------------------------------------------------------------------------------------------------------------


public extension NSObjectProtocol
{
	/// Same as retain(), which the compiler no longer lets us call:
	
	@discardableResult func manualRetain() -> Self
	{
		_ = Unmanaged.passRetained(self)
		return self
	}

	/// Same as release(), which the compiler no longer lets us call.
	
	@discardableResult func manualRelease() -> Self
	{
		Unmanaged.passUnretained(self).release()
		return self
	}

	/// Same as autorelease(), which the compiler no longer lets us call.
	
	@discardableResult func manualAutorelease() -> Self
	{
		_ = Unmanaged.passUnretained(self).autorelease()
		return self
	}
}


//----------------------------------------------------------------------------------------------------------------------
