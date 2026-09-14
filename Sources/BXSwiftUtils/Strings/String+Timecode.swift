//**********************************************************************************************************************
//
//  String+Timecode.swift
//	Extension for displaying and parsing time codes
//  Copyright ©2018-2026 Peter Baumgartner. All rights reserved.
//
//**********************************************************************************************************************


import Foundation


//----------------------------------------------------------------------------------------------------------------------


extension Double
{
	/// The placeholder returned instead of a timecode when the value cannot be represented.
	///
	/// Dashes follow the convention media players use for an unknown duration (QuickTime, the Music app, VLC and
	/// HTML5 players all show them when a duration is NaN or not yet known). They are deliberately NOT "0:00:00":
	/// a placeholder must not be mistakable for a real value, and a zero duration is a perfectly ordinary one.
	///
	/// The shape follows the format - same separators, same number of fraction digits - so the placeholder reads as
	/// a timecode that is simply not known. It cannot match the width of EVERY timecode, because the hours field is
	/// variable width (`%i`): "9:00:00.000" is one character shorter than "10:00:00.000". Two dashes are used for
	/// the hours, matching the two-digit case, rather than one dash that could be misread as the minus sign a
	/// negative duration now carries.
	///
	/// `showsHours` and `showsFraction` must match the arguments the string is standing in for, or the placeholder
	/// stops looking like the timecode it replaces - which is the only thing that makes it readable as one.
	
	public static func invalidTimecodeString(fps:Int = 1000, showsHours:Bool = true, showsFraction:Bool = true) -> String
	{
		let fields = showsHours ? "--:--:--" : "--:--"
		
		guard showsFraction else { return fields }
		
		return fps > 100 ? fields + ".---" : fields + ".--"
	}
	
	/// The placeholder for the short form
	
	public static let invalidShortTimecodeString = "--:--:--"
	
	/// The largest magnitude that will be rendered as a timecode.
	///
	/// The hours field goes through `Int(_:)`, which TRAPS rather than saturating, and the value is divided by
	/// 3600 before it gets there. This ceiling sits many orders of magnitude below the point where that would
	/// actually overflow, which leaves no room for a rounding error to sneak past it - and 1e15 seconds is around
	/// 32 million years, so nothing a caller could legitimately mean is being excluded.
	
	public static let maximumTimecodeSeconds = 1.0e15
	
	/// The largest tick count that can be converted to Int.
	///
	/// `maximumTimecodeSeconds` alone is not enough, because the seconds are multiplied by the frame rate before
	/// the conversion - and `fps` is a caller-supplied Int, so a large enough one overflows even a modest duration.
	
	public static let maximumTimecodeTicks = 9.0e18
	
	
	/// Converts the number of seconds into a timecode string of format "HH:MM:SS.ff"
	///
	/// A value that cannot be represented - NaN, an infinity, or a magnitude beyond `maximumTimecodeSeconds` -
	/// yields `invalidTimecodeString(fps:showsHours:showsFraction:)` rather than crashing. It used to crash:
	/// `Int(_:)` traps on a non-finite operand instead of saturating, so a NaN duration took the process down.
	///
	/// A negative value is formatted from its magnitude with a leading minus, e.g. "-0:00:05.500". Previously the
	/// sign leaked into the individual fields and produced unparseable output like "0:00:-5.-500".
	///
	/// A frame rate of zero or less has no meaning and yields the placeholder rather than dividing by it.
	///
	/// `showsHours` and `showsFraction` select which fields are printed, which is what lets a single implementation
	/// serve every shape the apps need - including BXTimeCodeFormatter, which used to carry its own copy of this
	/// arithmetic and therefore its own copy of the trap described above.
	///
	/// With the hours hidden the minutes field holds the TOTAL minutes rather than minutes past the hour, so
	/// nothing is silently discarded. Wrapping it would render 1h15m as "15:00", which is not a shorter way of
	/// saying the same thing - it is indistinguishable from a genuine fifteen minutes.
	
