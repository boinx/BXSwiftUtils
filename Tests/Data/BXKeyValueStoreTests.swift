//**********************************************************************************************************************
//
//  BXKeyValueStoreTests.swift
//	Verifies the UserDefaults conformance of BXKeyValueStore
//  Copyright ©2026 Peter Baumgartner. All rights reserved.
//
//**********************************************************************************************************************


import Testing
import Foundation
@testable import BXSwiftUtils


//----------------------------------------------------------------------------------------------------------------------


/// UserDefaults is the conformance that actually ships, so it is the one that has to be right.
///
/// Every test here works in its OWN suite domain, never `UserDefaults.standard` - the whole point of this protocol is
/// that code should stop reading and rewriting the preferences of whoever happens to run the tests, and a test suite
/// that did so itself would be a poor advertisement for it. The domain is removed at both ends of each test, so a
/// crashed run cannot leave state that makes the next one pass for the wrong reason.

@Suite("BXKeyValueStore")

struct BXKeyValueStoreTests
{
	/// Runs the body against a defaults domain that exists only for the duration of the test.

	static func withScratchStore(_ body:(UserDefaults) throws -> Void) rethrows
	{
		let name = "com.boinx.BXSwiftUtils.tests.\(UUID().uuidString)"

		UserDefaults.standard.removePersistentDomain(forName:name)
		defer { UserDefaults.standard.removePersistentDomain(forName:name) }

		guard let defaults = UserDefaults(suiteName:name) else
		{
			Issue.record("could not create the scratch domain \(name)")
			return
		}

		try body(defaults)
	}


//----------------------------------------------------------------------------------------------------------------------


	// MARK: - Round trips


	/// Each accessor stores and returns its own type. Nothing subtle, but it is the floor everything else stands on.

	@Test("Values survive a round trip")

	func testValuesRoundTrip()
	{
		Self.withScratchStore
		{
			store in

			store.setStringValue("hello", forKey:"s")
			store.setBoolValue(true, forKey:"b")
			store.setIntValue(42, forKey:"i")
			store.setDoubleValue(2.5, forKey:"d")

			#expect(store.stringValue(forKey:"s") == "hello")
			#expect(store.boolValue(forKey:"b") == true)
			#expect(store.intValue(forKey:"i") == 42)
			#expect(store.doubleValue(forKey:"d") == 2.5)
		}
	}


//----------------------------------------------------------------------------------------------------------------------


	// MARK: - Absence


	/// THE REASON THIS PROTOCOL EXISTS. UserDefaults answers 0, 0.0 and false for a key it has never seen, which no
	/// caller can tell apart from a stored zero - and that is not hypothetical here: an unregistered preference read
	/// as 0.0, was raised to a power, and produced a NaN that reached the data model.

	@Test("A key that was never written reads as nil")

	func testAbsentKeysAreNil()
	{
		Self.withScratchStore
		{
			store in

			#expect(store.stringValue(forKey:"missing") == nil)
			#expect(store.boolValue(forKey:"missing") == nil)
			#expect(store.intValue(forKey:"missing") == nil)
			#expect(store.doubleValue(forKey:"missing") == nil)
		}
	}


	/// The other half of the same claim, and the one that a naive implementation gets wrong: a value that IS stored
	/// and happens to be zero must not report as absent.

	@Test("A stored zero is not absence")

	func testStoredZeroIsNotAbsence()
	{
		Self.withScratchStore
		{
			store in

			store.setBoolValue(false, forKey:"b")
			store.setIntValue(0, forKey:"i")
			store.setDoubleValue(0.0, forKey:"d")

			#expect(store.boolValue(forKey:"b") == false)
			#expect(store.intValue(forKey:"i") == 0)
			#expect(store.doubleValue(forKey:"d") == 0.0)
		}
	}


	/// A REGISTERED default counts as present, because that is what the app actually relies on: registerDefaults is
	/// how a preference gets its intended starting value, and reporting it as absent would send every caller down
	/// its "never set" path on a fresh install.

	@Test("A registered default reads as present")

	func testRegisteredDefaultIsPresent()
	{
		Self.withScratchStore
		{
			store in

			store.register(defaults:["registered":1.02])

			#expect(store.doubleValue(forKey:"registered") == 1.02)
		}
	}


//----------------------------------------------------------------------------------------------------------------------


	// MARK: - Removal


	/// Setting nil forgets the value rather than storing a zero, so the key goes back to reading as absent.

	@Test("Setting nil removes the value", arguments:[0, 1, 2, 3])

	func testSettingNilRemoves(_ which:Int)
	{
		Self.withScratchStore
		{
			store in

			switch which
			{
				case 0:	store.setStringValue("x", forKey:"k") ; store.setStringValue(nil, forKey:"k")
				case 1:	store.setBoolValue(true, forKey:"k") ; store.setBoolValue(nil, forKey:"k")
				case 2:	store.setIntValue(7, forKey:"k") ; store.setIntValue(nil, forKey:"k")
				default: store.setDoubleValue(7.5, forKey:"k") ; store.setDoubleValue(nil, forKey:"k")
			}

			#expect(store.stringValue(forKey:"k") == nil)
			#expect(store.doubleValue(forKey:"k") == nil)
		}
	}


	/// removeValue does the same without having to name a type the caller may not know.

	@Test("removeValue forgets the value")

	func testRemoveValue()
	{
		Self.withScratchStore
		{
			store in

			store.setIntValue(7, forKey:"k")
			#expect(store.intValue(forKey:"k") == 7)

			store.removeValue(forKey:"k")
			#expect(store.intValue(forKey:"k") == nil)
		}
	}
}


//----------------------------------------------------------------------------------------------------------------------
