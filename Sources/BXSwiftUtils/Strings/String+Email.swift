//**********************************************************************************************************************
//
//  String+Email.swift
//	Chekc for valid email address
//  Copyright ©2025 Peter Baumgartner. All rights reserved.
//
//**********************************************************************************************************************


import Foundation


//----------------------------------------------------------------------------------------------------------------------


extension String
{
	/// Returns true if this String contains a valid email address
	
	public var isValidEmailAddress:Bool
	{
        // A commonly used, reasonably permissive email regex (provided by ChatGPT)
        
        let pattern = #"^[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}$"#
        let predicate = NSPredicate(format:"SELF MATCHES[c] %@", pattern)
        
        return predicate.evaluate(with:self)
    }
}


//----------------------------------------------------------------------------------------------------------------------
