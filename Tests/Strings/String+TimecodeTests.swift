//
//  String+TimecodeTests.swift
//  BXSwiftUtils
//
//  Copyright © 2026 Boinx Software Ltd. & Imagine GbR. All rights reserved.
//

import Testing
import Foundation
@testable import BXSwiftUtils


//----------------------------------------------------------------------------------------------------------------------


/// Timecode conversion runs in both directions between a Double of seconds and an "H:MM:SS.fff" string. Neither
/// direction validates anything: the formatter does arithmetic on whatever it is given, and the parser skips any
/// component it cannot read while still advancing its 60x factor. That combination is where the surprises live.

@Suite("Timecode conversion")

struct TimecodeTests
{
	/// A round trip is one multiplication into ticks and one division back out, so a value absorbs two roundings.

	static let epsilon = 1e-9


	// MARK: - Formatting


	@Test("Seconds are formatted as H:MM:SS.fff", arguments:
	[
		(0.0, "0:00:00.000"),
		(0.5, "0:00:00.500"),
		(1.5, "0:00:01.500"),
		(60.0, "0:01:00.000"),
		(61.0, "0:01:01.000"),
		(3661.5, "1:01:01.500"),
		(86400.0, "24:00:00.000"),
	])

	func testTimecodeString(_ seconds:Double, _ expected:String)
	{
		#expect(seconds.timecodeString() == expected)
	}


	/// A value is rendered to the NEAREST tick, so binary representation error no longer costs a millisecond.
	///
	/// 3599.999 used to format as "0:59:59.998": the old code took the fraction and multiplied it by 1000, and
	/// 0.999 times 1000 is 998.99999999 in binary, which Int(_:) then truncated. The millisecond was genuinely
	/// there in the value and the string lost it.

	@Test("A value is rendered to the nearest tick", arguments:
	[
		(3599.999, "0:59:59.999"),
		(59.999, "0:00:59.999"),
		(0.001, "0:00:00.001"),
		(0.999, "0:00:00.999"),
		(1.001, "0:00:01.001"),
	])

	func testNearestTick(_ seconds:Double, _ expected:String)
	{
		#expect(seconds.timecodeString() == expected)
	}


	/// Rounding has to carry, which is why the value is scaled to a tick count ONCE rather than having its
	/// fraction rounded on its own. Rounding the fraction alone would give 59.9999 a thousand-millisecond field
	/// and print "0:00:59.1000".

	@Test("Rounding carries into the higher fields", arguments:
	[
		(59.9999, "0:01:00.000"),
		(59.9995, "0:01:00.000"),
		(3599.9999, "1:00:00.000"),
		(0.9999, "0:00:01.000"),
	])

	func testRoundingCarries(_ seconds:Double, _ expected:String)
	{
		#expect(seconds.timecodeString() == expected)
	}


	/// A value sitting exactly on a half tick rounds AWAY from zero, which is what Double.rounded() does. Pinned
	/// because it is the one case where "nearest" has no single answer: at 25 fps, 2.5s is frame 62.5 exactly.
	///
	/// Note this is a change from the old behavior, which truncated and so always resolved a tie downward. SMPTE
	/// timecode identifies the CURRENT frame and would truncate; this formatter is used for durations and playhead
	/// readouts, where nearest-tick reads better.

	@Test("A value exactly on a half tick rounds away from zero")

	func testHalfTickRoundsAwayFromZero()
	{
		#expect(2.5.timecodeString(fps:25) == "0:00:02.13")		// frame 62.5 -> 63
		#expect((-2.5).timecodeString(fps:25) == "-0:00:02.13")
		#expect(0.0005.timecodeString() == "0:00:00.001")
	}


	/// A negative duration is formatted from its MAGNITUDE with a leading minus. The sign used to leak into the
	/// individual fields instead, producing unparseable output like "0:00:-5.-500".

