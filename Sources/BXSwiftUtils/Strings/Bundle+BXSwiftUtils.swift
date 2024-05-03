//**********************************************************************************************************************
//
//  Bundle+BXSwiftUtils.swift
//	Returns the Bundle for this framework
//  Copyright ©2024 Peter Baumgartner. All rights reserved.
//
//**********************************************************************************************************************


import Foundation


//----------------------------------------------------------------------------------------------------------------------


public extension Bundle
{
	#if SWIFT_PACKAGE
	static let BXSwiftUtils = Bundle.module
	#else
	static let BXSwiftUtils = Bundle(for:BXSwiftUtilsMarker.self)
	#endif
}

fileprivate class BXSwiftUtilsMarker {}


//----------------------------------------------------------------------------------------------------------------------
