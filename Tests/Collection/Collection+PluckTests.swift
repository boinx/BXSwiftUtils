//
//  Collection+PluckTests.swift
//  BXSwiftUtils
//
//  Copyright © 2026 Boinx Software Ltd. & Imagine GbR. All rights reserved.
//

import Testing
import Foundation
@testable import BXSwiftUtils


//----------------------------------------------------------------------------------------------------------------------


/// Two ways of extracting one property from every element: `pluck` keeps them all in order, `values(for:)` collects
/// them into a Set. The second was untested, and the difference between them is the whole reason both exist.

@Suite("Collection+Pluck")

struct Collection_PluckTests
{
	final class Item : Hashable
	{
		let number:Int
		let name:String

		init(_ number:Int, _ name:String = "") { self.number = number ; self.name = name }

		static func == (lhs:Item, rhs:Item) -> Bool { lhs === rhs }
		func hash(into hasher:inout Hasher) { hasher.combine(ObjectIdentifier(self)) }
	}


	@Test("Values are extracted in order")

	func testPluck()
	{
		let items = [Item(10), Item(42), Item(100)]

		#expect(items.pluck(\.number) == [10, 42, 100])
		#expect(items.pluck(\.name) == ["", "", ""])
	}


	/// PLUCK KEEPS DUPLICATES AND `values(for:)` DOES NOT. That is the difference between them, and neither the Set
	/// overload nor this distinction had a test - so nothing said which one to reach for.

	@Test("pluck keeps duplicates, values(for:) removes them")

	func testDuplicates()
	{
		let items = [Item(1), Item(1), Item(2)]

		#expect(items.pluck(\.number) == [1, 1, 2])
		#expect(items.values(for:\.number) == Set([1, 2]))
		#expect(items.values(for:\.number).count == 2)
	}


	/// `values(for:)` is how a caller asks "do all of these agree?" - a Set of one means they do. That is the use the
	/// doc comment describes, and it is worth a test because the answer is a COUNT rather than a Bool.

	@Test("A single value means the elements agree")

	func testUniformity()
	{
		#expect([Item(5), Item(5), Item(5)].values(for:\.number).count == 1)
		#expect([Item(5), Item(6)].values(for:\.number).count == 2)
		#expect([Item(5)].values(for:\.number).count == 1)
	}


	@Test("An empty collection yields nothing")

	func testEmpty()
	{
		let empty:[Item] = []

		#expect(empty.pluck(\.number) == [])
		#expect(empty.values(for:\.number).isEmpty)
	}


	/// Both are on Collection rather than Array, so a Set or a Dictionary works too. `pluck` on an unordered
	/// collection returns an unordered result, which is why this compares as a Set rather than by position.

	@Test("Any Collection can be plucked")

	func testOtherCollections()
	{
		let set:Set = [Item(10), Item(42), Item(100)]

		#expect(Set(set.pluck(\.number)) == [10, 42, 100])
		#expect(set.values(for:\.number) == [10, 42, 100])

		// A slice, and a Dictionary whose elements are key/value pairs

		#expect([Item(1), Item(2), Item(3)].dropFirst().pluck(\.number) == [2, 3])
		#expect(Set(["a":1, "b":2].pluck(\.value)) == [1, 2])
	}


	/// A key path to an optional comes back as an array of optionals rather than being compacted - `pluck` maps, it
	/// does not filter, so the element count always matches the collection.

	@Test("An optional property keeps its nils")

	func testOptionalKeyPath()
	{
		struct Row { let label:String? }

		let rows = [Row(label:"a"), Row(label:nil), Row(label:"c")]

		#expect(rows.pluck(\.label).count == 3)
		#expect(rows.pluck(\.label)[1] == nil)
	}
}


//----------------------------------------------------------------------------------------------------------------------
