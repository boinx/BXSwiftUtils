//
//  String+RegexTests.swift
//  BXSwiftUtils
//
//  Copyright © 2026 Boinx Software Ltd. & Imagine GbR. All rights reserved.
//

import Testing
import Foundation
@testable import BXSwiftUtils


//----------------------------------------------------------------------------------------------------------------------


/// Two conveniences over NSRegularExpression. The first swallows every error it can meet, which makes "no matches"
/// and "your pattern is nonsense" the same answer - that is the behavior worth pinning, since a caller building a
/// pattern from anything dynamic gets no warning at all.

@Suite("String+Regex")

struct String_RegexTests
{
	static let sentence = "Bla Laber ABC Schwafel Sülz"


	@Test("Matches are returned in order", arguments:
	[
		("ABC", ["ABC"]),
		("XYZ", []),
		("[A-Z]{3}", ["ABC"]),									// three consecutive capitals occur once
		("[A-Z][a-z]+", ["Bla", "Laber", "Schwafel"]),			// "Sülz" is missing - [a-z] is ASCII only
	])

	func testMatches(_ pattern:String, _ expected:[String])
	{
		#expect(Self.sentence.regexMatches(for:pattern) == expected)
	}


	@Test("Every occurrence is returned")

	func testMultipleMatches()
	{
		let repeated = "Bla ABC Laber ABC Schwafel ABC Sülz"

		#expect(repeated.regexMatches(for:"ABC") == ["ABC", "ABC", "ABC"])
		#expect(repeated.regexMatches(for:"ABC").count == 3)
	}


	/// The WHOLE match is returned, not the capture groups - so a pattern written with parentheses to extract part of
	/// something gives back the part plus everything around it. Worth stating, because that is what the parentheses
	/// look like they are for.

	@Test("Capture groups are not returned separately")

	func testCaptureGroups()
	{
		let matches = "width=1920 height=1080".regexMatches(for:"width=(\\d+)")

		#expect(matches == ["width=1920"], "the group was returned rather than the whole match")
	}


	/// PINS THE ERROR SWALLOWING. An invalid pattern answers `[]` - exactly what a valid pattern with no matches
	/// answers - because the NSRegularExpression is built with `try?`. Reachable by anything that builds a pattern
	/// from user input or a file, and silent by construction.

	@Test("An invalid pattern is indistinguishable from no matches")

	func testInvalidPattern()
	{
		#expect(Self.sentence.regexMatches(for:"[unclosed") == [])
		#expect(Self.sentence.regexMatches(for:"*") == [])
		#expect(Self.sentence.regexMatches(for:"(?<") == [])

		// ...and a valid pattern with nothing to find says the same thing

		#expect(Self.sentence.regexMatches(for:"ZZZ") == [])
	}


	/// The search runs over an NSString, so ranges are UTF-16 offsets rather than Character positions. Text outside
	/// the basic plane - an emoji, a flag - is where those two disagree, and nothing had tried any.

	@Test("Matching works across non-ASCII text")

	func testUnicode()
	{
		#expect("Sülz".regexMatches(for:"ü") == ["ü"])
		#expect("a👍b👍c".regexMatches(for:"👍").count == 2)
		#expect("a👍b".regexMatches(for:"b") == ["b"], "an offset after an emoji still lands correctly")
		#expect("🇩🇪 flag".regexMatches(for:"flag") == ["flag"])
	}


	@Test("An empty string matches nothing")

	func testEmptyString()
	{
		#expect("".regexMatches(for:"ABC") == [])
	}


//----------------------------------------------------------------------------------------------------------------------


	// MARK: - Stripping HTML


	/// `strippingHTMLTags` had NO coverage at all. It is a regular expression rather than a parser, which is fine for
	/// the release notes it is used on and worth stating the limits of.

	@Test("Tags are removed and their content kept", arguments:
	[
		("<b>bold</b>", "bold"),
		("<p>one</p><p>two</p>", "onetwo"),
		("plain text", "plain text"),
		("", ""),
		("<br/>", ""),
		("<a href=\"http://example.com\">link</a>", "link"),
		("<span class='x'>styled</span>", "styled"),
	])

	func testStrippingHTMLTags(_ input:String, _ expected:String)
	{
		#expect(input.strippingHTMLTags() == expected)
	}


	/// PINS THE LIMITS. It removes anything between angle brackets, which is not the same as understanding HTML: a
	/// bare `<` with no closing bracket is left alone, a `>` on its own is kept, and an unclosed tag swallows
	/// everything to the next `>` - including text that was never markup.

	@Test("It is a pattern, not a parser")

	func testStrippingIsNotParsing()
	{
		#expect("5 < 10".strippingHTMLTags() == "5 < 10", "a lone angle bracket is not a tag")
		#expect("10 > 5".strippingHTMLTags() == "10 > 5")
		#expect("a <b c> d".strippingHTMLTags() == "a  d", "anything between brackets goes, markup or not")
		#expect("<script>alert()</script>".strippingHTMLTags() == "alert()", "content is kept even when the tag was code")
	}
}


//----------------------------------------------------------------------------------------------------------------------
