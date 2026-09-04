//
//  Dictionary+EnumKeysTests.swift
//  BXSwiftUtils
//
//  Copyright © 2026 Boinx Software Ltd. & Imagine GbR. All rights reserved.
//

import Testing
import Foundation
@testable import BXSwiftUtils


//----------------------------------------------------------------------------------------------------------------------


/// Lets a string-backed enum be used as a dictionary key without spelling out `.rawValue`, either one key at a time
/// through a subscript or over a whole proxy dictionary through `using`.
///
/// The proxy is where the interesting behavior is: it is a COPY that gets written back, so what it does with entries
/// that were removed - and with keys that do not belong to the enum - is not something the call site can see.

@Suite("Dictionary+EnumKeys")

struct Dictionary_EnumKeysTests
{
	enum Key : String
	{
		case first = "stringKey1"
		case second = "stringKey2"
	}


	// MARK: - The subscript


	@Test("An enum key reads, writes and adds")

	func testSubscript()
	{
		var dictionary:[String:Int] = ["stringKey1":42]

		#expect(dictionary[Key.first] == 42)
		#expect(dictionary[Key.second] == nil, "a key that is not there reads as nil")

		dictionary[Key.first] = 23
		dictionary[Key.second] = 100

		#expect(dictionary == ["stringKey1":23, "stringKey2":100])
	}


	/// Assigning nil removes the entry, the same as with a plain String key - the subscript forwards to the real one
	/// rather than wrapping the value.

	@Test("Assigning nil through an enum key removes the entry")

	func testSubscriptRemoval()
	{
		var dictionary:[String:Int] = ["stringKey1":42, "stringKey2":7]

		dictionary[Key.first] = nil

		#expect(dictionary == ["stringKey2":7])
		#expect(dictionary[Key.first] == nil)
	}


//----------------------------------------------------------------------------------------------------------------------


	// MARK: - The proxy


	@Test("The proxy reads and writes through to the original")

	func testUsing()
	{
		var dictionary:[String:Int] = ["stringKey1":42]

		dictionary.using(Key.self)
		{
			proxy in

			#expect(proxy[.first] == 42)

			proxy[.first] = 23
			proxy[.second] = 100
		}

		#expect(dictionary == ["stringKey1":23, "stringKey2":100])
	}


	/// Keys the enum does not cover are LEFT ALONE rather than being dropped, which is what makes the proxy safe to
	/// use on a dictionary that holds more than one namespace.

	@Test("Keys outside the enum survive")

	func testForeignKeysSurvive()
	{
		var dictionary:[String:Int] = ["stringKey1":42, "somethingElse":7]

		dictionary.using(Key.self)
		{
			proxy in

			#expect(proxy.count == 1, "the proxy holds only the keys the enum covers")

			proxy[.first] = 23
		}

		#expect(dictionary == ["stringKey1":23, "somethingElse":7])
	}


	/// PINS A REAL ASYMMETRY. The proxy can ADD and CHANGE entries but cannot REMOVE them: the write-back loop copies
	/// what the proxy still holds and never deletes, so an entry the closure removed simply comes back.
	///
	/// Reachable the obvious way - `proxy[.first] = nil` reads exactly like the subscript above, which does remove -
	/// and silent, since the closure sees the removal happen. Nothing in the documentation mentions it.

	#warning("PINNED BEHAVIOR: Dictionary.using() cannot remove entries - a key deleted in the proxy is restored")

	@Test("An entry removed in the proxy comes back")

	func testProxyCannotRemove()
	{
		var dictionary:[String:Int] = ["stringKey1":42, "stringKey2":7]

		dictionary.using(Key.self)
		{
			proxy in

			proxy[.first] = nil

			#expect(proxy[.first] == nil, "the proxy itself really did remove it")
		}

		#expect(dictionary["stringKey1"] == 42, "the removal reached the original after all")
		#expect(dictionary == ["stringKey1":42, "stringKey2":7])
	}


	/// The closure is handed the proxy `inout`, so a closure that changes nothing leaves the dictionary untouched
	/// rather than rebuilding it - worth stating, since the write-back loop runs either way.

	@Test("A closure that changes nothing changes nothing")

	func testNoChanges()
	{
		var dictionary:[String:Int] = ["stringKey1":42, "somethingElse":7]
		let before = dictionary

		dictionary.using(Key.self) { _ in }

		#expect(dictionary == before)
	}
}


//----------------------------------------------------------------------------------------------------------------------
