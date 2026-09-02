//
//  Comparable+ClipTests.swift
//  BXSwiftUtils
//
//  Copyright © 2026 Boinx Software Ltd. & Imagine GbR. All rights reserved.
//

import Testing
import Foundation
@testable import BXSwiftUtils


//----------------------------------------------------------------------------------------------------------------------


/// `clipped` is one of the most widely used helpers in this framework, and its ordinary behavior is easy to reason
/// about. The interesting parts are the ones the original suite did not reach: bounds that are not in order, and a
/// value that no comparison can order at all.
///
/// The four entry points are two pairs - a mutating `clip` and a non-mutating `clipped`, each taking either
/// `min:max:` or a `ClosedRange`. Everything funnels into `clip(min:max:)`, so the tests below assert the funnel and
/// then that the other three agree with it.

@Suite("Comparable+Clip")

struct Comparable_ClipTests
{
	// MARK: - Clipping into a real range


	/// The ordinary cases, including both boundaries - a value exactly ON a bound must be left alone, since the range
	/// is closed.

	@Test("A value is clipped into the range", arguments:
	[
		// value, lower, upper, expected
		(5.0, 0.0, 10.0, 5.0),		// inside
		(5.0, 0.0, 5.0, 5.0),		// exactly on the upper bound
		(5.0, 5.0, 10.0, 5.0),		// exactly on the lower bound
		(5.0, 0.0, 4.0, 4.0),		// above
		(5.0, 6.0, 10.0, 6.0),		// below
		(7.0, 3.0, 3.0, 3.0),		// a range holding a single value
		(-5.0, -4.0, 10.0, -4.0),	// negatives order the same way
	])

	func testClippingIntoARange(_ value:Double, _ lower:Double, _ upper:Double, _ expected:Double)
	{
		#expect(value.clipped(min:lower, max:upper) == expected)
		#expect(value.clipped(to:lower...upper) == expected)

		var mutatedByBounds = value
		mutatedByBounds.clip(min:lower, max:upper)
		#expect(mutatedByBounds == expected)

		var mutatedByRange = value
		mutatedByRange.clip(to:lower...upper)
		#expect(mutatedByRange == expected)
	}


	/// The four entry points are one implementation and three callers, so the property worth asserting is that they
	/// AGREE - not that each of them separately produces some remembered number.

	@Test("All four entry points agree", arguments:[-100.0, -1.0, 0.0, 0.5, 1.0, 99.0])

	func testEntryPointsAgree(_ value:Double)
	{
		let reference = value.clipped(min:0.0, max:1.0)

		var mutating = value
		mutating.clip(min:0.0, max:1.0)

		var mutatingRange = value
		mutatingRange.clip(to:0.0...1.0)

		#expect(value.clipped(to:0.0...1.0) == reference)
		#expect(mutating == reference)
		#expect(mutatingRange == reference)
	}


//----------------------------------------------------------------------------------------------------------------------


	// MARK: - Bounds that are not a range


	/// FIXED. Inverted bounds used to return a value OUTSIDE the range the caller asked for, and which of the two
	/// bounds you got depended on the input - with min:10 max:0, a 5 came back as 10, a 20 as 0 and a -5 as 10.
	///
	/// The function had raised an NSException for `min > max` until July 2023, when it was removed because crashing
	/// on a customer machine is not an acceptable answer either - so some caller really does pass inverted bounds.
	/// Neither a crash nor a wrong answer was the third option: ordering the bounds first.

	@Test("Inverted bounds give the same answer as ordered ones", arguments:
	[
		// value, and the expected result for the bounds 10 and 0 in EITHER order
		(5.0, 5.0),			// between the two - untouched
		(20.0, 10.0),		// above both - down to the larger bound
		(-5.0, 0.0),		// below both - up to the smaller bound
		(0.0, 0.0),			// exactly on a bound
		(10.0, 10.0),		// exactly on the other
	])

	func testInvertedBoundsAreOrdered(_ value:Double, _ expected:Double)
	{
		#expect(value.clipped(min:10.0, max:0.0) == expected)
		#expect(value.clipped(min:0.0, max:10.0) == expected)

		var mutated = value
		mutated.clip(min:10.0, max:0.0)
		#expect(mutated == expected)
	}


	/// The general statement of the same thing: the bounds are an unordered PAIR, so swapping them cannot change the
	/// answer. This is the property the fix establishes - the table above is one instance of it.
	///
	/// Stated over a spread of values and bound pairs because the old behavior was not uniformly wrong: for a value
	/// already inside the range, inverted bounds happened to return the larger bound rather than the value, so a
	/// single well-chosen example could have passed either way.

	@Test("Swapping the bounds cannot change the answer", arguments:
	[
		-100.0, -1.0, -0.5, 0.0, 0.5, 1.0, 7.0, 100.0,
	])

	func testBoundsAreAnUnorderedPair(_ value:Double)
	{
		for (a,b) in [(0.0,1.0), (-1.0,1.0), (3.0,3.0), (-10.0,-5.0)]
		{
			#expect(value.clipped(min:a, max:b) == value.clipped(min:b, max:a), "bounds \(a),\(b) for \(value)")

			// ...and the ordered spelling is the one the range overload is restricted to, so it has to agree too

			#expect(value.clipped(min:b, max:a) == value.clipped(to:Swift.min(a,b)...Swift.max(a,b)))
		}
	}


