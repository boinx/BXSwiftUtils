//
//  Array+ConcatenationTests.swift
//  BXSwiftUtils
//
//  Copyright © 2026 Boinx Software Ltd. & Imagine GbR. All rights reserved.
//

import Testing
import Foundation
@testable import BXSwiftUtils


//----------------------------------------------------------------------------------------------------------------------


/// Three operators that let a single element be appended or prepended to an array, and skip the work when that element
/// is nil. Simple enough on `[Int]`, which is all the original suite ever used.
///
/// The interesting part is that both operators take `Element?`, so the compiler has to decide what `Element` is before
/// it can decide what the expression means. On an array whose Element is ITSELF optional, or an array of arrays, that
/// decision does not go the way the call site reads.

@Suite("Array+Concatenation")

struct Array_ConcatenationTests
{
	// MARK: - Appending and prepending


	@Test("An element is appended in place")

	func testAppendInPlace()
	{
		var values = [1, 2, 3]
		values += 4

		#expect(values == [1, 2, 3, 4])
	}


	@Test("Appending nil has no effect")

	func testAppendNilInPlace()
	{
		var values = [1, 2, 3]
		values += nil

		#expect(values == [1, 2, 3])
	}


	/// The non-mutating forms must leave the original alone - that is the only thing distinguishing them from the
	/// `+=` versions, and the reason both exist.

	@Test("The non-mutating forms copy rather than modify")

	func testNonMutatingFormsCopy()
	{
		let original = [1, 2, 3]

		#expect(original + 4 == [1, 2, 3, 4])
		#expect(0 + original == [0, 1, 2, 3])
		#expect(original + nil == [1, 2, 3])
		#expect(nil + original == [1, 2, 3])

		#expect(original == [1, 2, 3], "the original array was modified")
	}


	@Test("Empty arrays concatenate in both directions")

	func testEmptyArrays()
	{
		#expect([Int]() + 1 == [1])
		#expect(1 + [Int]() == [1])
		#expect([Int]() + nil == [])
		#expect(nil + [Int]() == [])
	}


	/// Both operators are left associative and return an array, so they chain - which is how they read at a call site
	/// and worth confirming rather than assuming.

	@Test("The operators chain")

	func testChaining()
	{
		#expect(0 + [1, 2] + 3 == [0, 1, 2, 3])
		#expect([1] + 2 + 3 == [1, 2, 3])
	}


	/// Elements are appended by identity, not by copy, which matters because most FotoMagico arrays hold objects.

	@Test("Reference types keep their identity")

	func testReferenceTypes()
	{
		let first = NSObject()
		let second = NSObject()

		let combined = [first] + second

		#expect(combined.count == 2)
		#expect(combined[0] === first)
		#expect(combined[1] === second)
	}


//----------------------------------------------------------------------------------------------------------------------


	// MARK: - When Element is itself optional


	/// THE CONTRACT IS BACKWARDS HERE. The doc comment promises that "if the added element is an optional that happens
	/// to be nil, then this operator has no effect" - and on an array of optionals, which is the only place that
	/// sentence could possibly apply, whether it holds depends on HOW THE NIL IS SPELLED.
	///
	/// The parameter is `Element?`, so for `[Int?]` it is `Int??`. A literal `nil` becomes the OUTER none and is
	/// skipped; a variable of type `Int?` is promoted to `.some(.none)` and is APPENDED. Same value, opposite result,
	/// and the variable form is the one real code writes.
	///
	/// So an array of optionals cannot have a nil appended by literal, and cannot avoid having one appended by
	/// variable - the operator offers no way to say either thing.

	#warning("PINNED BEHAVIOR: on an array of optionals, `array += nil` skips but `array += someNilOptional` appends")

	@Test("A nil literal and a nil variable behave differently on an array of optionals")

	func testNilLiteralVersusNilVariable()
	{
		var byLiteral:[Int?] = [1, 2]
		byLiteral += nil

		#expect(byLiteral.count == 2, "the literal was read as the outer nil and skipped")

		var byVariable:[Int?] = [1, 2]
		let absent:Int? = nil
		byVariable += absent

		#expect(byVariable.count == 3, "the variable was promoted and appended")
		#expect(byVariable.last == .some(.none), "and what it appended is a nil element")
	}


	/// A present optional appends the same way whichever form is used, so the divergence above is entirely about nil.

	@Test("A present optional appends either way")

	func testPresentOptionalAppends()
	{
		var byLiteral:[Int?] = [1]
		byLiteral += 2

		let present:Int? = 3
		byLiteral += present

		#expect(byLiteral.count == 3)
		#expect(byLiteral[1] == 2)
		#expect(byLiteral[2] == 3)
	}


//----------------------------------------------------------------------------------------------------------------------


	// MARK: - When Element is itself an array


	/// PINS A TYPE INFERENCE TRAP. On an array of arrays, `+` without a type annotation does not append the right hand
	/// side as ONE element, and does not concatenate the two as arrays either - it silently widens BOTH to `[Any]`
	/// and concatenates that, so `[[1,2]] + [3,4]` has THREE elements of type Any.
	///
	/// Without these operators the expression would not compile at all, which would be the better outcome. With them,
	/// `Element` can be inferred as `Any`, and that candidate wins.
	///
	/// Annotating the result, or using `+=`, gives the appending behavior the call site looks like it wants. Nothing
	/// warns about the difference, so the only defense is knowing it is there.

	@Test("An array of arrays widens to Any unless the result is annotated")

	func testNestedArrayWidensToAny()
	{
		let nested:[[Int]] = [[1, 2]]

		// No annotation: Element is inferred as Any and both sides are concatenated

		let inferred = nested + [3, 4]

		#expect(inferred.count == 3, "the element was appended rather than the arrays being merged")
		#expect(type(of:inferred) == [Any].self)

		// Annotated: the right hand side is one element of the outer array, which is what the call site reads like

		let annotated:[[Int]] = nested + [3, 4]

		#expect(annotated.count == 2)
		#expect(annotated[1] == [3, 4])

		// ...and the mutating form cannot widen, because the destination fixes the type

		var mutable:[[Int]] = [[1, 2]]
		mutable += [3, 4]

		#expect(mutable.count == 2)
		#expect(mutable[1] == [3, 4])
	}
}


//----------------------------------------------------------------------------------------------------------------------
