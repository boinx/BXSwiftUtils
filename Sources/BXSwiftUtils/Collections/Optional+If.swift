//
//  Optional+If.swift
//  BXSwiftUtils
//
//  Created by PeterBaumgartner on 08.10.18.
//  Copyright © 2018 Boinx Software Ltd. & Imagine GbR. All rights reserved.
//

import Foundation

extension Optional
{

	/// Provides an alternate name for the flatMap function - so that the code reads more natural at the call site. The closure is executed if the optional is non-nil.
	///
	///	## Example
	/// 	self.someOptionalProperty.if { self.doSomethingWith($0) }
	///
	/// - parameter closure: This closure is executed only if the Optional is non-nil. The unwrapped value is passed as an argument.

    public func `if`<U>(_ closure: (Wrapped) throws -> U?) rethrows -> U?
    {
        return try self.flatMap(closure)
    }
    
}