	/// The RANGE overloads never had the problem: `ClosedRange` will not build with `upperBound < lowerBound`, so
	/// they could not express inverted bounds in the first place. That is now a redundancy rather than the only
	/// defense, but it is still the reason to prefer `clipped(to:)` where a caller has the choice - the bad call is
	/// rejected at the type level instead of being quietly repaired.
	///
	/// The inverted range itself is NOT PINNED BY A TEST: forming it traps, and a trap takes the whole test process
	/// with it rather than failing one case.

	@Test("The range overload is bounded by its own type")

	func testRangeOverloadCannotBeInverted()
	{
		// A range built the right way round behaves; the wrong way round is unrepresentable, hence untestable

		#expect(5.0.clipped(to:0.0...10.0) == 5.0)
	}


//----------------------------------------------------------------------------------------------------------------------


	// MARK: - Values no comparison can order


	/// PINS CURRENT BEHAVIOR. A NaN passes through UNCHANGED - clipping does not sanitize it.
	///
	/// Both comparisons in `clip` are false for a NaN, so neither branch is taken. That is worth stating explicitly
	/// because "clip it into a valid range" reads like a safety measure, and for the one value that most needs
	/// catching it does nothing at all. FMTransform.validZoom relies on this: it calls `validated(fallbackValue:)`
	/// FIRST and only then clips, precisely because the clip alone would let a NaN straight through.

	@Test("A NaN is not clipped")

	func testNaNPassesThrough()
	{
		#expect(Double.nan.clipped(min:0.0, max:10.0).isNaN)
		#expect(Double.nan.clipped(to:0.0...10.0).isNaN)
	}


	/// PINS CURRENT BEHAVIOR. A NaN BOUND is ignored rather than refused, so the value comes back untouched even
	/// though it was never compared against anything meaningful.
	///
	/// The two cases differ in why: against a NaN lower bound the first comparison is false and the second is a real
	/// test that happens to pass; against a NaN upper bound the value genuinely is above the lower bound and then
	/// fails an unorderable comparison. Both look like a successful clip from the outside.
	///
	/// This also guards the ordering fix above. Ordering the bounds with Swift.min and Swift.max would have broken
	/// exactly this case - both answer 0 for the pair (0, NaN), which would turn a bound nothing can order into a
	/// hard clamp to the other one, silently changing 5 into 0. The single comparison used instead is false for a
	/// NaN, so the bounds stay as given.

	@Test("A NaN bound is ignored", arguments:
	[
		(Double.nan, 10.0),
		(0.0, Double.nan),
		(Double.nan, Double.nan),
	])

	func testNaNBoundsAreIgnored(_ lower:Double, _ upper:Double)
	{
		#expect(5.0.clipped(min:lower, max:upper) == 5.0)
	}


	/// Infinities ARE ordered, so unlike a NaN they clip exactly as any other out-of-range value would. This is the
	/// case that makes the NaN behavior above look like an oversight rather than a policy: two of the three
	/// non-finite values are handled, and the third is not.

	@Test("Infinities are clipped like any other value")

	func testInfinitiesAreClipped()
	{
		#expect(Double.infinity.clipped(to:0.0...10.0) == 10.0)
		#expect((-Double.infinity).clipped(to:0.0...10.0) == 0.0)

		// ...and an infinite BOUND is a real bound, not a missing one

		#expect(5.0.clipped(min:-Double.infinity, max:Double.infinity) == 5.0)
		#expect(Double.infinity.clipped(min:0.0, max:Double.infinity).isInfinite)
	}


//----------------------------------------------------------------------------------------------------------------------


	// MARK: - Beyond numbers


	/// A Comparable whose ordering looks at only PART of its value, so that two instances can compare equal and
	/// still be told apart. Nothing numeric can do that, which is why the strictness of the bound comparison is
	/// invisible until a type like this is used.

	struct Tagged : Comparable
	{
		let value:Double
		let tag:String

		static func < (lhs:Tagged, rhs:Tagged) -> Bool { lhs.value < rhs.value }
		static func == (lhs:Tagged, rhs:Tagged) -> Bool { lhs.value == rhs.value }
	}


	/// Bounds that compare EQUAL must not be swapped, because neither one is less than the other.
	///
	/// Found by mutation: loosening the ordering comparison from `<` to `<=` survived every other test in this suite.
	/// For numbers it genuinely cannot be observed - two equal Doubles are the same value - so this is the one case
	/// where the generic signature is not just a nicety but the only way to state what the function does.

	@Test("Bounds that compare equal keep their order")

	func testEqualBoundsAreNotSwapped()
	{
		let first = Tagged(value:5.0, tag:"first")
		let second = Tagged(value:5.0, tag:"second")

		// The value is below both bounds, so the LOWER one is what comes back - and which instance that is says
		// whether the pair was swapped on the way in

		let result = Tagged(value:0.0, tag:"value").clipped(min:first, max:second)

		#expect(result.tag == "first", "the bounds were swapped, though neither is less than the other")
	}


	/// The extension is on `Comparable`, not on a numeric protocol, so it applies to anything orderable. The original
	/// suite only ever used Double, which left the genericity - the reason it is written this way at all - untested.

	@Test("Any Comparable can be clipped")

	func testNonNumericComparable()
	{
		#expect("m".clipped(min:"a", max:"f") == "f")
		#expect("c".clipped(min:"a", max:"f") == "c")
		#expect("A".clipped(to:"a"..."f") == "a")		// uppercase sorts before lowercase

		let epoch = Date(timeIntervalSince1970:0)
		let later = Date(timeIntervalSince1970:100)
		let between = Date(timeIntervalSince1970:50)

		#expect(between.clipped(to:epoch...later) == between)
		#expect(Date(timeIntervalSince1970:1000).clipped(to:epoch...later) == later)
	}
}


//----------------------------------------------------------------------------------------------------------------------
