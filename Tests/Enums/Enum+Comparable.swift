//
//  Enum+Comparable.swift
//  BXSwiftUtils
//
//  Copyright © 2026 Boinx Software Ltd. & Imagine GbR. All rights reserved.
//

import Testing
import Foundation
@testable import BXSwiftUtils


//----------------------------------------------------------------------------------------------------------------------


/// `ComparableEnum` gives an enum an ordering, and it has TWO implementations that order by different things - integer
/// enums by their raw value, string enums by the order their cases are DECLARED. Getting those two confused is the
/// mistake the protocol exists to prevent, and only one assertion in the original suite could tell them apart.

@Suite("Enum+Comparable")

struct Enum_ComparableTests
{
	/// Raw values deliberately out of declaration order, so that "ordered by rawValue" and "ordered by case position"
	/// give different answers and the test can say which one happens.

	enum Priority : Int, ComparableEnum
	{
		case high = 30
		case low = 10
		case medium = 20
	}


	/// Declared in an order that is NOT alphabetical, for the same reason.

	enum State : String, CaseIterable, ComparableEnum
	{
		case waiting
		case running
		case finished
	}


	@Test("An integer enum is ordered by its raw value, not its declaration order")

	func testIntegerOrdering()
	{
		#expect(Priority.low < Priority.medium)
		#expect(Priority.medium < Priority.high)
		#expect(Priority.low < Priority.high)

		// `high` is declared FIRST and is still the greatest, which is what makes this a raw value ordering

		#expect([Priority.high, Priority.low, Priority.medium].max() == .high)
		#expect([Priority.high, Priority.low, Priority.medium].min() == .low)
		#expect([Priority.high, Priority.low, Priority.medium].sorted() == [.low, .medium, .high])
	}


	/// A STRING enum is ordered by where its cases are declared, not by comparing the strings - which is the whole
	/// point of the second implementation and the reason it demands CaseIterable.
	///
	/// Alphabetically these would be finished, running, waiting. By declaration they are the reverse.

	@Test("A string enum is ordered by declaration, not alphabetically")

	func testStringOrdering()
	{
		#expect(State.waiting < State.running)
		#expect(State.running < State.finished)

		#expect([State.running, State.finished, State.waiting].max() == .finished)
		#expect([State.running, State.finished, State.waiting].sorted() == [.waiting, .running, .finished])

		// The alphabetical answer would be the exact opposite, which is what this rules out

		#expect(!(State.finished < State.waiting))
		#expect(State.waiting.rawValue > State.finished.rawValue, "the raw strings really do sort the other way")
	}


	/// Comparable derives the rest of the operators from `<`, so a type only has to supply one - worth confirming,
	/// since both implementations define exactly that one and nothing else.

	@Test("The remaining comparisons come for free")

	func testDerivedOperators()
	{
		#expect(Priority.high > Priority.low)
		#expect(Priority.low <= Priority.low)
		#expect(Priority.high >= Priority.medium)
		#expect(State.finished > State.waiting)
		#expect(State.running >= State.running)
	}


	/// Equality is the enum's own, and is unaffected by the ordering - a case equals itself and nothing else, however
	/// the raw values happen to compare.

	@Test("Equality is unaffected by the ordering")

	func testEquality()
	{
		#expect(Priority.medium == Priority.medium)
		#expect(Priority.medium != Priority.high)
		#expect(!(Priority.medium < Priority.medium))
		#expect(!(State.running < State.running))
	}
}


//----------------------------------------------------------------------------------------------------------------------
