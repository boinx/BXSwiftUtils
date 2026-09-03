//
//  Collection+MathTests.swift
//  BXSwiftUtils
//
//  Copyright ©2026 IMAGINE GbR. All rights reserved.
//


import Testing
import Foundation
import CoreGraphics
@testable import BXSwiftUtils


//----------------------------------------------------------------------------------------------------------------------


/// Fifteen lines of implementation, and almost all of its behavior comes from the two protocols it is constrained to
/// rather than from anything written here. So the questions worth asking are about those: which types actually get
/// these methods, and what arithmetic does each of them bring along.
///
/// `sum()` sits on AdditiveArithmetic, so it inherits INTEGER overflow trapping. `average()` sits on FloatingPoint, so
/// it inherits NaN and infinity instead - the same operation with completely different failure behavior on either
/// side of the constraint.

@Suite("Collection+Math")

struct Collection_MathTests
{
	// MARK: - Summing


	@Test("Values are summed", arguments:
	[
		([1.0, 2.0, 3.5], 6.5),
		([-5.0, 5.0], 0.0),
		([42.0], 42.0),
		([], 0.0),					// .zero is the seed, so an empty collection sums to zero rather than failing
	])

	func testSumOfDoubles(_ values:[Double], _ expected:Double)
	{
		#expect(values.sum() == expected)
	}


	/// `sum()` is constrained to AdditiveArithmetic rather than FloatingPoint, which is the whole reason it is written
	/// with a `.zero` seed instead of a literal - and it is what lets integers use it at all.

	@Test("Integers sum too, because the constraint is AdditiveArithmetic")

	func testSumOfIntegers()
	{
		#expect([1, 2, 3].sum() == 6)
		#expect([-5, 5].sum() == 0)
		#expect([Int]().sum() == 0)
	}


	/// Anything that is a Collection qualifies, not just Array - which nothing had checked, though it is the reason
	/// these are written as protocol extensions.

	@Test("Any Collection can be summed")

	func testOtherCollections()
	{
		#expect([1, 2, 3, 4].dropFirst().sum() == 9)			// a slice
		#expect(Set([1, 2, 3]).sum() == 6)
		let dictionary:[String:Double] = ["a":1.5, "b":2.5]
		#expect(dictionary.values.sum() == 4.0)
		#expect(stride(from:1.0, to:4.0, by:1.0).map { $0 }.sum() == 6.0)
	}


	/// Both floating point widths, and CGFloat, which is the one FotoMagico actually passes most of the time.

	@Test("The floating point width does not matter")

	func testFloatingPointWidths()
	{
		#expect([Float(1.5), Float(2.5)].sum() == Float(4.0))
		#expect([CGFloat(1.5), CGFloat(2.5)].average() == CGFloat(2.0))
	}


//----------------------------------------------------------------------------------------------------------------------


	// MARK: - Averaging


	@Test("Values are averaged", arguments:
	[
		([1.0, 2.0, 3.0], 2.0),
		([2.0, 4.0], 3.0),
		([42.0], 42.0),
		([-1.0, 1.0], 0.0),
	])

	func testAverage(_ values:[Double], _ expected:Double)
	{
		#expect(values.average() == expected)
	}


	/// PINS CURRENT BEHAVIOR. An empty collection averages to NaN - sum is .zero and the divisor is 0, so this is
	/// 0.0/0.0 rather than a trap.
	///
	/// Not a bad answer: NaN says "there is no average of nothing" and propagates through anything that consumes it,
	/// where a zero would quietly look like a real measurement. It does have to be EXPECTED at the call site though,
	/// and it is the reason FMCircularBuffer and the animation code guard their divisors instead of relying on this.

	#warning("PINNED BEHAVIOR: Average of empty collection return NaN")
	
	@Test("An empty collection averages to NaN")

	func testAverageOfEmptyCollection()
	{
		#expect([Double]().average().isNaN)
		#expect([Float]().average().isNaN)
	}


//----------------------------------------------------------------------------------------------------------------------


