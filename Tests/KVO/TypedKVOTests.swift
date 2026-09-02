//
//  TypedKVOTests.swift
//  BXSwiftUtils
//
//  Copyright © 2026 Boinx Software Ltd. & Imagine GbR. All rights reserved.
//

import Testing
import Foundation
@testable import BXSwiftUtils


//----------------------------------------------------------------------------------------------------------------------


/// TypedKVO turns a Swift KeyPath into a string based KVO registration, so almost everything that can go wrong is a
/// question of LIFETIME: the token decides how long the observation lives, and every object along the key path can
/// disappear underneath it.
///
/// Note the observed classes below do NOT call `KVO.invalidate(for:)` from deinit, the way the original suite's did.
/// That call has been a no-op since the just-in-time teardown was removed in 2022 - Apple stopped raising an exception
/// for an observed object dying with observers attached in macOS 10.13 - so writing it here would suggest the tests
/// depend on something that no longer exists.

@Suite("TypedKVO")

struct TypedKVOTests
{
	final class Leaf : NSObject
	{
		@objc dynamic var text:String = "hello"
	}


	final class Node : NSObject
	{
		@objc dynamic var number:Int = 42
		@objc dynamic var leaf:Leaf? = Leaf()
	}


	final class Root : NSObject
	{
		@objc dynamic var node:Node? = Node()

		/// Deliberately NOT exposed to the Objective-C runtime, which is what makes a key path through it unusable
		/// for KVO - and the reason TypedKVO checks rather than letting KVO fail obscurely later.

		var hidden:Node? = Node()
	}


//----------------------------------------------------------------------------------------------------------------------


	// MARK: - Observing


	/// `.initial` reports the value at registration time, before anything has changed - which is what lets a caller
	/// use one closure for "set up" and "keep up to date" rather than writing the first assignment twice.

	@Test("An observation reports the initial value and then each change")

	func testInitialAndChanges()
	{
		let root = Root()
		var seen:[Int?] = []

		let token = TypedKVO(root, \.node?.number)
		{
			_, change in
			seen.append(change.newValue ?? nil)
		}

		root.node?.number = 100
		root.node?.number = 7

		#expect(seen == [42, 100, 7])

		withExtendedLifetime(token) { }
	}


	/// An empty option set means no initial callback - and, less obviously, no VALUES either. The change is still
	/// reported, because the options only say what to put in the change dictionary, not whether to notify.
	///
	/// Worth stating because `options:[]` reads like "observe with defaults" rather than "tell me that something
	/// happened but not what", and a caller who reaches for it to suppress the initial call loses the new value too.

	@Test("An empty option set skips the initial callback but still reports changes")

	func testNoInitialCallback()
	{
		let root = Root()
		var seen:[Int?] = []

		let token = TypedKVO(root, \.node?.number, options:[])
		{
			_, change in
			seen.append(change.newValue ?? nil)
		}

		#expect(seen.isEmpty, "the initial value was reported without .initial")

		root.node?.number = 100

		#expect(seen.count == 1, "the change itself was not reported")
		#expect(seen == [nil], "a new value arrived although .new was not requested")

		withExtendedLifetime(token) { }
	}


	/// The OLD value only arrives when it was asked for. Nothing in the original suite ever passed `.old`, so the
	/// half of `Change` that carries it was never once populated in a test.

	@Test("The old value is reported only with the .old option")

	func testOldValue()
	{
		let root = Root()
		var oldValues:[Int?] = []

		do
		{
			let token = TypedKVO(root, \.node?.number, options:[.old, .new])
			{
				_, change in
				oldValues.append(change.oldValue ?? nil)
			}

			root.node?.number = 100
			withExtendedLifetime(token) { }
		}

		#expect(oldValues == [42])

		// ...and without .old there is no old value to report

		var withoutOld:[Int?] = []

		do
		{
			let token = TypedKVO(root, \.node?.number, options:[.new])
			{
				_, change in
				withoutOld.append(change.oldValue ?? nil)
			}

			root.node?.number = 200
			withExtendedLifetime(token) { }
		}

		#expect(withoutOld == [nil])
	}


	/// The closure is handed the observed object, so a caller does not have to capture it - which is the whole reason
	/// TypedKVO takes a target rather than letting the caller close over one and create a cycle.

	@Test("The closure is handed the observed object")

	func testClosureReceivesTheTarget()
	{
		let root = Root()
		var identities:[ObjectIdentifier] = []

		let token = TypedKVO(root, \.node?.number, options:[.new])
		{
			target, _ in
			identities.append(ObjectIdentifier(target))
		}

		root.node?.number = 100

		#expect(identities == [ObjectIdentifier(root)])

		withExtendedLifetime(token) { }
	}


	/// Two observations of the same property are independent - registering one must not disturb the other.

	@Test("Several observations of one property all fire")

	func testMultipleObservers()
	{
		let root = Root()
		var first = 0
		var second = 0

		let tokens =
		[
			TypedKVO(root, \.node?.number, options:[.new]) { _, _ in first += 1 },
			TypedKVO(root, \.node?.number, options:[.new]) { _, _ in second += 1 },
		]

		root.node?.number = 100

		#expect(first == 1)
		#expect(second == 1)

		withExtendedLifetime(tokens) { }
	}


//----------------------------------------------------------------------------------------------------------------------


	// MARK: - Lifetime


