//
//  Equatable+IsContainedInTests.swift
//  BXSwiftUtils
//
//  Copyright © 2026 Boinx Software Ltd. & Imagine GbR. All rights reserved.
//

import Testing
import Foundation
@testable import BXSwiftUtils


//----------------------------------------------------------------------------------------------------------------------


/// Syntactic sugar around `collection.contains(self)`, plus a `~==` operator for it. The interesting part is the
/// operator's PRECEDENCE, since that is what decides whether an expression means what it looks like.

@Suite("Equatable+IsContainedIn")

struct Equatable_IsContainedInTests
{
	enum State { case waiting, running, finished }


	@Test("Membership is reported both ways round")

	func testIsContained()
	{
		#expect(State.waiting.isContained(in:[.waiting, .running]))
		#expect(!State.waiting.isContained(in:[.running]))
		#expect(!State.waiting.isContained(in:[]))

		#expect(State.waiting ~== [.waiting, .running])
		#expect(!(State.waiting ~== [.running]))
		#expect(!(State.waiting ~== []))
	}


	/// The extension is on Equatable and the parameter is any Collection of the same element, so neither side is tied
	/// to Array. Only array literals had been used.

	@Test("Any Collection can be searched")

	func testOtherCollections()
	{
		// Bound to locals rather than written inline: the #expect macro re-parses the expression it is given, and an
		// operator of this precedence next to a range or a logical operator confuses it into a different parse than
		// the compiler makes of the same text. The parsing under test still happens - in the initializers below.

		let inSet = 3 ~== Set([1, 2, 3])
		let notInSet = 9 ~== Set([1, 2, 3])
		let inRange = 3 ~== (1...5)
		let notInRange = 9 ~== (1...5)
		let inStrings = "b" ~== ["a", "b"]
		let inSlice = 2 ~== [1, 2, 3].dropFirst()

		#expect(inSet)
		#expect(!notInSet)
		#expect(inRange)
		#expect(!notInRange)
		#expect(inStrings)
		#expect(inSlice)
	}


	/// `~==` is declared with ComparisonPrecedence, which is what lets it be written next to `&&` and `||` without
	/// parentheses - the reason the operator exists rather than just the function.
	///
	/// Asserted with a case that would give the WRONG answer under a different precedence: with logical operators
	/// binding tighter, `a ~== [x] && b ~== [y]` would try to compare an array against a Bool and not compile at all.

	@Test("The operator binds tighter than the logical operators")

	func testPrecedence()
	{
		let both = State.waiting ~== [.waiting] && State.running ~== [.running, .finished]
		let either = State.waiting ~== [.finished] || State.running ~== [.running]
		let neither = State.waiting ~== [.finished] || State.running ~== [.finished]

		#expect(both)
		#expect(either)
		#expect(!neither)
	}
}


//----------------------------------------------------------------------------------------------------------------------
