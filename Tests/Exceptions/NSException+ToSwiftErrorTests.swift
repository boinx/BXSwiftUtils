//
//  NSException+ToSwiftErrorTests.swift
//  BXSwiftUtils
//
//  Copyright © 2026 Boinx Software Ltd. & Imagine GbR. All rights reserved.
//

import Testing
import Foundation
@testable import BXSwiftUtils


//----------------------------------------------------------------------------------------------------------------------


/// Objective-C exceptions are not Swift errors and cannot be caught by `do`/`catch` - an uncaught one terminates the
/// process. These two helpers bridge them, which matters wherever Swift calls into an AppKit or Foundation API that
/// still raises: an out of range NSArray access, a KVO registration for a key that does not exist.

@Suite("NSException+ToSwiftError")

struct NSException_ToSwiftErrorTests
{
	@Test("A raised exception becomes a Swift error")

	func testExceptionBecomesAnError()
	{
		#expect(throws:(any Error).self)
		{
			try NSException.toSwiftError
			{
				NSArray().object(at:1)			// out of range, raises NSRangeException
			}
		}
	}


	/// The error carries the exception's own name and reason, which is the only way a caller can tell WHAT went
	/// wrong - a bridged exception that arrived as an anonymous error would be no better than a crash report.

	@Test("The error describes the exception")

	func testErrorDescribesTheException()
	{
		var caught:NSError? = nil

		do
		{
			try NSException.toSwiftError { NSArray().object(at:1) }
		}
		catch
		{
			caught = error as NSError
		}

		let description = caught?.localizedDescription ?? ""

		#expect(caught != nil)
		#expect(!description.isEmpty, "the bridged error says nothing about what was raised")
	}


	/// A block that raises nothing returns normally, so wrapping a call site costs nothing when it behaves.

	@Test("A block that does not raise simply returns")

	func testNoException() throws
	{
		var ran = false

		try NSException.toSwiftError { ran = true }

		#expect(ran)
	}


	/// `NSException.catch` is the newer entry point and takes a THROWING block, so it bridges both kinds of failure -
	/// an Objective-C exception and an ordinary Swift error - through one `catch`. The older helper cannot: its block
	/// is non-throwing, so a Swift error has nowhere to go.

	@Test("catch bridges Swift errors as well as exceptions")

	func testCatchBridgesBothKinds()
	{
		struct Failure : Error {}

		#expect(throws:Failure.self)
		{
			try NSException.catch { throw Failure() }
		}

		#expect(throws:(any Error).self)
		{
			try NSException.catch { NSArray().object(at:1) }
		}

		#expect(throws:Never.self)
		{
			try NSException.catch { }
		}
	}
}


//----------------------------------------------------------------------------------------------------------------------
