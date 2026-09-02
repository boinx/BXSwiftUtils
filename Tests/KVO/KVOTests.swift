//
//  KVOTests.swift
//  BXSwiftUtils
//
//  Copyright © 2026 Boinx Software Ltd. & Imagine GbR. All rights reserved.
//

import Testing
import Foundation
@testable import BXSwiftUtils


//----------------------------------------------------------------------------------------------------------------------


/// KVO is the string based layer that TypedKVO is built on, and the difference between them is the whole point: here
/// the key path is an unchecked String, so a typo is not a compile error and not necessarily a runtime one either.
///
/// The general observation behavior is covered in TypedKVOTests. What this suite is for is the surface that only
/// exists down here - the raw key path, the Objective-C entry points, and what is left of the old teardown machinery.

@Suite("KVO")

struct KVOTests
{
	final class Node : NSObject
	{
		@objc dynamic var number:Int = 42
	}


	final class Root : NSObject
	{
		@objc dynamic var node:Node? = Node()
	}


//----------------------------------------------------------------------------------------------------------------------


	// MARK: - Observing through a string


	@Test("A string key path reports the initial value and each change")

	func testBasicObservation()
	{
		let root = Root()
		var seen:[Int?] = []

		let token = KVO(object:root, keyPath:"node.number", options:[.initial, .new])
		{
			_, newValue in
			seen.append(newValue as? Int)
		}

		root.node?.number = 100

		#expect(seen == [42, 100])
		#expect(token.keyPath == "node.number")

		withExtendedLifetime(token) { }
	}


	/// The old value arrives only when asked for, exactly as in the typed layer - and the base class hands both
	/// values through untyped, so a caller casts them itself.

	@Test("Old and new values are reported when requested")

	func testOldAndNewValues()
	{
		let root = Root()
		var pairs:[(Int?, Int?)] = []

		let token = KVO(object:root, keyPath:"node.number", options:[.old, .new])
		{
			oldValue, newValue in
			pairs.append((oldValue as? Int, newValue as? Int))
		}

		root.node?.number = 100

		#expect(pairs.count == 1)
		#expect(pairs.first?.0 == 42)
		#expect(pairs.first?.1 == 100)

		withExtendedLifetime(token) { }
	}


	/// The observed object is exposed and held WEAKLY, so a token cannot keep alive the thing it watches.

	@Test("The observed object is exposed and not retained")

	func testObservedObjectIsWeak()
	{
		var token:KVO?
		weak var weakRoot:Root?

		do
		{
			let root = Root()
			weakRoot = root
			token = KVO(object:root, keyPath:"node.number", options:[.new]) { _, _ in }

			#expect(token?.observedObject === root)
		}

		#expect(weakRoot == nil, "the token retained the object it observes")
		#expect(token?.observedObject == nil, "observedObject should have gone nil with the object")

		token = nil
	}


	@Test("Releasing the token stops the observation")

	func testTokenControlsTheObservation()
	{
		let root = Root()
		var count = 0

		weak var weakToken:KVO?

		do
		{
			let token = KVO(object:root, keyPath:"node.number", options:[.new]) { _, _ in count += 1 }
			weakToken = token

			root.node?.number = 100

			#expect(count == 1)

			withExtendedLifetime(token) { }
		}

		#expect(weakToken == nil, "the token outlived its scope, so the rest proves nothing")

		root.node?.number = 200

		#expect(count == 1, "the observation outlived its token")
	}


//----------------------------------------------------------------------------------------------------------------------


	// MARK: - Key paths that are only strings


	/// PINS A TRAP, and it is the reason TypedKVO exists. A key path that names nothing behaves in TWO different ways
	/// depending on the options, and neither of them is a Swift error.
	///
	/// With `.initial`, KVO reads the value at registration and raises NSUnknownKeyException - loud, immediate, and
	/// at least findable. Without it, registration SUCCEEDS and the observation simply never fires: a typo becomes a
	/// feature that silently does not work, with nothing anywhere to say so.

	@Test("A misspelled key path raises only when .initial forces a read")

	func testMisspelledKeyPathWithInitial() throws
	{
		let root = Root()

		#expect(throws:(any Error).self)
		{
			try NSException.catch
			{
				let token = KVO(object:root, keyPath:"nosuchproperty", options:[.initial, .new]) { _, _ in }
				withExtendedLifetime(token) { }
			}
		}
	}


	@Test("A misspelled key path without .initial registers and never fires")

	func testMisspelledKeyPathWithoutInitial() throws
	{
		let root = Root()
		var count = 0

		try NSException.catch
		{
			let token = KVO(object:root, keyPath:"nosuchproperty", options:[.new]) { _, _ in count += 1 }

			// Changing a REAL property proves the object is being observed at all, just not usefully

			root.node?.number = 100

			#expect(count == 0, "a key path that names nothing must not report anything")

			withExtendedLifetime(token) { }
		}
	}


//----------------------------------------------------------------------------------------------------------------------


	// MARK: - The Objective-C entry points


	/// The block form takes no values at all, because it registers with an empty option set - so it answers "something
	/// changed" and nothing more, and there is no initial call.

	@Test("The Objective-C block API reports changes without values")

	func testObjectiveCBlockAPI()
	{
		let root = Root()
		var count = 0

		let token = KVO.observe(root, onKeyPath:"node.number") { count += 1 }

		#expect(count == 0, "the block form must not fire initially")

		root.node?.number = 100

		#expect(count == 1)

		withExtendedLifetime(token) { }
	}


	@Test("The Objective-C options API reports old and new values")

	func testObjectiveCOptionsAPI()
	{
		let root = Root()
		var seen:[Int?] = []

		let token = KVO.observe(root, onKeyPath:"node.number", options:[.old, .new])
		{
			oldValue, newValue in
			seen.append(oldValue as? Int)
			seen.append(newValue as? Int)
		}

		root.node?.number = 100

		#expect(seen == [42, 100])

		withExtendedLifetime(token) { }
	}


//----------------------------------------------------------------------------------------------------------------------


	// MARK: - What is left of the old teardown machinery


	/// `KVO.invalidate(for:)` DOES NOTHING. Its body was commented out in 2022 along with the rest of the
	/// just-in-time teardown, because Apple stopped raising an exception for an observed object dying with observers
	/// attached back in macOS 10.13 - the reasoning is written out at length at the top of KVO.swift.
	///
	/// The method itself was left in place, and roughly seven production call sites still call it from deinit. They
	/// are harmless, but they read as protection that is no longer there, and anyone maintaining one of those classes
	/// has to go and find that out.
	///
	/// What this pins is the CONTRACT - that invalidating does not stop an observation - rather than the empty
	/// body. A mutation that puts a harmless side effect in the method survives, and should: the point is what a
	/// caller can rely on, and no caller can rely on an empty body staying empty.

	#warning("PINNED BEHAVIOR: KVO.invalidate(for:) is a no-op, yet production code still calls it from deinit")

	@Test("Invalidating an object does not stop its observations")

	func testInvalidateIsANoOp()
	{
		let root = Root()
		var count = 0

		let token = KVO(object:root, keyPath:"node.number", options:[.new]) { _, _ in count += 1 }

		KVO.invalidate(for:root)

		root.node?.number = 100

		#expect(count == 1, "invalidate(for:) has started doing something - the call sites need revisiting")

		withExtendedLifetime(token) { }
	}
}


//----------------------------------------------------------------------------------------------------------------------
