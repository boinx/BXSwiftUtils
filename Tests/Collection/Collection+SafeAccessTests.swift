//
//  Collection+SafeAccessTests.swift
//  BXSwiftUtils
//
//  Copyright © 2026 Boinx Software Ltd. & Imagine GbR. All rights reserved.
//

import Testing
import Foundation
@testable import BXSwiftUtils


//----------------------------------------------------------------------------------------------------------------------


/// The `safe` subscripts exist so that an out-of-range access answers nil or an empty slice instead of trapping, which
/// makes "what counts as out of range" the whole of their behavior.
///
/// Two things are easy to get wrong here and neither is visible from an Array of five strings. Indices are ABSOLUTE:
/// on a slice they are the parent's, not zero based, so a caller thinking in offsets asks for something else than it
/// means. And the bounds arrive as arbitrary integers, so they can be far outside anything the collection could
/// address - including values whose successor does not exist.

@Suite("Collection+SafeAccess")

struct Collection_SafeAccessTests
{
	static let data = ["hello", "world", "one", "two", "three"]
	static let empty:[String] = []


//----------------------------------------------------------------------------------------------------------------------


	// MARK: - A single element


	@Test("A single element is returned or nil", arguments:
	[
		// index, expected element
		(0, "hello"),
		(4, "three"),
		(5, nil),				// one past the end
		(1337, nil),
		(-1, nil),				// negative, which the original suite never tried
		(Int.min, nil),
		(Int.max, nil),
	])

	func testSingleElement(_ index:Int, _ expected:String?)
	{
		#expect(Self.data[safe:index] == expected)
	}


	@Test("An empty collection has no element at any index", arguments:[-1, 0, 1])

	func testEmptyCollectionHasNoElement(_ index:Int)
	{
		#expect(Self.empty[safe:index] == nil)
	}


//----------------------------------------------------------------------------------------------------------------------


	// MARK: - Ranges


	@Test("A half-open range is clamped into the collection", arguments:
	[
		(0..<2, ["hello", "world"]),
		(0..<1, ["hello"]),
		(2..<5, ["one", "two", "three"]),
		(2..<10, ["one", "two", "three"]),		// clamped at the end
		(-1..<2, ["hello", "world"]),			// clamped at the start
		(-10..<10, ["hello", "world", "one", "two", "three"]),
		(2..<2, []),							// empty range inside the collection
		(10..<20, []),							// entirely above
		(-20..<(-10), []),						// entirely below
	])

	func testHalfOpenRange(_ range:Range<Int>, _ expected:[String])
	{
		#expect(Array(Self.data[safe:range]) == expected)
	}


	@Test("A closed range is clamped into the collection", arguments:
	[
		(0...1, ["hello", "world"]),
		(1...1, ["world"]),
		(2...4, ["one", "two", "three"]),
		(2...10, ["one", "two", "three"]),		// clamped at the end
		(-1...1, ["hello", "world"]),			// clamped at the start
		(-10...10, ["hello", "world", "one", "two", "three"]),
		(10...20, []),							// entirely above
		(-20...(-10), []),						// entirely below
	])

	func testClosedRange(_ range:ClosedRange<Int>, _ expected:[String])
	{
		#expect(Array(Self.data[safe:range]) == expected)
	}


	@Test("An empty collection yields an empty slice for any range")

	func testEmptyCollectionYieldsEmptySlices()
	{
		#expect(Array(Self.empty[safe:(-10)..<10]) == [])
		#expect(Array(Self.empty[safe:(-10)...10]) == [])
		#expect(Array(Self.empty[safe:0..<0]) == [])
		#expect(Array(Self.empty[safe:0...0]) == [])
	}


	/// The two range overloads describe the same span differently, so `a..<b` and `a...(b-1)` must agree. Asserted as
	/// a relationship rather than two tables, since a table can be updated on one side only.

	@Test("The two range overloads agree", arguments:[-3, -1, 0, 1, 2, 4, 7])

	func testRangeOverloadsAgree(_ lower:Int)
	{
		for upper in [lower, lower+1, lower+3, 10]
		{
			let halfOpen = Array(Self.data[safe:lower..<(upper+1)])
			let closed = Array(Self.data[safe:lower...upper])

			#expect(halfOpen == closed, "\(lower)..<\(upper+1) vs \(lower)...\(upper)")
		}
	}


//----------------------------------------------------------------------------------------------------------------------


	// MARK: - Bounds with no successor


