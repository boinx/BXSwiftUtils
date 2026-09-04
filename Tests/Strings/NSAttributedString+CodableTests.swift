//
//  NSAttributedString+CodableTests.swift
//  BXSwiftUtils
//
//  Copyright © 2026 Boinx Software Ltd. & Imagine GbR. All rights reserved.
//

import Testing
import Foundation
import AppKit
@testable import BXSwiftUtils


//----------------------------------------------------------------------------------------------------------------------


fileprivate struct Container : Codable
{
	var string:NSAttributedString

	init(_ string:NSAttributedString) { self.string = string }

	enum CodingKeys : String, CodingKey { case string }

	init(from decoder:Decoder) throws
	{
		let container = try decoder.container(keyedBy:CodingKeys.self)
		self.string = try container.decode(NSAttributedString.self, forKey:.string)
	}
}


fileprivate struct OptionalContainer : Codable
{
	var string:NSAttributedString?

	init(_ string:NSAttributedString?) { self.string = string }

	enum CodingKeys : String, CodingKey { case string }

	init(from decoder:Decoder) throws
	{
		let container = try decoder.container(keyedBy:CodingKeys.self)
		self.string = try container.decodeIfPresent(NSAttributedString.self, forKey:.string)
	}
}


//----------------------------------------------------------------------------------------------------------------------


/// NSAttributedString cannot be made Decodable - the required initializer cannot be added in an extension - so
/// decoding is patched onto `KeyedDecodingContainer` instead. The asymmetry is the interesting part: encoding is a
/// normal conformance and works anywhere, decoding only works from a KEYED container.
///
/// The other gap is what actually survives the round trip. The original suite only ever compared the plain text, so
/// nothing checked that the ATTRIBUTES - the reason for using an attributed string at all - come back.

@Suite("NSAttributedString+Codable")

struct NSAttributedString_CodableTests
{
	static func roundTrip(_ string:NSAttributedString) throws -> NSAttributedString
	{
		let data = try PropertyListEncoder().encode(Container(string))

		return try PropertyListDecoder().decode(Container.self, from:data).string
	}


	@Test("Plain text survives the round trip")

	func testPlainText() throws
	{
		let decoded = try Self.roundTrip(NSAttributedString(string:"ExpectedValue"))

		#expect(decoded == NSAttributedString(string:"ExpectedValue"))
		#expect(decoded.string == "ExpectedValue")
	}


	/// THE POINT OF THE TYPE. Attributes have to survive, and nothing had ever checked one - the old assertions
	/// compared against a freshly built plain string, which an implementation that dropped every attribute would
	/// have passed.

	@Test("Attributes survive the round trip")

	func testAttributes() throws
	{
		let font = NSFont.systemFont(ofSize:24)

		let original = NSAttributedString(string:"styled", attributes:
		[
			.font : font,
			.foregroundColor : NSColor.red,
		])

		let decoded = try Self.roundTrip(original)

		#expect(decoded.string == "styled")

		var range = NSRange()
		let attributes = decoded.attributes(at:0, effectiveRange:&range)

		#expect(range.length == 6, "the attribute run did not cover the whole string")
		#expect((attributes[.font] as? NSFont)?.pointSize == 24)
		#expect(attributes[.foregroundColor] as? NSColor == NSColor.red)
		#expect(decoded == original, "the whole string, attributes included, must compare equal")
	}


	/// Several runs with different attributes have to keep their boundaries, not be flattened into one.

	@Test("Attribute runs keep their boundaries")

	func testMultipleRuns() throws
	{
		let original = NSMutableAttributedString(string:"one two")
		original.addAttribute(.font, value:NSFont.systemFont(ofSize:12), range:NSRange(location:0, length:3))
		original.addAttribute(.font, value:NSFont.systemFont(ofSize:24), range:NSRange(location:4, length:3))

		let decoded = try Self.roundTrip(original)

		var first = NSRange()
		var second = NSRange()

		#expect((decoded.attribute(.font, at:0, effectiveRange:&first) as? NSFont)?.pointSize == 12)
		#expect((decoded.attribute(.font, at:4, effectiveRange:&second) as? NSFont)?.pointSize == 24)
		#expect(first.length == 3)
	}


	@Test("An absent value decodes as nil")

	func testDecodeIfPresent() throws
	{
		let data = try PropertyListEncoder().encode(OptionalContainer(nil))

		#expect(try PropertyListDecoder().decode(OptionalContainer.self, from:data).string == nil)
	}


	@Test("An empty string survives")

	func testEmptyString() throws
	{
		#expect(try Self.roundTrip(NSAttributedString(string:"")).string == "")
	}


	/// The `data` property is the same archive by another name, and it swallows failures into an EMPTY Data rather
	/// than reporting them - so a caller cannot tell an empty string from an archive that could not be made.

	@Test("The data property archives the string")

	func testDataProperty()
	{
		let string = NSAttributedString(string:"hello")

		#expect(!string.data.isEmpty)
		#expect(NSAttributedString(string:"").data.isEmpty == false, "even an empty string produces an archive")
	}
}


//----------------------------------------------------------------------------------------------------------------------