	@Test("A negative duration carries a leading sign", arguments:
	[
		(-5.5, "-0:00:05.500"),
		(-0.25, "-0:00:00.250"),
		(-3661.5, "-1:01:01.500"),
		(-60.0, "-0:01:00.000"),
	])

	func testNegativeDurationCarriesASign(_ seconds:Double, _ expected:String)
	{
		#expect(seconds.timecodeString() == expected)
	}


	/// Negative zero is not negative, so it gets no sign - otherwise a value that rounds to nothing would sprout
	/// one for no visible reason.

	@Test("Negative zero carries no sign")

	func testNegativeZeroHasNoSign()
	{
		#expect((-0.0).timecodeString() == "0:00:00.000")
		#expect((-0.0).shortTimecodeString() == "0:00:00")
	}


	/// The short form floors the MAGNITUDE, so a negative value truncates towards zero rather than away from it.

	@Test("The short form truncates a negative towards zero")

	func testShortFormOfNegative()
	{
		#expect((-5.5).shortTimecodeString() == "-0:00:05")
		#expect((-0.25).shortTimecodeString() == "-0:00:00")
	}


	/// Below 100 fps the last field is FRAMES in a two digit slot, not thousandths - so the same instant reads
	/// differently depending on fps, and only the default 1000 produces a string the parser can read back.

	@Test("Below 100 fps the last field is frames, not thousandths")

	func testFrameRateChangesTheLastField()
	{
		#expect(1.5.timecodeString(fps:30) == "0:00:01.15")
		#expect(1.5.timecodeString(fps:1000) == "0:00:01.500")
		#expect(2.0.timecodeString(fps:25) == "0:00:02.00")
	}


	/// A frame rate of zero or less has no meaning. It matters that this is guarded rather than merely odd: the
	/// tick count is divided BY the frame rate, so a zero would divide by zero and trap.

	@Test("A non-positive frame rate yields the placeholder", arguments:[0, -1, -25])

	func testNonPositiveFrameRateIsRejected(_ fps:Int)
	{
		#expect(1.5.timecodeString(fps:fps) == Double.invalidTimecodeString(fps:fps), "fps \(fps)")
	}


	/// A frame rate large enough to overflow the tick count is rejected too - the ceiling on seconds alone cannot
	/// catch it, because the seconds are multiplied by the frame rate before the conversion to Int.

	@Test("A frame rate that overflows the tick count yields the placeholder")

	func testOverflowingFrameRateIsRejected()
	{
		#expect(1.0e15.timecodeString(fps:1_000_000) == "--:--:--.---")
		#expect(1.0e14.timecodeString(fps:1_000_000) == "--:--:--.---")
	}


	/// The short form drops the fraction by flooring, which is the right direction for an elapsed-time readout.

	@Test("The short form floors to whole seconds", arguments:
	[
		(0.0, "0:00:00"),
		(0.9, "0:00:00"),
		(61.75, "0:01:01"),
		(3661.5, "1:01:01"),
	])

	func testShortTimecodeString(_ seconds:Double, _ expected:String)
	{
		#expect(seconds.shortTimecodeString() == expected)
	}


	/// A value that cannot be represented yields the placeholder instead of crashing.
	///
	/// These all used to TRAP: Int(_:) does not saturate, so a NaN or infinite duration took the whole process
	/// down, and the hours field overflowed for a large enough magnitude. Because the old behavior was a trap
	/// rather than a wrong answer, none of it could be covered by a test until it was fixed - the test process
	/// would have died with it.

	@Test("A value that cannot be represented yields the placeholder", arguments:
	[
		Double.nan,
		Double.infinity,
		-Double.infinity,
		Double.signalingNaN,
		Double.greatestFiniteMagnitude,
		-Double.greatestFiniteMagnitude,
		1.0e16,						// past maximumTimecodeSeconds
		-1.0e16,
	])

