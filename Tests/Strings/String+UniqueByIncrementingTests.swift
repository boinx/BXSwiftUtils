//
//  String+UniqueByIncrementingTests.swift
//  BXSwiftUtils
//
//  Copyright © 2026 Boinx Software Ltd. & Imagine GbR. All rights reserved.
//

import Testing
import Foundation
@testable import BXSwiftUtils


//----------------------------------------------------------------------------------------------------------------------


/// This is what names a duplicated layer or an exported file, so its output is read by users rather than by code, and
/// a wrong answer is visible rather than merely incorrect.
///
/// The behavior is deliberately asymmetric and that asymmetry is the part worth pinning: WITHOUT an annotation a
/// trailing number is left alone, because "Show 2018" is a name and not a counter; WITH one, a trailing number after
/// the annotation is picked up and continued, because "Placer copy 2" really was numbered by this function.

@Suite("String+UniqueByIncrementing")

struct String_UniqueByIncrementingTests
{
	/// Rejects nothing, for the cases where the question is what gets composed rather than what collides.

	static let acceptAll:(String) -> Bool = { _ in false }


//----------------------------------------------------------------------------------------------------------------------


	// MARK: - Incrementing without an annotation


	@Test("A free name is returned unchanged, a taken one is numbered", arguments:
	[
		// existing names, and what "bla" becomes
		([], "bla"),
		(["bla"], "bla 2"),
		(["bla", "bla 2"], "bla 3"),
		(["bla", "bla 2", "bla 3"], "bla 4"),
		(["other"], "bla"),						// a collision with something else is not a collision
		(["bla", "bla 3"], "bla 2"),			// GAPS ARE FILLED - the search takes the first free number, not the next one after the highest
		(["bla 2"], "bla"),						// the unnumbered name is free, so nothing is appended
	])

	func testIncrementing(_ existing:[String], _ expected:String)
	{
		#expect("bla".uniqueStringByIncrementing(rejectIf:existing.contains) == expected)
	}


	/// PINS THE DOCUMENTED ASYMMETRY. Without an annotation a trailing number is part of the NAME, so "show 2018"
	/// gains a counter instead of becoming "show 2019". Getting this wrong would quietly renumber people's documents.

	@Test("A trailing number is not a counter without an annotation", arguments:
	[
		("show 2018", ["show 2018"], "show 2018 2"),
		("show 2018", ["show 2018", "show 2018 2"], "show 2018 3"),
		("Placer 3", ["Placer 3"], "Placer 3 2"),			// straight from the documentation comment
		("bla 2", ["bla 2"], "bla 2 2"),
	])

	func testTrailingNumberIsNotACounter(_ name:String, _ existing:[String], _ expected:String)
	{
		#expect(name.uniqueStringByIncrementing(rejectIf:existing.contains) == expected)
	}


//----------------------------------------------------------------------------------------------------------------------


	// MARK: - Annotations


	@Test("An annotation is appended and then counted", arguments:
	[
		// name, existing names, expected
		("bla", [], "bla copy"),
		("bla copy", [], "bla copy"),							// already annotated and free - left alone
		("bla", ["bla copy"], "bla copy 2"),
		("bla", ["bla copy", "bla copy 3"], "bla copy 2"),		// gap filled here too
		("bla copy 3", ["bla copy", "bla copy 3"], "bla copy 4"),
		("bla copy", ["bla copy", "bla copy 2"], "bla copy 3"),
		("bla copy 2", ["bla copy", "bla copy 2"], "bla copy 3"),
	])

	func testAnnotation(_ name:String, _ existing:[String], _ expected:String)
	{
		#expect(name.uniqueStringByIncrementing(rejectIf:existing.contains, appendAnnotation:"copy") == expected)
	}


	/// PINS CURRENT BEHAVIOR. Recognising an existing annotation is CASE SENSITIVE, so a name the user capitalised
	/// differently is not recognised as already annotated and gets a second annotation instead of a counter.
	///
	/// Reachable by anyone who renames a duplicate by hand, and the result - "bla Copy copy" - is the kind of thing
	/// a user notices. Not changed here, because matching case-insensitively would also change which strings count
	/// as already-annotated for every existing caller.

