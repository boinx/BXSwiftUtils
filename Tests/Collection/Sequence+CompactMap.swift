//
//  Sequence+CompactMap.swift
//  BXSwiftUtils
//
//  Copyright © 2026 Boinx Software Ltd. & Imagine GbR. All rights reserved.
//

import Testing
import Foundation
@testable import BXSwiftUtils


//----------------------------------------------------------------------------------------------------------------------


/// The source file this suite belongs to is a SHIM for Swift 4.0, where `compactMap` did not yet exist: its entire
/// body sits inside `#if !swift(>=4.1)`, so on any compiler in use today it declares nothing at all.
///
/// The original test therefore exercised the standard library rather than BXSwiftUtils, and would have passed just as
/// well with the source file deleted. Both files can go; this one stays only until that is done, and asserts the fact
/// that makes the shim unnecessary.

#warning("DEAD CODE: Sequence+CompactMap.swift is empty on Swift 4.1+, and this suite tests the standard library")

@Suite("Sequence+CompactMap")

struct Sequence_CompactMapTests
{
	@Test("The standard library supplies compactMap, so the shim is not compiled")

	func testStandardLibraryCompactMap()
	{
		let input = [1, 2, 3, 4, 5, 6]

		let evens = input.compactMap { $0 % 2 == 0 ? $0 : nil }

		#expect(evens == [2, 4, 6])

		// The shim was declared for Sequence, and this is the behavior it was standing in for

		#expect(["1", "x", "3"].compactMap { Int($0) } == [1, 3])
		#expect(Set([1, 2]).compactMap { $0 }.count == 2)
	}
}


//----------------------------------------------------------------------------------------------------------------------