	func testUnrepresentableValueYieldsPlaceholder(_ seconds:Double)
	{
		#expect(seconds.timecodeString() == "--:--:--.---", "\(seconds)")
		#expect(seconds.shortTimecodeString() == "--:--:--", "\(seconds)")
	}


	/// The placeholder follows the shape of the format: same separators, and a fraction field whose width tracks
	/// the frame rate exactly as the real one does.
	///
	/// It deliberately does NOT claim to match the width of every timecode. The hours field is `%i`, so the real
	/// output is variable width already - "9:00:00.000" is a character shorter than "10:00:00.000" - and no single
	/// placeholder can match both. Two dashes are used for the hours, which matches the two-digit case.

	@Test("The placeholder follows the shape of the format")

	func testPlaceholderFollowsFormatShape()
	{
		#expect(Double.nan.timecodeString(fps:1000) == "--:--:--.---")
		#expect(Double.nan.timecodeString(fps:30) == "--:--:--.--")

		// The fraction field tracks the frame rate, just as the real format does

		#expect(Double.invalidTimecodeString(fps:1000).hasSuffix(".---"))
		#expect(Double.invalidTimecodeString(fps:30).hasSuffix(".--"))

		// It matches a two digit hours timecode exactly, and is one wider than a single digit one

		#expect(Double.invalidTimecodeString(fps:1000).count == 86400.0.timecodeString().count)
		#expect(Double.invalidShortTimecodeString.count == 86400.0.shortTimecodeString().count)
		#expect(Double.invalidTimecodeString(fps:1000).count == 3661.5.timecodeString().count + 1)
	}


	/// The value right at the ceiling is still rendered - the guard is inclusive, so the boundary is not a
	/// silently unrepresentable value of its own.

	@Test("The largest representable value is still rendered")

	func testValueAtTheCeilingIsRendered()
	{
		let string = Double.maximumTimecodeSeconds.timecodeString()

		#expect(string != "--:--:--.---")
		#expect(string.hasSuffix(".000"))
	}


	/// The placeholder is not mistakable for a real value: parsing it back yields zero, exactly like any other
	/// wholly unparseable string, rather than a plausible number.

	@Test("The placeholder does not parse back to anything")

	func testPlaceholderDoesNotParseBack()
	{
		#expect(Double.invalidTimecodeString().timecodeValueInSeconds() == 0.0)
		#expect(Double.invalidShortTimecodeString.timecodeValueInSeconds() == 0.0)
	}


//----------------------------------------------------------------------------------------------------------------------


	// MARK: - Field selection


	/// The two flags select which fields are printed. This is what lets one implementation serve every shape the
	/// apps need - BXTimeCodeFormatter used to carry its own copy of this arithmetic, and therefore its own copy
	/// of the Int(_:) trap that the guards above exist to prevent.

	@Test("The flags select which fields are printed", arguments:
	[
		(true, true, "1:01:01.500"),
		(true, false, "1:01:01"),
		(false, true, "61:01.500"),
		(false, false, "61:01"),
	])

	func testFieldSelection(_ showsHours:Bool, _ showsFraction:Bool, _ expected:String)
	{
		#expect(3661.5.timecodeString(showsHours:showsHours, showsFraction:showsFraction) == expected)
	}


	/// With the hours hidden the minutes field holds the TOTAL minutes, not minutes past the hour.
	///
	/// Wrapping it at sixty is not a shorter way of saying the same thing: 1h15m would print as "15:00", which is
	/// indistinguishable from a genuine fifteen minutes, and the hour would be gone without trace. The field is a
	/// MINIMUM width, so three digit minutes print in full rather than being truncated to fit.

	@Test("With the hours hidden the minutes do not wrap", arguments:
	[
		(3600.0, "60:00.000"),
		(4500.0, "75:00.000"),
		(7500.0, "125:00.000"),
	])

	func testHoursHiddenShowsTotalMinutes(_ seconds:Double, _ expected:String)
	{
		#expect(seconds.timecodeString(showsHours:false) == expected)
	}


