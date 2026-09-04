//
//  Bool+OperatorsTests.swift
//  BXSwiftUtils
//
//  Copyright © 2026 Boinx Software Ltd. & Imagine GbR. All rights reserved.
//

import Testing
import Foundation
@testable import BXSwiftUtils


//----------------------------------------------------------------------------------------------------------------------


/// Three operators over Bool. Two of them take their right side as an `@autoclosure`, and that is the whole reason
/// they exist rather than being written out - so whether the right side is EVALUATED is the behavior worth testing,
/// and it was the one thing the original suite could not see.

@Suite("Bool+Operators")

struct Bool_OperatorsTests
{
	@Test("OR-assign follows the truth table", arguments:
	[
		(false, false, false),
		(false, true, true),
		(true, true, true),
		(true, false, true),
	])

	func testOrAssign(_ initial:Bool, _ operand:Bool, _ expected:Bool)
	{
		var value = initial
		value ||= operand

		#expect(value == expected)
	}


	@Test("AND-assign follows the truth table", arguments:
	[
		(false, false, false),
		(false, true, false),
		(true, true, true),
		(true, false, false),
	])

	func testAndAssign(_ initial:Bool, _ operand:Bool, _ expected:Bool)
	{
		var value = initial
		value &&= operand

		#expect(value == expected)
	}


	@Test("XOR follows the truth table", arguments:
	[
		(false, false, false),
		(false, true, true),
		(true, false, true),
		(true, true, false),
	])

	func testXor(_ lhs:Bool, _ rhs:Bool, _ expected:Bool)
	{
		#expect((lhs ^^ rhs) == expected)
	}


	/// THE REASON FOR THE AUTOCLOSURE. `||=` must not evaluate its right side once the value is already true, and
	/// `&&=` must not once it is already false - the same short-circuiting `||` and `&&` give, which is lost the
	/// moment someone writes `x = x || expensive()`.
	///
	/// Invisible in every result: the value ends up the same either way, so the original suite's truth tables would
	/// have passed just as well with the autoclosures evaluated eagerly.

	@Test("The right side is only evaluated when it can change the answer")

	func testShortCircuiting()
	{
		var evaluations = 0

		func operand(_ value:Bool) -> Bool { evaluations += 1 ; return value }

		var alreadyTrue = true
		alreadyTrue ||= operand(false)

		#expect(evaluations == 0, "||= evaluated its right side although the value was already true")

		var alreadyFalse = false
		alreadyFalse &&= operand(true)

		#expect(evaluations == 0, "&&= evaluated its right side although the value was already false")

		// ...and it IS evaluated when it decides the outcome

		var undecidedOr = false
		undecidedOr ||= operand(true)

		#expect(evaluations == 1)

		var undecidedAnd = true
		undecidedAnd &&= operand(false)

		#expect(evaluations == 2)
	}


	/// Both are `rethrows`, so an error from the right side reaches the caller - and only when the right side is
	/// reached at all, which is the short-circuiting rule again, seen from the other side.

	@Test("An error from the right side is rethrown, and only when it is evaluated")

	func testRethrows() throws
	{
		struct Failure : Error {}

		func failing() throws -> Bool { throw Failure() }

		var short = true

		#expect(throws:Never.self) { try short ||= failing() }
		#expect(short)

		var reached = false

		#expect(throws:Failure.self) { try reached ||= failing() }
		#expect(!reached, "the value must be left alone when the right side throws")
	}


	/// `^^` is declared with LogicalDisjunctionPrecedence, so it associates left to right and sits at the same level
	/// as `||`. Chaining is therefore parity - an odd number of trues.

	@Test("Chained XOR is a parity check", arguments:
	[
		(false, false, true, true),
		(false, false, false, false),
		(false, true, true, false),
		(true, false, false, true),
		(true, true, true, true),
	])

	func testChainedXor(_ a:Bool, _ b:Bool, _ c:Bool, _ expected:Bool)
	{
		let chained = a ^^ b ^^ c

		#expect(chained == expected)
		#expect(chained == ([a, b, c].filter { $0 }.count % 2 == 1), "chained XOR is not parity")
	}
}


//----------------------------------------------------------------------------------------------------------------------