	@Test("Annotation matching is case sensitive")

	func testAnnotationIsCaseSensitive()
	{
		#expect("bla Copy".uniqueStringByIncrementing(rejectIf:["bla Copy"].contains, appendAnnotation:"copy") == "bla Copy copy")
		#expect("bla copy".uniqueStringByIncrementing(rejectIf:["bla copy"].contains, appendAnnotation:"Copy") == "bla copy Copy")
	}


	/// The annotation is only recognised at the END of the string, which is what keeps a name that merely mentions
	/// the word from being treated as a duplicate of something.

	@Test("An annotation is only recognised at the end")

	func testAnnotationOnlyAtTheEnd()
	{
		#expect("copy of bla".uniqueStringByIncrementing(rejectIf:["copy of bla"].contains, appendAnnotation:"copy") == "copy of bla copy")
	}


//----------------------------------------------------------------------------------------------------------------------


	// MARK: - Separators, and what they are made of


	@Test("A custom separator is used for both the annotation and the counter")

	func testCustomSeparator()
	{
		let existing = ["bla--copy", "bla--copy--2"]

		#expect("bla--copy".uniqueStringByIncrementing(rejectIf:existing.contains, appendAnnotation:"copy", separator:"--") == "bla--copy--3")
		#expect("bla--copy--2".uniqueStringByIncrementing(rejectIf:existing.contains, appendAnnotation:"copy", separator:"--") == "bla--copy--3")
	}


	/// The annotation and separator are pushed through a REGULAR EXPRESSION to find an existing counter, so anything
	/// a caller passes has to be escaped first. Nothing tested that, and the characters that would break it are
	/// exactly the ones a separator plausibly is: a dot, a plus, a bracket.
	///
	/// Unescaped, `.` would match any character and `+` would fail to compile the pattern at all - and a pattern that
	/// does not compile means `range(of:options:.regularExpression)` finds nothing, so the counter is silently
	/// ignored rather than continued.

	@Test("Regex metacharacters in the separator and annotation are escaped", arguments:
	[
		// name, annotation, separator, expected
		("bla.copy.2", "copy", ".", "bla.copy.3"),
		("bla c+p 2", "c+p", " ", "bla c+p 3"),
		("bla(x)2", "(x)", "", "bla(x)3"),
		("bla[1]copy[1]2", "copy", "[1]", "bla[1]copy[1]3"),
	])

	func testRegexMetacharactersAreEscaped(_ name:String, _ annotation:String, _ separator:String, _ expected:String)
	{
		#expect(name.uniqueStringByIncrementing(rejectIf:[name].contains, appendAnnotation:annotation, separator:separator) == expected)
	}


//----------------------------------------------------------------------------------------------------------------------


	// MARK: - Filenames


	@Test("The extension is preserved and the counter goes before it", arguments:
	[
		// name, existing, annotation, expected
		("bla.jpg", ["bla.jpg"], nil, "bla 2.jpg"),
		("bla.jpg", ["bla.jpg"], "copy", "bla copy.jpg"),
		("foo.jpg", ["bla.jpg", "foo copy.jpg"], "copy", "foo copy 2.jpg"),
		("archive.tar.gz", ["archive.tar.gz"], nil, "archive.tar 2.gz"),	// only the LAST extension counts
	])

	func testFilename(_ name:String, _ existing:[String], _ annotation:String?, _ expected:String)
	{
		#expect(name.uniqueFilenameByIncrementing(rejectIf:existing.contains, appendAnnotation:annotation) == expected)
	}


	/// FIXED, and it was wrong in two ways at once. A name with NO extension used to come back with a trailing dot -
	/// "bla" became "bla." - because the extension was appended unconditionally.
	///
	/// The worse half was invisible: the rejector was handed "bla." while the caller's list held "bla", so the
	/// collision this function exists to avoid was never seen. The original name came back, dotted and still taken.

	@Test("A name with no extension does not acquire one", arguments:
	[
		// name, existing, expected
		("bla", [], "bla"),
		("bla", ["bla"], "bla 2"),					// the collision is now actually noticed
		("bla", ["bla", "bla 2"], "bla 3"),
		("README", ["README"], "README 2"),
	])

