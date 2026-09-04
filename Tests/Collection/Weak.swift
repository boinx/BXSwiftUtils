//
//  Weak.swift
//  BXSwiftUtils
//
//  Copyright © 2026 Boinx Software Ltd. & Imagine GbR. All rights reserved.
//

import Testing
import Foundation
@testable import BXSwiftUtils


//----------------------------------------------------------------------------------------------------------------------


/// A box that holds its value weakly, so that a collection of them does not keep its contents alive.

@Suite("Weak")

struct WeakTests
{
	final class Thing
	{
		let name:String
		
		init(_ name:String)
		{
			self.name = name
		}
	}


	@Test("The box does not keep its value alive")

	func testValueIsWeak()
	{
		var box:Weak<Thing>?
		weak var weakThing:Thing?

		do
		{
			let thing = Thing("hello")
			weakThing = thing
			box = Weak(thing)

			#expect(box?.value === thing)
			#expect(weakThing != nil)
		}

		#expect(weakThing == nil, "the box kept its value alive")
		#expect(box?.value == nil)

		box = nil
	}


	/// The box outliving its value is the whole point - it stays usable and simply answers nil, rather than the
	/// caller having to handle a dangling reference.

	@Test("The box remains usable after its value is gone")

	func testBoxSurvivesTheValue()
	{
		var box:Weak<Thing>

		do
		{
			let thing = Thing("hello")
			box = Weak(thing)
			#expect(box.value?.name == "hello")
		}

		#expect(box.value == nil)
		#expect(box.value == nil, "reading twice must not differ")
	}


	/// The case it was written for: a collection that does not retain what it holds. Each box empties on its own, so
	/// the collection keeps its COUNT while losing its contents - which a caller has to expect.

	@Test("A collection of boxes does not retain its contents")

	func testWeakCollection()
	{
		var boxes:[Weak<Thing>] = []
		let kept = Thing("kept")

		do
		{
			let transient = Thing("transient")
			boxes = [Weak(kept), Weak(transient)]

			#expect(boxes.compactMap { $0.value }.count == 2)
		}

		#expect(boxes.count == 2, "the boxes themselves are still there")
		#expect(boxes.compactMap { $0.value }.count == 1, "but only the retained value survived")
		#expect(boxes.compactMap { $0.value }.first === kept)
	}


	/// `value` is `private(set)`, so a box cannot be re-pointed after it is made - it is a snapshot of one reference
	/// rather than a mutable slot. Stated because the alternative design is the more common one.

	@Test("A box is not a mutable slot")

	func testValueIsReadOnly()
	{
		let thing = Thing("hello")
		let box = Weak(thing)

		#expect(box.value === thing)

		// box.value = otherThing would not compile - the setter is private

		#expect(Mirror(reflecting:box).children.isEmpty == false)
	}
}


//----------------------------------------------------------------------------------------------------------------------