	public func timecodeString(fps:Int = 1000, showsHours:Bool = true, showsFraction:Bool = true) -> String
	{
		// The `isFinite` test is deliberately redundant: `abs(nan) <= x` is already false, since every comparison
		// against NaN is, and an infinity exceeds any ceiling. It is kept because it states the intent - a mutation
		// that removes it cannot be caught by a test, so only this note stops it being "simplified" away on the
		// assumption that the magnitude check was doing that work by accident.
	
		guard self.isFinite, abs(self) <= Self.maximumTimecodeSeconds, fps > 0
		else { return Self.invalidTimecodeString(fps:fps, showsHours:showsHours, showsFraction:showsFraction) }
		
		let magnitude = abs(self)
		let totalSeconds:Int
		let ff:Int
		
		if showsFraction
		{
			// Decompose from an integer tick count instead of repeatedly subtracting and dividing in floating point.
			// The old arithmetic accumulated representation error: 3599.999 came out as "0:59:59.998", because 0.999
			// times 1000 is 998.99999999 in binary and Int(_:) truncated it - losing a millisecond that the value
			// genuinely had. Scaling and rounding ONCE, up front, removes that.
			//
			// It also makes the carry work. Rounding the fraction on its own would produce a field that does not fit:
			// 59.9999 would round to 1000 thousandths and print "0:00:59.1000". Going through a tick count instead
			// carries properly into the seconds, so it prints "0:01:00.000".
			//
			// Note this rounds to the NEAREST tick rather than truncating towards the current one. A value sitting
			// exactly on a half tick therefore rounds away from zero - at 25 fps, 2.5s is frame 62.5 and becomes 63.
			
			let scaled = (magnitude * Double(fps)).rounded()
			
			guard scaled <= Self.maximumTimecodeTicks
			else { return Self.invalidTimecodeString(fps:fps, showsHours:showsHours, showsFraction:showsFraction) }
			
			let ticks = Int(scaled)
			totalSeconds = ticks / fps
			ff = ticks % fps
		}
		else
		{
			// Without a fraction field the magnitude is FLOORED rather than rounded through a tick count. Rounding
			// here would push a value up into a second whose precision is not being shown - 59.6 would read as
			// "0:01:00" - and it would break the short form's documented truncation towards zero.
			
			totalSeconds = Int(floor(magnitude))
			ff = 0
		}
		
		let SS = totalSeconds % 60
		let MM = showsHours ? (totalSeconds/60) % 60 : totalSeconds/60
		let HH = totalSeconds / 3600
		
		var string = ""
		
		if showsHours
		{
			string = NSString(format:"%i:%02i:%02i" as NSString,HH,MM,SS) as String
		}
		else
		{
			string = NSString(format:"%02i:%02i" as NSString,MM,SS) as String
		}
		
		if showsFraction
		{
			let format = fps > 100 ? ".%03i" : ".%02i"
			string += NSString(format:format as NSString,ff) as String
		}
		
		return self < 0.0 ? "-" + string : string
	}


	/// Converts the number of seconds into a timecode string of format "HH:MM:SS"
	///
	/// Same guards as `timecodeString(fps:)`. Note that the magnitude is floored, so a negative value truncates
	/// TOWARDS zero - -5.5 is "-0:00:05" rather than "-0:00:06" - which is the usual reading for a signed duration.
	
	public func shortTimecodeString() -> String
	{
		return self.timecodeString(showsFraction:false)
	}
}


//----------------------------------------------------------------------------------------------------------------------


extension String
{
	/// Converts a timecode string of format "HH:MM:SS.sss" to the time in seconds, or nil if it is not one.
	///
	/// Components are read right to left as seconds, minutes, hours and days, so a string may carry as few of them
	/// as it likes: "90", "1:30" and "0:01:30" all mean ninety seconds.
	///
	/// The fourth component is DAYS, worth 24 hours. It used to be worth 60 hours: the old loop simply multiplied
	/// its factor by sixty for every component, which is right up to hours and wrong after that. "1:00:00:00" came
	/// back as 216000 seconds instead of 86400.
	///
	/// A fifth component has no meaning at all, so more than four is rejected rather than silently scaled by
	/// another sixty.
	///
	/// A leading "-" or "+" applies to the WHOLE timecode, which is how every system that has a signed timecode
	/// writes it: SMPTE has no negative form at all, the NLEs display offsets as "-01:00:00:00", and ISO 8601
	/// durations are "-PT1M30S". An individual component may NOT carry a sign - "0:-2:-1" is rejected rather than
	/// quietly subtracting the middle of a timecode from its end.
	///
	/// This also closes a round trip hole. `timecodeString` writes a negative duration as "-0:00:05.500", and that
	/// used to parse back as POSITIVE 5.5: the minus landed on a "-0" hours component, and -0.0 times 3600 is
	/// -0.0, so the sign disappeared without trace.
	///
	/// EVERY component has to be a number. This used to be lenient in a way that produced wrong answers rather
	/// than no answer: an unreadable component was skipped while its sixty-times factor still advanced, so the
	/// remaining components kept their place value. A single leading space was enough - `Double(" 1")` is nil, so
	/// " 1:30" silently lost its minutes and came back as 30 seconds instead of 90.
	///
	/// Surrounding whitespace is now trimmed, so " 1:30" is simply ninety seconds. Anything still unreadable makes
	/// the whole string invalid.
	///
	/// A non-finite RESULT is rejected too. Swift's Double parser accepts "nan", "inf" and "infinity", so without
	/// this "inf:30" would yield an infinity and hand it to whatever consumed the result - and even all-finite
	/// components can overflow, as "1e308:0" does. (The parser also accepts hex like "0x10" and exponents like
	/// "1e3"; those are left alone, since they at least denote a real, finite number.)
	
