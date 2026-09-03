//
//  URL+ExtendedAttributesTests.swift
//  BXSwiftUtils
//
//  Copyright © 2026 Boinx Software Ltd. & Imagine GbR. All rights reserved.
//

import Testing
import Foundation
@testable import BXSwiftUtils


//----------------------------------------------------------------------------------------------------------------------


/// Extended attributes are the one part of this framework that touches the real file system, so the interesting cases
/// are the ones where the file system says no: an attribute that is not there, a file that is not there, a name the
/// kernel will not accept.
///
/// Note the temporary file is UNIQUE PER TEST. The original suite shared one fixed path in NSTemporaryDirectory,
/// created in setUp and deleted in tearDown, which was safe only because XCTest ran the methods one at a time. Swift
/// Testing runs them in parallel, so a shared path would have them deleting each other's fixture.

@Suite("URL+ExtendedAttributes")

struct URL_ExtendedAttributesTests
{
	static let key = "com.boinx.test"


	/// Runs the body against a temporary file of its own, and removes it afterwards.

	static func withTemporaryFile(_ body:(URL) throws -> Void) rethrows
	{
		let url = URL(fileURLWithPath:NSTemporaryDirectory())
			.appendingPathComponent("BXSwiftUtils-xattr-\(UUID().uuidString)")

		FileManager.default.createFile(atPath:url.path, contents:Data("This is a test".utf8))

		defer { try? FileManager.default.removeItem(at:url) }

		try body(url)
	}


//----------------------------------------------------------------------------------------------------------------------


	// MARK: - Round trips


	/// Everything that goes through the generic overload is serialised as a property list, so the types that survive
	/// a round trip are exactly the plist types. Four near-identical tests in the original suite collapse into this.

	@Test("Property list values survive a round trip")

	func testPropertyListRoundTrip() throws
	{
		try Self.withTemporaryFile
		{
			url in

			try url.setExtendedAttribute("bar", forName:Self.key)
			#expect(url.extendedAttribute(forName:Self.key) == "bar")

			try url.setExtendedAttribute(42, forName:Self.key)
			#expect(url.extendedAttribute(forName:Self.key) == 42)

			try url.setExtendedAttribute(true, forName:Self.key)
			#expect(url.extendedAttribute(forName:Self.key) == true)

			try url.setExtendedAttribute(3.5, forName:Self.key)
			#expect(url.extendedAttribute(forName:Self.key) == 3.5)

			try url.setExtendedAttribute([1, 2, 3], forName:Self.key)
			#expect(url.extendedAttribute(forName:Self.key) == [1, 2, 3])

			try url.setExtendedAttribute(["a":1], forName:Self.key)
			#expect(url.extendedAttribute(forName:Self.key) == ["a":1])
		}
	}


	/// The value is read back in two steps - ask for the length, then read that many bytes - so anything longer than a
	/// stack sized buffer is the case worth checking. The original suite made this point with 93 characters; a
	/// kilobyte and a 64K value make it properly.

	@Test("Long values survive a round trip", arguments:[93, 1024, 65536])

	func testLongValueRoundTrip(_ length:Int) throws
	{
		try Self.withTemporaryFile
		{
			url in

			let value = String(repeating:"x", count:length)

			try url.setExtendedAttribute(value, forName:Self.key)

			let readBack:String? = url.extendedAttribute(forName:Self.key)

			#expect(readBack?.count == length)
			#expect(readBack == value)
		}
	}


	/// PINS A SPECIAL CASE. `Data` does NOT go through the property list, because the non-generic overload is more
	/// specific and wins - so its bytes are written verbatim.
	///
	/// It matters because it is not symmetrical with the rest: every other type gains a plist header, and Data does
	/// not, so bytes written by this API are readable by anything that knows the xattr name, and vice versa. Worth
	/// knowing before assuming the two overloads are interchangeable.

	@Test("Data is stored verbatim rather than as a property list")

	func testDataIsStoredVerbatim() throws
	{
		try Self.withTemporaryFile
		{
			url in

			let bytes = Data([0x18, 0x03, 0x19, 0x69])

			try url.setExtendedAttribute(bytes, forName:Self.key)

			let readBack = url.extendedAttribute(forName:Self.key)

			#expect(readBack == bytes)
			#expect(readBack?.count == 4, "a property list header would have made this longer")
		}
	}


	@Test("An empty value round trips")

	func testEmptyValue() throws
	{
		try Self.withTemporaryFile
		{
			url in

			try url.setExtendedAttribute(Data(), forName:Self.key)

			#expect(url.hasExtendedAttribute(forName:Self.key), "an empty attribute still exists")
			#expect(url.extendedAttribute(forName:Self.key) == Data())
		}
	}


	/// Reading a value back as the wrong type answers nil rather than trapping or returning something wrong - the
	/// generic accessor casts after deserialising, and a failed cast is simply no value.

	@Test("Reading with the wrong type gives nil")

	func testWrongTypeGivesNil() throws
	{
		try Self.withTemporaryFile
		{
			url in

			try url.setExtendedAttribute(42, forName:Self.key)

			let asString:String? = url.extendedAttribute(forName:Self.key)
			let asArray:[Int]? = url.extendedAttribute(forName:Self.key)

			#expect(asString == nil)
			#expect(asArray == nil)

			// ...while the right type still works, so the nils above are about the cast and nothing else

			let asInt:Int? = url.extendedAttribute(forName:Self.key)

			#expect(asInt == 42)
		}
	}


//----------------------------------------------------------------------------------------------------------------------


