//
//  Collection+Flatten.swift
//  BXSwiftUtils
//
//  Copyright © 2026 Boinx Software Ltd. & Imagine GbR. All rights reserved.
//

import Testing
import Foundation
@testable import BXSwiftUtils


//----------------------------------------------------------------------------------------------------------------------


/// One level of nesting removed, in order, by `reduce([], +)`.

@Suite("Collection+Flatten")

struct Collection_FlattenTests
{
	@Test("One level of nesting is removed, in order", arguments:
	[
		([[1, 2, 3], [4], [], [5, 6]], [1, 2, 3, 4, 5, 6]),
		([[1], [2], [3]], [1, 2, 3]),
		([[], [], []], []),					// every inner collection empty
		([], []),							// nothing at all
		([[1, 2, 3]], [1, 2, 3]),			// a single inner collection
	])

	func testFlatten(_ input:[[Int]], _ expected:[Int])
	{
		#expect(input.flatten() == expected)
	}


	/// ONE level, not all of them - the result of flattening a triply nested array is still nested, which is the
	/// difference between this and a recursive flatten and is not obvious from the name.

	@Test("Only one level is removed")

	func testOnlyOneLevel()
	{
		let deep = [[[1, 2], [3]], [[4]]]

		let once = deep.flatten()

		#expect(once.count == 3)
		#expect(once == [[1, 2], [3], [4]])
		#expect(once.flatten() == [1, 2, 3, 4], "flattening again reaches the elements")
	}


	/// The constraint is `Element: Collection`, so anything nested qualifies - including Strings, whose elements are
	/// Characters, and Sets. Nothing but arrays of arrays had been tried.

	@Test("Any nested Collection can be flattened")

	func testOtherCollections()
	{
		#expect(["ab", "cd"].flatten() == ["a", "b", "c", "d"])

		let sets:[Set<Int>] = [[1], [2]]

		#expect(Set(sets.flatten()) == [1, 2])

		// ...and the OUTER collection need not be an Array either

		#expect(Set([[1, 2]]).flatten() == [1, 2])
	}


	/// Duplicates are kept - this concatenates, it does not merge. Worth stating because the Set case above could
	/// suggest otherwise.

	@Test("Duplicates survive flattening")

	func testDuplicatesAreKept()
	{
		#expect([[1, 1], [1]].flatten() == [1, 1, 1])
	}
}


//----------------------------------------------------------------------------------------------------------------------