	public func timecodeValue() -> Double?
	{
		// Seconds, minutes, hours, days. Spelled out rather than derived by repeatedly multiplying by sixty,
		// because that is precisely where the old version went wrong - the step from hours to days is 24, not 60.
		
		let factors:[Double] = [1.0, 60.0, 3600.0, 86400.0]
		
		// The sign is taken off the front once, before anything is split. Leaving it attached would make it a
		// property of whichever component happened to come first, which is both wrong and invisible.
		
		var body = self.trimmingCharacters(in:.whitespaces)
		var sign = 1.0
		
		if body.hasPrefix("-")
		{
			sign = -1.0
			body.removeFirst()
		}
		else if body.hasPrefix("+")
		{
			body.removeFirst()
		}
		
		var value = 0.0
		let components = body.components(separatedBy:":")
		
		// Load-bearing, not just semantic: the loop indexes `factors` directly, so without this a fifth component
		// would run off the end of the array and trap rather than return nil.
		
		guard components.count <= factors.count else { return nil }

		for (index,component) in components.reversed().enumerated()
		{
			let trimmed = component.trimmingCharacters(in:.whitespaces)
			
			// A component must be plain decimal digits, with at most one decimal point. Double(_:) alone is far
			// more permissive than a timecode should be: it accepts "0x10" as 16, "1e3" as 1000, and "nan" and
			// "inf" as themselves. None of those is anything a person would type into a timecode field, and each
			// of them reads as a number that is not the one it looks like.
			//
			// This also subsumes the per-component sign rule - a "+" or "-" is not a digit - so there is no
			// separate check for it.
			
			guard Self.isDecimalComponent(trimmed) else { return nil }
			guard let v = Double(trimmed) else { return nil }
			
			value += factors[index] * v
		}
		
		// One check at the end covers both ways the result can go non-finite: a component that spelled "nan" or
		// "inf" (any such component makes the total non-finite too), and finite components whose sum overflows -
		// "1e308:0" is all finite and still lands on infinity. A per-component test would only duplicate the
		// first half, and nothing could tell the two versions apart.
		
		guard value.isFinite else { return nil }
		
		return sign * value
	}


	/// Returns true if the string is plain decimal digits with at most one decimal point, e.g. "30", "05" or
	/// "05.500".
	///
	/// Written out rather than handed to Double(_:) because that parser is deliberately liberal - it takes hex,
	/// exponents, and the words "nan" and "inf" - and a timecode component is none of those things.
	///
	/// ASCII digits only. `Character.isNumber` is true for other scripts' digits too, and "٥" is not something a
	/// timecode field should quietly accept as five.
	///
	/// Two parts of this cannot be caught by a test, because Double(_:) happens to reject the same input a moment
	/// later: the ASCII restriction (it parses neither "٥" nor the full width "１") and the single-point rule (it
	/// rejects "1.2.3"). They are kept anyway, because this predicate answers "is this a plain decimal component"
	/// and it should answer correctly on its own - leaning on the parser downstream would make it wrong in a way
	/// that only shows up when someone stops calling the parser. The parts that ARE load-bearing are the ones
	/// where Double is more liberal than a timecode: it takes "0x10", "1e3", "nan", "inf", and both "5." and ".5".
	
	private static func isDecimalComponent(_ string:String) -> Bool
	{
		var digitsBeforePoint = 0
		var digitsAfterPoint = 0
		var seenPoint = false
		
		for character in string
		{
			if character == "."
			{
				guard !seenPoint else { return false }
				seenPoint = true
			}
			else if character.isASCII, character.isNumber
			{
				if seenPoint { digitsAfterPoint += 1 } else { digitsBeforePoint += 1 }
			}
			else
			{
				return false
			}
		}
		
		// "5." and ".5" are both rejected: a timecode component has digits on both sides of its point, or no
		// point at all.
		
		guard digitsBeforePoint > 0 else { return false }
		guard !seenPoint || digitsAfterPoint > 0 else { return false }
		
		return true
	}


	/// Converts a timecode string of format "HH:MM:SS.sss" to the time in seconds, treating anything unreadable
	/// as zero.
	///
	/// Kept for callers that have no way to report a failure, such as a value transformer. Prefer
	/// `timecodeValue()` where nil can be acted on - zero is a perfectly ordinary timecode, so this cannot
	/// distinguish "0:00:00" from nonsense.
	
	public func timecodeValueInSeconds() -> Double
	{
		return self.timecodeValue() ?? 0.0
	}
}


//----------------------------------------------------------------------------------------------------------------------