	// MARK: - What the element type brings with it


	/// PINS A REAL NUMERICAL PROPERTY. `sum()` reduces left to right, and floating point addition is not associative -
	/// so the same values in a different ORDER can give a different answer.
	///
	/// Not a defect to fix; every naive summation has it, and the alternatives (pairwise, Kahan) cost more than this
	/// is worth. Worth stating because the doc comment says "the sum of the elements" as though the order were an
	/// implementation detail, and here it is part of the result.

	#warning("PINNED BEHAVIOR: Sum is not order-independent")

	@Test("Summation is left to right, so order can change the result")

	func testSummationIsOrderDependent()
	{
		let overflowing = [1.0e308, 1.0e308, -1.0e308].sum()
		let reordered = [1.0e308, -1.0e308, 1.0e308].sum()

		#expect(overflowing.isInfinite, "the running total passed the maximum and stayed there")
		#expect(reordered == 1.0e308, "the same values, ordered so that the total never overflows")

		// The everyday version of the same thing: a small value is lost next to a large one

		let smallFirst:[Double] = [1.0, 1.0e17, -1.0e17]
		let smallLast:[Double] = [1.0e17, -1.0e17, 1.0]

		#expect(smallFirst.sum() == 0.0, "the 1.0 was absorbed by the large running total")
		#expect(smallLast.sum() == 1.0, "the same three values, ordered so that nothing is lost")
	}


	/// The `.zero` SEED is not just a way to satisfy AdditiveArithmetic - it also normalises the sign of zero, since
	/// `+0.0 + -0.0` is `+0.0`. Seeding with the first element instead would carry a negative zero straight through.
	///
	/// Found by mutation: rewriting sum() to seed from `first` survived every other test here, because the two agree
	/// on every value except this one - and `==` cannot see the difference either, so it takes `.sign` to state it.
	/// It matters to anyone who divides by the result, where -0.0 turns an infinity negative.

	@Test("The zero seed normalises a negative zero")

	func testNegativeZeroIsNormalised()
	{
		let negativeZero:[Double] = [-0.0]

		#expect(negativeZero.sum() == 0.0, "the value is zero either way")
		#expect(negativeZero.sum().sign == .plus, "the sign of the seed was not applied")

		// ...and the element itself really is a negative zero, so the test is not passing by accident

		#expect(negativeZero[0].sign == .minus)
	}


	/// A NaN anywhere in the collection makes the whole sum - and therefore the average - NaN, since every operation
	/// on a NaN yields one. Worth having stated: a caller who checks the RESULT for NaN cannot tell an empty
	/// collection from one holding a bad measurement.

	@Test("A NaN element propagates to the result")

	func testNaNPropagates()
	{
		#expect([1.0, Double.nan, 3.0].sum().isNaN)
		#expect([1.0, Double.nan, 3.0].average().isNaN)

		// Infinities of opposite sign do the same, by a different route

		#expect([Double.infinity, -Double.infinity].sum().isNaN)
		#expect([Double.infinity, 1.0].sum().isInfinite)
	}


	/// NOT PINNED BY A TEST, because it TRAPS and a trap takes the whole test process with it rather than failing one
	/// case: an integer sum that exceeds the type's range crashes, because AdditiveArithmetic's `+` is the trapping
	/// operator rather than the wrapping one.
	///
	/// So the two halves of this file fail in opposite ways - `[Int.max, 1].sum()` crashes where
	/// `[Double.greatestFiniteMagnitude, .greatestFiniteMagnitude].sum()` quietly returns infinity. A caller summing
	/// something unbounded (a byte count, a duration in ticks) is choosing between those two by choosing a type.

	@Test("A floating point sum saturates where an integer one would trap")

	func testFloatingPointSumSaturates()
	{
		let huge = [Double.greatestFiniteMagnitude, Double.greatestFiniteMagnitude].sum()

		#expect(huge.isInfinite)
		#expect(!huge.isNaN)
	}
}


//----------------------------------------------------------------------------------------------------------------------