	func testFilenameWithoutExtension(_ name:String, _ existing:[String], _ expected:String)
	{
		#expect(name.uniqueFilenameByIncrementing(rejectIf:existing.contains) == expected)
	}


	/// A dotfile is the same bug wearing a different hat: NSString reports no extension for ".gitignore", so it used
	/// to become ".gitignore." - a different file, and a hidden one that no longer looks like what it is.

	@Test("A dotfile keeps its name")

	func testDotfile()
	{
		#expect(".gitignore".uniqueFilenameByIncrementing(rejectIf:Self.acceptAll) == ".gitignore")
		#expect(".gitignore".uniqueFilenameByIncrementing(rejectIf:[".gitignore"].contains) == ".gitignore 2")
	}


	/// The rejector must be asked about the FULL filename, extension included, or a caller holding real filenames
	/// would never match anything it is shown.

	@Test("The rejector sees the name with its extension")

	func testRejectorSeesTheExtension()
	{
		var seen:[String] = []

		_ = "bla.jpg".uniqueFilenameByIncrementing(rejectIf:
		{
			seen.append($0)
			return $0 == "bla.jpg"
		})

		#expect(seen.first == "bla.jpg")
		#expect(seen.allSatisfy { $0.hasSuffix(".jpg") }, "\(seen)")
	}


//----------------------------------------------------------------------------------------------------------------------


	// MARK: - Degenerate input


	/// FIXED. A counter of Int.max used to CRASH: the search ran over `counter ..< Int.max`, which is EMPTY when the
	/// counter parsed out of the input is already Int.max, and the force unwrap on the first match had nothing to
	/// unwrap. A closed range makes Int.max a usable counter like any other.
	///
	/// Absurd as an input, but it is a NAME - a string a user can type or paste - not something only code produces.

	@Test("A counter at the integer limit does not crash")

	func testCounterAtTheIntegerLimit()
	{
		let atMax = "bla copy \(Int.max)"

		#expect(atMax.uniqueStringByIncrementing(rejectIf:Self.acceptAll, appendAnnotation:"copy") == atMax)

		// One below the limit still increments into it rather than stopping short

		let belowMax = "bla copy \(Int.max - 1)"

		#expect(belowMax.uniqueStringByIncrementing(rejectIf:[belowMax].contains, appendAnnotation:"copy") == atMax)
	}


	/// A counter too large for Int falls back to 1 rather than being carried, so the search starts from the beginning
	/// instead of continuing a number nobody can represent. PINNED because the alternative - trusting the digits -
	/// is what would make the case above unreachable.

	@Test("A counter too large for Int restarts the numbering")

	func testUnparseableCounterRestarts()
	{
		let huge = "bla copy 99999999999999999999999"

		#expect(huge.uniqueStringByIncrementing(rejectIf:Self.acceptAll, appendAnnotation:"copy") == "bla copy")
	}


	/// PINS CURRENT BEHAVIOR for inputs that are not really names. Neither result is wrong exactly, but both are
	/// worth stating: an empty base leaves the separator stranded at the front, and an empty annotation leaves it
	/// stranded at the back.

	@Test("Empty strings leave the separator stranded")

	func testEmptyStrings()
	{
		#expect("".uniqueStringByIncrementing(rejectIf:[""].contains) == " 2")
		#expect("bla".uniqueStringByIncrementing(rejectIf:["bla"].contains, appendAnnotation:"") == "bla ")
	}


	/// The rejector is consulted at least once even when nothing can collide, so a caller relying on it for a side
	/// effect - counting, logging - sees the name that was actually chosen.

	@Test("The chosen name is the last one the rejector was shown")

	func testRejectorSeesTheChosenName()
	{
		var seen:[String] = []

		let result = "bla".uniqueStringByIncrementing(rejectIf:
		{
			seen.append($0)
			return ["bla", "bla 2"].contains($0)
		})

		#expect(result == "bla 3")
		#expect(seen == ["bla", "bla 2", "bla 3"])
	}
}


//----------------------------------------------------------------------------------------------------------------------