	// MARK: - Presence, listing and removal


	@Test("An attribute appears and disappears")

	func testPresence() throws
	{
		try Self.withTemporaryFile
		{
			url in

			#expect(!url.hasExtendedAttribute(forName:Self.key))
			#expect(!url.hasExtendedAttribute(forName:"com.boinx.unknown"))

			try url.setExtendedAttribute("bar", forName:Self.key)

			#expect(url.hasExtendedAttribute(forName:Self.key))

			try url.removeExtendedAttribute(forName:Self.key)

			#expect(!url.hasExtendedAttribute(forName:Self.key))
			#expect(url.extendedAttribute(forName:Self.key) == nil)
		}
	}


	/// `listExtendedAttributes` had NO coverage at all - not one of the original six tests called it, though it is the
	/// only way to discover what a file carries without knowing the names in advance.
	///
	/// Asserted by containment rather than equality: a file can pick up attributes that are nobody's business here
	/// (quarantine, provenance), and a test that demanded an exact list would fail for reasons unrelated to this code.

	@Test("The attribute list reflects what was set")

	func testListExtendedAttributes() throws
	{
		try Self.withTemporaryFile
		{
			url in

			let second = "com.boinx.test2"

			#expect(try !url.listExtendedAttributes().contains(Self.key))

			try url.setExtendedAttribute("one", forName:Self.key)
			try url.setExtendedAttribute("two", forName:second)

			let list = try url.listExtendedAttributes()

			#expect(list.contains(Self.key))
			#expect(list.contains(second))

			try url.removeExtendedAttribute(forName:Self.key)

			let shorter = try url.listExtendedAttributes()

			#expect(!shorter.contains(Self.key))
			#expect(shorter.contains(second), "removing one attribute took the other with it")
		}
	}


//----------------------------------------------------------------------------------------------------------------------


	// MARK: - When the file system says no


	/// Removing something that is not there THROWS, where reading it merely answers nil. Worth pinning because the two
	/// read like a pair and behave differently, and a caller tidying up attributes has to allow for it.

	@Test("Removing an attribute that is not there throws")

	func testRemovingMissingAttributeThrows() throws
	{
		Self.withTemporaryFile
		{
			url in

			#expect(url.extendedAttribute(forName:Self.key) == nil, "reading is quiet about it")

			var thrown:NSError? = nil

			do
			{
				try url.removeExtendedAttribute(forName:Self.key)
				Issue.record("removing a missing attribute should have thrown")
			}
			catch
			{
				thrown = error as NSError
			}

			#expect(thrown?.domain == NSPOSIXErrorDomain)
			#expect(thrown?.code == Int(ENOATTR), "expected ENOATTR, got \(thrown?.code ?? -1)")
		}
	}


	/// A file that does not exist fails the same way, through the same errno channel - so a caller can tell the two
	/// apart by the code and only by the code.

	@Test("Writing to a file that does not exist throws")

	func testMissingFileThrows()
	{
		let missing = URL(fileURLWithPath:NSTemporaryDirectory())
			.appendingPathComponent("BXSwiftUtils-does-not-exist-\(UUID().uuidString)")

		var thrown:NSError? = nil

		do
		{
			try missing.setExtendedAttribute("bar", forName:Self.key)
			Issue.record("writing to a missing file should have thrown")
		}
		catch
		{
			thrown = error as NSError
		}

		#expect(thrown?.domain == NSPOSIXErrorDomain)
		#expect(thrown?.code == Int(ENOENT), "expected ENOENT, got \(thrown?.code ?? -1)")
	}


	/// PINS CURRENT BEHAVIOR. The READ side has no error channel: `extendedAttribute(forName:)` swallows whatever the
	/// file system said and answers nil, so "there is no such attribute", "there is no such file" and "the disk is
	/// failing" are the same answer.
	///
	/// Same for `hasExtendedAttribute`, which reports false for a file that does not exist. Neither is wrong for the
	/// convenience these are meant to be - it is worth stating because the write side does the opposite, and code
	/// that reads before writing gets no warning from the reads.

	@Test("The read side reports a missing file as simply having no attribute")

	func testReadingAMissingFileIsQuiet()
	{
		let missing = URL(fileURLWithPath:NSTemporaryDirectory())
			.appendingPathComponent("BXSwiftUtils-does-not-exist-\(UUID().uuidString)")

		#expect(missing.extendedAttribute(forName:Self.key) == nil)
		#expect(!missing.hasExtendedAttribute(forName:Self.key))
	}


	/// The kernel limits an attribute NAME to 127 bytes, and the error arrives through the same channel as everything
	/// else rather than being caught earlier - so a caller building a name from user data needs to expect it.

	@Test("An over-long attribute name throws")

	func testOverLongNameThrows() throws
	{
		Self.withTemporaryFile
		{
			url in

			let tooLong = "com.boinx." + String(repeating:"x", count:200)

			var thrown:NSError? = nil

			do
			{
				try url.setExtendedAttribute("bar", forName:tooLong)
				Issue.record("an over-long name should have thrown")
			}
			catch
			{
				thrown = error as NSError
			}

			#expect(thrown?.domain == NSPOSIXErrorDomain)
			#expect(thrown?.code == Int(ENAMETOOLONG), "expected ENAMETOOLONG, got \(thrown?.code ?? -1)")
		}
	}
}


//----------------------------------------------------------------------------------------------------------------------