	/// FIXED. `list[safe: 0...Int.max]` used to CRASH.
	///
	/// The closed range overload converted its inclusive bound to a half-open one with `index(after:)`, which on an
	/// Int indexed collection is addition - and adding one to Int.max overflows and traps. A subscript named `safe`
	/// crashing on a bound a caller is free to pass is the sharpest form of the bug this whole family exists to
	/// prevent, and it needed no exotic collection: a plain Array of five strings was enough.
	///
	/// The half-open overload never had it, because it does no index arithmetic at all.

	@Test("An extreme upper bound does not overflow")

	func testExtremeUpperBound()
	{
		#expect(Array(Self.data[safe:0...Int.max]) == Self.data)
		#expect(Array(Self.data[safe:(-1)...Int.max]) == Self.data)
		#expect(Array(Self.data[safe:Int.max...Int.max]) == [])

		#expect(Array(Self.data[safe:0..<Int.max]) == Self.data)
		#expect(Array(Self.data[safe:Int.min..<Int.max]) == Self.data)

		#expect(Array(Self.empty[safe:0...Int.max]) == [])
	}


	/// The lower bound has the same shape from the other end - `index(after:)` must not be reached with a bound far
	/// below the collection either, since nothing says a Collection's index type can go there.

	@Test("An extreme lower bound does not underflow")

	func testExtremeLowerBound()
	{
		#expect(Array(Self.data[safe:Int.min...(-1)]) == [])
		#expect(Array(Self.data[safe:Int.min...2]) == ["hello", "world", "one"])
		#expect(Array(Self.data[safe:Int.min..<0]) == [])
	}


//----------------------------------------------------------------------------------------------------------------------


	// MARK: - Slices, where indices are not zero based


	/// PINS CURRENT BEHAVIOR, and it is the trap most likely to catch a caller. A slice keeps its PARENT's indices,
	/// so `slice[safe:0]` is not "the first element of the slice" - it is index 0, which the slice does not have.
	///
	/// This is correct rather than broken: `indices.contains` is exactly the right question. It is pinned because it
	/// is surprising, because nothing in the old suite touched a slice at all, and because the obvious "fix" someone
	/// might reach for - treating the index as an offset - would silently change what every existing caller means.

	@Test("A slice keeps the parent's indices")

	func testSliceIndicesAreAbsolute()
	{
		let slice = Self.data[2...]			// ["one", "two", "three"], startIndex 2

		#expect(slice.startIndex == 2)
		#expect(slice[safe:0] == nil, "index 0 is not an index this slice has")
		#expect(slice[safe:2] == "one")
		#expect(slice[safe:4] == "three")
		#expect(slice[safe:5] == nil)
	}


	/// The same for ranges: a range is clamped into the slice's own index space rather than being read as an offset,
	/// so asking a slice for 0..<3 gives whatever part of 0..<3 the slice actually covers - here just index 2.

	@Test("A range is clamped into the slice's own indices")

	func testSliceRangesAreAbsolute()
	{
		let slice = Self.data[2...]

		#expect(Array(slice[safe:0..<3]) == ["one"])
		#expect(Array(slice[safe:0..<2]) == [])
		#expect(Array(slice[safe:2..<5]) == ["one", "two", "three"])
		#expect(Array(slice[safe:0...10]) == ["one", "two", "three"])
	}


	/// PINS CURRENT BEHAVIOR. An empty result from the out-of-range path comes back as `prefix(0)`, whose indices
	/// start at the collection's start - not at the position that was asked for.
	///
	/// Harmless for the usual `Array(...)` or `isEmpty` use, and worth knowing for anything that reads the indices of
	/// the result: two empty slices from this subscript are not necessarily interchangeable.

	@Test("An out-of-range slice starts at the beginning")

	func testEmptySliceFromTheOutOfRangePath()
	{
		#expect(Self.data[safe:10..<20].startIndex == 0)
		#expect(Self.data[5..<5].startIndex == 5, "the natural empty slice at that position")
	}


//----------------------------------------------------------------------------------------------------------------------


	// MARK: - Beyond Array


	/// The extension is on `Collection`, so it is not about arrays. Nothing in the old suite used anything else,
	/// which left the index handling untested for a type whose indices are not integers at all.

	@Test("Any Collection can be accessed safely")

	func testNonArrayCollection()
	{
		let string = "hello"
		let third = string.index(string.startIndex, offsetBy:3)

		#expect(string[safe:string.startIndex] == "h")
		#expect(string[safe:string.endIndex] == nil)
		#expect(String(string[safe:string.startIndex..<third]) == "hel")
		#expect(String(string[safe:string.startIndex...third]) == "hell")

		// A range reaching past the end is clamped rather than trapping, same as for an Array

		#expect(String(string[safe:string.startIndex..<string.endIndex]) == "hello")
	}
}


//----------------------------------------------------------------------------------------------------------------------
