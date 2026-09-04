//
//  Numeric+LocalizedTests.swift
//  BXSwiftUtils
//
//  Copyright © 2026 Boinx Software Ltd. & Imagine GbR. All rights reserved.
//

import Testing
import Foundation
import CoreGraphics
@testable import BXSwiftUtils


//----------------------------------------------------------------------------------------------------------------------


/// Number formatting is where a test suite quietly becomes machine-dependent, so every case here passes an EXPLICIT
/// locale. The originals did too, which is the one thing that kept them from failing on a German machine - and worth
/// keeping, because the API's default is `Locale.current`.
///
/// The parsing direction is the more interesting half: it strips whatever is not part of a number before handing the
/// rest to the formatter, which makes it very forgiving - and the question is what it forgives that it should not.

@Suite("Numeric+Localized")

struct Numeric_LocalizedTests
{
	static let US = Locale(identifier:"en_US")
	static let DE = Locale(identifier:"de_DE")


	// MARK: - Formatting


	@Test("Integers are formatted with the given format and locale")

	func testIntegerFormatting()
	{
		#expect(1920.localized(locale:Self.US) == "1920")
		#expect(1920.localized(with:"#.#px", locale:Self.US) == "1920px")
		#expect(1920.localized(with:"#.# px", locale:Self.US) == "1920 px")

		// Leading zeros come from numberOfDigits, which is what the doc comment advertises

		#expect(1.localized(numberOfDigits:3, locale:Self.US) == "001")
		#expect(1234.localized(numberOfDigits:3, locale:Self.US) == "1234", "the width is a minimum, not a maximum")
	}


	/// NEGATIVES had no test, and they take a different path - the formatter is given a separate negativeFormat built
	/// from the positive one, so a format with a unit has to carry the unit into the negative case too.

	@Test("Negative numbers keep their sign and their unit")

	func testNegativeFormatting()
	{
		#expect((-5).localized(locale:Self.US) == "-5")
		#expect((-5).localized(with:"#.#px", locale:Self.US) == "-5px")
		#expect((-1.5).localized(with:"#.#s", locale:Self.US) == "-1.5s")
		#expect(0.localized(locale:Self.US) == "0")
	}


	/// The decimal separator is the locale's, which is the entire reason these take one.

	@Test("Floating point formatting follows the locale")

	func testFloatingPointFormatting()
	{
		#expect(1.234.localized(locale:Self.US) == "1.2")
		#expect(1.234.localized(locale:Self.DE) == "1,2")
		#expect(1.234.localized(with:"#.#s", locale:Self.US) == "1.2s")
		#expect(1.234.localized(with:"#.#s", locale:Self.DE) == "1,2s")
		#expect(1.234.localized(with:"#.##s", numberOfDigits:2, locale:Self.DE) == "1,23s")
	}


	/// Float and CGFloat have the same extension as Double, and nothing had used either - CGFloat is the one
	/// FotoMagico passes most often.

	@Test("Float and CGFloat format like Double")

	func testOtherFloatingPointTypes()
	{
		#expect(Float(1.25).localized(with:"#.##", numberOfDigits:2, locale:Self.US) == "1.25")
		#expect(CGFloat(1.25).localized(with:"#.##", numberOfDigits:2, locale:Self.US) == "1.25")
		#expect(CGFloat(1.25).localized(with:"#.##", numberOfDigits:2, locale:Self.DE) == "1,25")
	}


//----------------------------------------------------------------------------------------------------------------------


	// MARK: - Stripping


	@Test("Everything that is not part of a number is removed", arguments:
	[
		("1234unit", "1234"),
		("1234 unit", "1234"),
		("12 34", "1234"),
		(" 1234 ", "1234"),
		("bla1234laber", "1234"),
		("", ""),
		("unit", ""),
	])

	func testStripping(_ input:String, _ expected:String)
	{
		#expect(input.strippingNonNumericCharacters() == expected)
	}


	/// Signs and separators are kept deliberately - they are part of a number, and stripping them would turn -5 into
	/// 5. Neither had a test, and the sign case is the one that would be silently wrong.

	@Test("Signs and separators survive stripping")

	func testStrippingKeepsSignsAndSeparators()
	{
		#expect("-5px".strippingNonNumericCharacters() == "-5")
		#expect("+5px".strippingNonNumericCharacters() == "+5")
		#expect("12.34s".strippingNonNumericCharacters() == "12.34")
		#expect("1,234 items".strippingNonNumericCharacters() == "1,234")
	}


	/// PINS THE COST OF BEING FORGIVING. It removes characters rather than parsing, so anything left over is simply
	/// joined together - which turns a range or a list into one meaningless number instead of failing.

	@Test("Stripping joins what is left, however little sense it makes")

	func testStrippingIsNotParsing()
	{
		#expect("10-20".strippingNonNumericCharacters() == "10-20")
		#expect("1 and 2 and 3".strippingNonNumericCharacters() == "123")
		#expect("v1.2.3".strippingNonNumericCharacters() == "1.2.3")
	}


//----------------------------------------------------------------------------------------------------------------------


	// MARK: - Parsing


	@Test("An integer is parsed out of a decorated string", arguments:
	[
		"1234", " 1234 ", "12 34", "1234px", "1234 px", "1234 otherUnit",
	])

	func testParsingIntegers(_ input:String)
	{
		let formatter = NumberFormatter.forInteger(with:"#px", locale:Self.US)

		#expect(input.intValue(with:formatter) == 1234)
	}


	@Test("A double is parsed out of a decorated string", arguments:
	[
		"12.34", " 12.34 ", "12.34°", "12.34 °", "12.34 otherUnit",
	])

	func testParsingDoubles(_ input:String)
	{
		let formatter = NumberFormatter.forInteger(with:"#.#°", locale:Self.US)

		#expect(input.doubleValue(with:formatter) == 12.34)
	}


	/// Parsing follows the formatter's LOCALE, so the same text means different numbers in different places - a comma
	/// is a decimal point in German and a thousands separator in English. Nothing had tried the German side.

	@Test("Parsing follows the formatter's locale")

	func testParsingIsLocalised()
	{
		let german = NumberFormatter.forFloatingPoint(with:"#.#", numberOfDigits:2, locale:Self.DE)
		let american = NumberFormatter.forFloatingPoint(with:"#.#", numberOfDigits:2, locale:Self.US)

		#expect("12,34".doubleValue(with:german) == 12.34)
		#expect("12.34".doubleValue(with:american) == 12.34)
	}


	/// Negatives parse back, which is the round trip the formatting side has to agree with.

	@Test("Negative numbers survive a round trip")

	func testNegativeRoundTrip()
	{
		let formatter = NumberFormatter.forInteger(with:"#px", locale:Self.US)

		#expect("-5px".intValue(with:formatter) == -5)
		#expect((-5).localized(with:"#px", locale:Self.US).intValue(with:formatter) == -5)
	}
}


//----------------------------------------------------------------------------------------------------------------------