	/// The sign is a property of the whole timecode in every shape, not of the hours field it happens to precede.

	@Test("A negative value carries its sign in every shape", arguments:
	[
		(true, true, "-1:01:01.500"),
		(true, false, "-1:01:01"),
		(false, true, "-61:01.500"),
		(false, false, "-61:01"),
	])

	func testNegativeInEveryShape(_ showsHours:Bool, _ showsFraction:Bool, _ expected:String)
	{
		#expect((-3661.5).timecodeString(showsHours:showsHours, showsFraction:showsFraction) == expected)
	}


	/// Dropping the fraction FLOORS rather than rounding through a tick count.
	///
	/// Rounding would push a value up into a second whose precision is not being shown - 59.6 would read as one
	/// minute - and it would break the short form's documented truncation towards zero.

	@Test("Dropping the fraction floors rather than rounds", arguments:
	[
		(59.6, "0:00:59"),
		(59.999, "0:00:59"),
		(-59.6, "-0:00:59"),
	])

	func testNoFractionFloors(_ seconds:Double, _ expected:String)
	{
		#expect(seconds.timecodeString(showsFraction:false) == expected)
	}


	/// The short form is exactly the hours-without-fraction shape, which is why it can delegate rather than carry
	/// a second copy of the decomposition.

	@Test("The short form is the hours-without-fraction shape", arguments:
	[0.0, 0.9, 61.75, 3661.5, -5.5, -0.0])

	func testShortFormDelegates(_ seconds:Double)
	{
		#expect(seconds.shortTimecodeString() == seconds.timecodeString(showsFraction:false), "\(seconds)")
	}


	/// The placeholder follows the same shape as the string it stands in for. A placeholder that kept fields the
	/// real output does not have would not read as "this timecode is unknown" - it would read as a different
	/// timecode entirely.

	@Test("The placeholder follows the shape it stands in for", arguments:
	[
		(1000, true, true, "--:--:--.---"),
		(1000, true, false, "--:--:--"),
		(1000, false, true, "--:--.---"),
		(1000, false, false, "--:--"),
		(30, true, true, "--:--:--.--"),
		(30, false, true, "--:--.--"),
		(30, false, false, "--:--"),
	])

	func testPlaceholderShape(_ fps:Int, _ showsHours:Bool, _ showsFraction:Bool, _ expected:String)
	{
		#expect(Double.invalidTimecodeString(fps:fps, showsHours:showsHours, showsFraction:showsFraction) == expected)
	}


	/// A value that cannot be represented yields the placeholder for ITS shape, not the default one - the guards
	/// are shared, so a caller asking for a narrower shape must not get a wider placeholder back.

	@Test("An unrepresentable value yields the placeholder for its own shape", arguments:
	[Double.nan, .infinity, -.infinity, .greatestFiniteMagnitude, 1.0e16])

	func testUnrepresentableInEveryShape(_ seconds:Double)
	{
		#expect(seconds.timecodeString(showsHours:false) == "--:--.---", "\(seconds)")
		#expect(seconds.timecodeString(showsHours:false, showsFraction:false) == "--:--", "\(seconds)")
		#expect(seconds.timecodeString(showsFraction:false) == "--:--:--", "\(seconds)")
	}



//----------------------------------------------------------------------------------------------------------------------


	// MARK: - Parsing


	/// Components are read right to left, each worth 60x the one before, so a string may carry as few or as many
	/// as it likes.

	@Test("A timecode string is parsed right to left", arguments:
	[
		("90", 90.0),
		("1:30", 90.0),
		("0:01:30", 90.0),
		("1:00:00", 3600.0),
		("0:00:01.500", 1.5),
	])

	func testTimecodeValueInSeconds(_ string:String, _ expected:Double)
	{
		#expect(string.timecodeValueInSeconds() == expected)
	}