	/// The token IS the observation. Releasing it unregisters, which is what makes `observers = []` a complete
	/// teardown rather than a leak.
	///
	/// EQUIVALENT MUTANT, confirmed: removing the `removeObserver` call from KVO.deinit entirely survives this suite.
	/// Nothing here can tell the difference, and that is consistent with the note at the top of KVO.swift - since
	/// macOS 10.13 the runtime no longer punishes an observation that outlives its observer, which is exactly why the
	/// old just-in-time teardown machinery could be deleted in 2022. The call stays: it is the correct thing to do,
	/// and being unobservable is a property of this OS rather than of the code.

	@Test("Releasing the token stops the observation")

	func testTokenControlsTheObservation()
	{
		let root = Root()
		var count = 0

		weak var weakToken:TypedKVO<Root,Int?>?

		do
		{
			let token = TypedKVO(root, \.node?.number, options:[.new]) { _, _ in count += 1 }
			weakToken = token

			root.node?.number = 100

			#expect(count == 1)

			withExtendedLifetime(token) { }
		}

		// Assert the token really is gone before concluding anything from the silence that follows - otherwise a
		// lifetime this test did not intend would make it pass without observing anything.

		#expect(weakToken == nil, "the token outlived its scope, so the rest proves nothing")

		root.node?.number = 200

		#expect(count == 1, "the observation outlived its token")
	}


	/// An object in the MIDDLE of the key path going away must neither crash nor go unreported - KVO delivers a
	/// change for the whole tail of the path when an intermediate link is replaced.

	@Test("An intermediate object can be deallocated")

	func testIntermediateObjectDeallocated()
	{
		let root = Root()
		var seen:[String?] = []

		let token = TypedKVO(root, \.node?.leaf?.text)
		{
			_, change in
			seen.append(change.newValue ?? nil)
		}

		#expect(seen == ["hello"])

		// Would have crashed under the pre-10.13 runtime if the observer were not torn down in time

		root.node?.leaf = nil

		#expect(seen == ["hello", nil])

		root.node = nil

		#expect(seen == ["hello", nil, nil])

		withExtendedLifetime(token) { }
	}


	/// The ROOT going away is the case the token cannot control, since TypedKVO holds it weakly on purpose. The
	/// observation simply stops, and nothing is delivered afterwards.

	@Test("The observed root can be deallocated before the token")

	func testRootDeallocated()
	{
		var seen:[String?] = []
		var token:TypedKVO<Root,String?>?

		weak var weakRoot:Root?

		do
		{
			let root = Root()
			weakRoot = root

			token = TypedKVO(root, \.node?.leaf?.text)
			{
				_, change in
				seen.append(change.newValue ?? nil)
			}

			#expect(seen == ["hello"])
		}

		// THE LOAD BEARING ASSERTION. TypedKVO holds the observed object weakly, both as KVO.observedObject and in
		// the closure it wraps around the caller's - so a live token must not be enough to keep the root alive.
		// Without this, a strong capture would be invisible here: nothing changes the root afterwards either way,
		// so the silence below would look the same.

		#expect(weakRoot == nil, "the token retained the object it observes")

		#expect(seen == ["hello"])

		// ...and releasing the token afterwards must not touch the object that is already gone

		token = nil

		#expect(token == nil)
	}


//----------------------------------------------------------------------------------------------------------------------


	// MARK: - Key paths KVO cannot use


	/// A key path through a property that is not `@objc dynamic` has no KVC string, and TypedKVO raises rather than
	/// registering something that could never fire.
	///
	/// An NSException rather than a Swift error, deliberately: it needs no `try` at the hundreds of call sites, and a
	/// key path that is not KVO compatible is a programming error rather than a runtime condition.

	@Test("A key path that is not KVO compatible raises")

	func testNonExposedKeyPathRaises() throws
	{
		let root = Root()

		#expect(throws:(any Error).self)
		{
			try NSException.catch
			{
				_ = TypedKVO(root, \.hidden?.number) { _, _ in }
			}
		}
	}


	/// ...while the exposed equivalent of the very same property registers without complaint, so the test above is
	/// failing for the reason it claims rather than because of anything else about the key path.

	@Test("The exposed equivalent registers normally")

	func testExposedKeyPathDoesNotRaise() throws
	{
		let root = Root()

		try NSException.catch
		{
			let token = TypedKVO(root, \.node?.number) { _, _ in }
			withExtendedLifetime(token) { }
		}
	}


//----------------------------------------------------------------------------------------------------------------------


	// MARK: - The shape of Change


	/// PINS AN API WART, though a milder one than it looks. `Change.newValue` is `Value?`, and for a key path through
	/// an optional the `Value` is itself optional - so the caller receives `String??` and writes `?? nil` to flatten
	/// it, as every call site in the original suite did.
	///
	/// The two levels do carry different meanings and are distinguishable: the OUTER nil means KVO reported something
	/// this observation could not turn into a `Value`, while `.some(nil)` means the property really is nil. A removed
	/// property arrives as NSNull, which casts to `String?` successfully as nil - so it is the inner level that goes
	/// nil, and a caller who checks the outer one is asking a different question than they probably think.

	@Test("A nil property is reported at the inner level of the change")

	func testChangeIsDoublyOptional()
	{
		let root = Root()
		var raw:[String??] = []

		let token = TypedKVO(root, \.node?.leaf?.text)
		{
			_, change in
			raw.append(change.newValue)
		}

		root.node?.leaf = nil

		#expect(raw.count == 2)
		#expect((raw.first ?? nil) == "hello")

		let last = raw.last ?? nil

		#expect(last != nil, "the OUTER optional went nil, so the value could not be converted at all")
		#expect((last ?? nil) == nil, "the INNER optional should be nil for a property that went away")

		withExtendedLifetime(token) { }
	}
}


//----------------------------------------------------------------------------------------------------------------------
