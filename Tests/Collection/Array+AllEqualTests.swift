//
//  Array+AllEqualTests.swift
//  BXSwiftUtils
//
//  Copyright © 2026 Boinx Software Ltd. & Imagine GbR. All rights reserved.
//

import Testing
import Foundation
@testable import BXSwiftUtils


//----------------------------------------------------------------------------------------------------------------------


/// `allEqual(to:)` answers a THREE-valued question - yes, no, or "there was nothing to compare" - which is the whole
/// reason it returns an optional rather than defaulting an empty array to true the way `allSatisfy` does.

@Suite("Array+AllEqual")

struct Array_AllEqualTests
{
	@Test("All elements are compared against the value", arguments:
	[
		([1, 1, 1], true),
		([1, 1, 2], false),
		([2, 1, 1], false),			// the mismatch at the FRONT must be found too
		([1], true),
		([2], false),
	])

	func testAllEqual(_ values:[Int], _ expected:Bool)
	{
		#expect(values.allEqual(to:1) == expected)
	}


	/// An empty array answers nil rather than true. Vacuous truth is what `allSatisfy` gives, and the doc comment says
	/// this returns nil precisely so the caller has to decide what emptiness means where it happens.

	@Test("An empty array has no answer")

	func testEmptyArray()
	{
		#expect([Int]().allEqual(to:1) == nil)
		#expect([String]().allEqual(to:"x") == nil)

		// ...and nil is distinguishable from false, which is the point of the optional

		#expect([2].allEqual(to:1) == false)
	}


	/// It works for anything Equatable, not just numbers - and equality is the type's own, so a type with a custom
	/// `==` is compared the way it defines rather than by identity.

	@Test("Any Equatable is compared by its own ==")

	func testCustomEquatable()
	{
		struct Version : Equatable
		{
			let major:Int
			let minor:Int

			static func == (lhs:Version, rhs:Version) -> Bool { lhs.major == rhs.major }		// minor ignored
		}

		#expect([Version(major:1, minor:0), Version(major:1, minor:9)].allEqual(to:Version(major:1, minor:5)) == true)
		#expect([Version(major:1, minor:0), Version(major:2, minor:0)].allEqual(to:Version(major:1, minor:0)) == false)

		#expect(["a", "a"].allEqual(to:"a") == true)
	}


	/// PINS CURRENT BEHAVIOR. An array of NaN is not "all equal" to NaN, because the test is written as
	/// `contains(where: { $0 != element })` and every comparison against a NaN is false in one direction and true in
	/// the other. So a NaN never equals itself here, exactly as everywhere else in floating point.
	///
	/// Not a defect, and worth stating: `allEqual` reads like a structural question and answers a numeric one.

	@Test("NaN is never equal to itself")

	func testNaN()
	{
		#expect([Double.nan].allEqual(to:Double.nan) == false)
		#expect([Double.nan, Double.nan].allEqual(to:Double.nan) == false)

		// Infinities, by contrast, compare equal to themselves

		#expect([Double.infinity, Double.infinity].allEqual(to:Double.infinity) == true)
	}


	/// The extension is on Array, not on Collection - so a Set or a slice cannot use it, unlike most of this folder.
	/// Pinned by demonstrating the workaround a caller has to reach for.

	@Test("Only Array has this, so other collections need converting")

	func testArrayOnly()
	{
		let slice = [1, 1, 1, 2].dropLast()

		#expect(Array(slice).allEqual(to:1) == true)
		#expect(Array(Set([1])).allEqual(to:1) == true)
	}
}


//----------------------------------------------------------------------------------------------------------------------