	/// Surrounding whitespace is trimmed, so a value typed with a stray space still reads correctly.
	///
	/// This is the case that used to be actively misleading rather than merely lenient: " 1:30" came back as 30
	/// seconds, not 90, because Double(" 1") is nil and the skipped component still advanced the 60x factor - so
	/// the minutes vanished and left a plausible-looking answer behind.

	@Test("Surrounding whitespace is trimmed", arguments:
	[
		(" 1:30", 90.0),
		("1:30 ", 90.0),
		(" 1 : 30 ", 90.0),
		("\t1:30", 90.0),
		(" 90 ", 90.0),
	])

	func testWhitespaceIsTrimmed(_ string:String, _ expected:Double)
	{
		#expect(string.timecodeValue() == expected, "\(string)")
		#expect(string.timecodeValueInSeconds() == expected, "\(string)")
	}


	/// A component that is still not a number invalidates the WHOLE string. Skipping it while keeping the place
	/// value of the others is what produced a wrong answer instead of no answer.

	@Test("An unreadable component invalidates the whole string", arguments:
	[
		"abc:30",
		"::30",
		"x:y:30",
		"1:2x:3",
		"1::3",
	])

	func testUnreadableComponentInvalidatesEverything(_ string:String)
	{
		#expect(string.timecodeValue() == nil, "\(string)")
	}


	/// Swift's Double parser accepts "nan" and "inf", so a component spelling either of those would otherwise
	/// yield a non-finite duration - and hand it straight to a formatter.

	@Test("A non-finite component is rejected", arguments:
	[
		"inf", "inf:30", "nan:30", "1:nan", "-inf:0", "infinity:0", "NaN",
	])

	func testNonFiniteComponentIsRejected(_ string:String)
	{
		#expect(string.timecodeValue() == nil, "\(string)")
		#expect(string.timecodeValueInSeconds() == 0.0, "\(string)")
	}


	/// The result is checked rather than each component, because components that are individually finite can
	/// still overflow when they are summed with their sixty-times factors. "1e308:0" is the case: both parts are
	/// real numbers and the total is infinity.

	@Test("Finite components that overflow when combined are rejected", arguments:
	[
		"1e308:0",
		"0:1e308:0",
		"-1e308:0",
	])

	func testOverflowingTotalIsRejected(_ string:String)
	{
		#expect(string.timecodeValue() == nil, "\(string)")
	}


	/// Input with nothing usable in it is nil. The defaulting wrapper still answers 0, which is exactly why it
	/// cannot be trusted to tell nonsense from a real zero - that is what timecodeValue() is for.

	@Test("Wholly unreadable input is nil, and zero through the wrapper", arguments:["", "abc", ":", "::", "   "])

	func testUnreadableInputIsNil(_ string:String)
	{
		#expect(string.timecodeValue() == nil, "\(string)")
		#expect(string.timecodeValueInSeconds() == 0.0, "\(string)")
	}


	/// A genuine zero is distinguishable from nonsense through the optional form, which is the whole point of
	/// having it.

	@Test("A real zero is distinguishable from unreadable input")

	func testRealZeroIsDistinguishable()
	{
		#expect("0".timecodeValue() == 0.0)
		#expect("0:00:00.000".timecodeValue() == 0.0)
		#expect("abc".timecodeValue() == nil)

		// Both answer 0.0 through the defaulting wrapper - the ambiguity it cannot resolve

		#expect("0".timecodeValueInSeconds() == "abc".timecodeValueInSeconds())
	}


	/// A component must be plain decimal digits. Double(_:) on its own is far more permissive than a timecode
	/// should be - it reads "0x10" as 16 and "1e3" as 1000 - and each of those looks like a number that is not
	/// the one it denotes.

	@Test("Only plain decimal components are accepted", arguments:
	[
		"0x10",			// hex, read as 16
		"1e3",			// exponent, read as 1000
		"1E3",
		"0x10:30",
		"1:1e3",
		"1_000",
		"1,5",			// a decimal comma
		"1.2.3",		// two decimal points
		"5.",			// a trailing point
		".5",			// a leading point
		".",
		"٥",			// Arabic-Indic five
		"１",			// a full width one
		"1½",
	])

	func testOnlyDecimalComponentsAreAccepted(_ string:String)
	{
		#expect(string.timecodeValue() == nil, "\(string)")
	}


	/// What a component may legitimately look like: digits, optionally with a decimal point between digits.
	/// Leading zeros are ordinary in a timecode and must keep working.

	@Test("Plain decimal components are accepted", arguments:
	[
		("30", 30.0),
		("05", 5.0),
		("00042", 42.0),
		("0", 0.0),
		("1.5", 1.5),
		("05.500", 5.5),
		("0.000", 0.0),
	])

	func testDecimalComponentsAreAccepted(_ string:String, _ expected:Double)
	{
		#expect(string.timecodeValue() == expected, "\(string)")
	}


	/// The digits-only rule does NOT make the non-finite check redundant: a component of nothing but digits can
	/// still be large enough to overflow a Double, and the sum can overflow even when each part does not.

	@Test("An all-digit component can still overflow")

	func testAllDigitComponentCanOverflow()
	{
		let huge = "1" + String(repeating:"0", count:400)

		#expect(Double(huge)?.isInfinite == true, "the fixture is not actually infinite")
		#expect(huge.timecodeValue() == nil)
		#expect("\(huge):0".timecodeValue() == nil)
	}


	/// The fourth component is DAYS, worth 24 hours.
	///
	/// It used to be worth SIXTY hours: the old loop multiplied its factor by sixty for every component, which is
	/// correct up to hours and wrong beyond them. "1:00:00:00" came back as 216000 seconds rather than 86400 - a
	/// day and a half out, from a string that looks entirely ordinary.

	/// Held as an explicitly typed static rather than written inline: an arithmetic expression inside a tuple in
	/// an array literal defeats the type checker, which gives up rather than reporting a real error.

	static let dayCases:[(String,Double)] =
	[
		("1:0:0:0", 86400.0),		// one day
		("0:1:0:0", 3600.0),		// one hour
		("0:0:1:0", 60.0),			// one minute
		("0:0:0:1", 1.0),			// one second
		("1:2:3:4", 93784.0),		// 86400 + 7200 + 180 + 4
		("2:00:00:00", 172800.0),
	]


	@Test("The fourth component is days", arguments:Self.dayCases)

	func testFourthComponentIsDays(_ string:String, _ expected:Double)
	{
		#expect(string.timecodeValue() == expected, "\(string)")
	}


	/// The place values are exactly seconds, minutes, hours and days - worth stating together, because the bug was
	/// that they were derived by repeated multiplication rather than named.

	@Test("The place values are seconds, minutes, hours and days")

	func testPlaceValues()
	{
		#expect("1".timecodeValue() == 1.0)
		#expect("1:0".timecodeValue() == 60.0)
		#expect("1:0:0".timecodeValue() == 3600.0)
		#expect("1:0:0:0".timecodeValue() == 86400.0)
	}


	/// A FIFTH component has no meaning, so it is rejected rather than scaled by another sixty - or by any other
	/// number someone might guess at.

	@Test("More than four components is invalid", arguments:
	[
		"1:0:0:0:0",
		"0:0:0:0:0",
		"1:2:3:4:5:6",
	])

	func testMoreThanFourComponentsIsInvalid(_ string:String)
	{
		#expect(string.timecodeValue() == nil, "\(string)")
		#expect(string.timecodeValueInSeconds() == 0.0, "\(string)")
	}


	/// The formatter has no day field - it lets the hours run past 24 - so a four component string parses but does
	/// not come back in the same shape. Worth pinning: the round trip is format-then-parse, not parse-then-format.

	@Test("A day is parsed but formatted as hours")

	func testDayIsFormattedAsHours() throws
	{
		let seconds = try #require("1:00:00:00".timecodeValue())

		#expect(seconds == 86400.0)
		#expect(seconds.timecodeString() == "24:00:00.000")
	}


	/// A leading sign applies to the WHOLE timecode, not to the component it happens to touch.
	///
	/// "-1:30" is minus ninety seconds, not minus thirty. It used to be the latter: the minus stayed attached to
	/// the minutes, so it subtracted one minute from thirty seconds. Every system with a signed timecode writes
	/// the sign once at the front - SMPTE has no negative form, the NLEs show offsets as "-01:00:00:00", and ISO
	/// 8601 durations are "-PT1M30S".

	@Test("A leading sign applies to the whole timecode", arguments:
	[
		("-1:30", -90.0),
		("-90", -90.0),
		("-0:01:30", -90.0),
		("-1:00:00:00", -86400.0),
		("+1:30", 90.0),
		("+90", 90.0),
		(" -1:30 ", -90.0),
	])

	func testLeadingSignAppliesToTheWhole(_ string:String, _ expected:Double)
	{
		#expect(string.timecodeValue() == expected, "\(string)")
	}


	/// An individual component may NOT carry a sign. There is no convention for it, and reading it as arithmetic
	/// means part of a timecode silently subtracts from the rest.
	///
	/// There is no separate check for this any more - a sign is simply not a digit, so the decimal-component rule
	/// covers it. These cases stay because the RULE is worth pinning independently of how it is enforced.

	@Test("A signed component is rejected", arguments:
	[
		"0:-2:-1",
		"0:-2:1",
		"1:-30",
		"-1:-30",
		"--1:30",
		"1:+30",
		"-",
		"+",
	])

	func testSignedComponentIsRejected(_ string:String)
	{
		#expect(string.timecodeValue() == nil, "\(string)")
	}


	/// A negative duration survives a round trip. It did NOT before: the formatter writes "-0:00:05.500", and the
	/// parser read the minus as belonging to the hours component - where -0.0 times 3600 is -0.0, so the sign
	/// vanished without trace and -5.5 came back as +5.5.
	///
	/// Nothing caught it, because the round trip test only used non-negative values. That gap is the reason this
	/// test exists separately rather than as another entry in it.

	@Test("A negative duration survives a round trip", arguments:
	[-0.5, -1.5, -5.5, -60.0, -3661.5, -86399.0])

	func testNegativeRoundTrip(_ seconds:Double)
	{
		let string = seconds.timecodeString()

		#expect(string.hasPrefix("-"), "\(seconds) formatted as \(string)")
		#expect(string.timecodeValue() == seconds, "\(seconds) became \(string)")
	}


//----------------------------------------------------------------------------------------------------------------------


	// MARK: - Round trip


	/// The two directions are inverse at the default 1000 fps, which is what makes the pair usable for a text
	/// field the user can type into.

	@Test("Formatting and parsing round trip at the default frame rate", arguments:
	[0.0, 0.5, 1.5, 59.5, 60.0, 61.25, 3661.5, 86399.0])

	func testRoundTrip(_ seconds:Double)
	{
		let string = seconds.timecodeString()

		#expect(isAboutEqual(string.timecodeValueInSeconds(), seconds, epsilon:Self.epsilon), "\(seconds) became \(string)")
	}


	/// But NOT at any other frame rate: the frames field is read back as a fraction of a second, so the value
	/// changes. Only fps 1000 is safe to hand to the parser.

	@Test("The round trip does not hold at other frame rates")

	func testRoundTripFailsAtOtherFrameRates()
	{
		let string = 1.5.timecodeString(fps:30)

		#expect(string == "0:00:01.15")
		#expect(string.timecodeValueInSeconds() == 1.15)
	}
}


//----------------------------------------------------------------------------------------------------------------------
