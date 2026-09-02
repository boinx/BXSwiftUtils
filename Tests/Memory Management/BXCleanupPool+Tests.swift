//
//  BXCleanupPool+Tests.swift
//  BXSwiftUtils
//
//  Copyright © 2026 Boinx Software Ltd. & Imagine GbR. All rights reserved.
//

import Testing
import Foundation
@testable import BXSwiftUtils


//----------------------------------------------------------------------------------------------------------------------


/// A pool exists so that an object can break its own reference cycles at a moment it chooses, which makes its
/// behavior almost entirely a question of WHO HOLDS WHAT. The target must be held weakly or the pool defeats its own
/// purpose; the cleanup value must be held strongly or it may be gone by the time it is needed; and both have to be
/// let go afterwards.
///
/// The other half is re-entrancy. Cleanup runs arbitrary closures belonging to an object that is being torn down, so
/// those closures can perfectly well touch the pool again - and what happens then is not something a caller can see
/// from the outside.

@Suite("BXCleanupPool")

struct BXCleanupPool_Tests
{
	/// The object cleanups are registered against. A class, because a cleanup keyPath must be a
	/// ReferenceWritableKeyPath - the pool works on reference semantics by definition.

	final class Target
	{
		var optional:NSObject? = NSObject()
		var nonOptional:NSObject = NSObject()
		var log:[String] = []

		/// Registers its own cleanup on assignment, which is the pattern the pool was written for.

		var automatic:NSObject?
		{
			willSet { self.pool?.registerCleanup(self, \.automatic, nil) }
		}

		weak var pool:BXCleanupPool?
	}


	/// Reports the ORDER in which its properties are written, which is the only way to observe how the pool sequences
	/// property cleanups - setting a property is otherwise silent.

	final class Ordered
	{
		var log:[String] = []

		var a:Int = 0 { didSet { self.log.append("a") } }
		var b:Int = 0 { didSet { self.log.append("b") } }
	}


//----------------------------------------------------------------------------------------------------------------------


	// MARK: - Cleaning up


	@Test("A registered property is set on cleanup")

	func testManualCleanup()
	{
		let pool = BXCleanupPool()
		let target = Target()

		pool.registerCleanup(target, \.optional, nil)

		#expect(target.optional != nil)

		pool.cleanup()

		#expect(target.optional == nil)
	}


	/// The pool cleans up when it is deallocated, which is what lets an owner simply drop it rather than remember to
	/// call cleanup() on every path out.

	@Test("Deallocating the pool cleans up")

	func testCleanupOnDeinit()
	{
		let target = Target()

		do
		{
			let pool = BXCleanupPool()
			pool.registerCleanup(target, \.optional, nil)

			#expect(target.optional != nil)
		}

		#expect(target.optional == nil)
	}


	/// The value written on cleanup does not have to be nil, and the optional and non-optional overloads must agree -
	/// the second exists only so a caller need not wrap the value in Optional() by hand.

	@Test("The cleanup value can be any value")

	func testCustomCleanupValue()
	{
		let pool = BXCleanupPool()
		let target = Target()
		let replacement = NSObject()

		pool.registerCleanup(target, \.optional, replacement)
		pool.registerCleanup(target, \.nonOptional, replacement)
		pool.cleanup()

		#expect(target.optional === replacement)
		#expect(target.nonOptional === replacement)
	}


	@Test("A property that registers itself on assignment is cleaned up")

	func testAutomaticRegistration()
	{
		let pool = BXCleanupPool()
		let target = Target()
		target.pool = pool

		target.automatic = NSObject()

		#expect(target.automatic != nil)

		pool.cleanup()

		#expect(target.automatic == nil)
	}


//----------------------------------------------------------------------------------------------------------------------


	// MARK: - What replaces what


	/// Registering the same target and keyPath twice keeps only the LAST registration, so a property that registers
	/// itself on every assignment does not accumulate one entry per write.

	@Test("Re-registering the same property replaces the previous entry")

	func testReRegistrationReplaces()
	{
		let pool = BXCleanupPool()
		let target = Target()

		weak var firstValue:NSObject?

		do
		{
			let value = NSObject()
			firstValue = value
			pool.registerCleanup(target, \.nonOptional, value)
		}

		#expect(firstValue != nil, "the pool must hold the cleanup value")

		let secondValue = NSObject()
		pool.registerCleanup(target, \.nonOptional, secondValue)

		#expect(firstValue == nil, "the replaced entry must let its value go")

		pool.cleanup()

		#expect(target.nonOptional === secondValue)
	}


	/// PINS CURRENT BEHAVIOR. Replacing an entry also MOVES it: the implementation filters the old one out and
	/// appends the new one, so a property re-registered late is cleaned up last, after entries that were registered
	/// after it originally.
	///
	/// Harmless when cleanups are independent, which they usually are - and worth stating, because "re-register to
	/// update the value" is not obviously the same thing as "re-register to change the order".

	@Test("Re-registering moves the entry to the end")

	func testReRegistrationMovesToTheEnd()
	{
		let pool = BXCleanupPool()
		let ordered = Ordered()

		pool.registerCleanup(ordered, \.a, 1)
		pool.registerCleanup(ordered, \.b, 1)
		pool.registerCleanup(ordered, \.a, 2)		// same target and keyPath as the first

		pool.cleanup()

		#expect(ordered.log == ["b", "a"], "got \(ordered.log)")
		#expect(ordered.a == 2)
	}


	/// Only the target AND keyPath together identify an entry, so neither alone may collapse two registrations.

	@Test("Different targets and different keyPaths do not replace each other")

	func testIdentityIsTargetAndKeyPath()
	{
		let pool = BXCleanupPool()
		let first = Target()
		let second = Target()

		pool.registerCleanup(first, \.optional, nil)
		pool.registerCleanup(second, \.optional, nil)		// same keyPath, other target
		pool.registerCleanup(first, \.nonOptional, NSObject())	// same target, other keyPath

		pool.cleanup()

		#expect(first.optional == nil)
		#expect(second.optional == nil)
	}


	/// Closures are anonymous, so the pool cannot tell two of them apart and deliberately never treats one as
	/// replacing another. Every registered closure runs, in registration order.

	@Test("Closures accumulate rather than replacing")

	func testClosuresAccumulate()
	{
		let pool = BXCleanupPool()
		let target = Target()

		pool.registerCleanup(target) { $0.log.append("a") }
		pool.registerCleanup(target) { $0.log.append("b") }
		pool.registerCleanup(target) { $0.log.append("c") }

		pool.cleanup()

		#expect(target.log == ["a", "b", "c"])
	}


//----------------------------------------------------------------------------------------------------------------------


	// MARK: - What is held, and for how long


	/// The whole point. A pool that retained its targets would keep alive exactly the objects whose cycles it exists
	/// to break.

	@Test("The target is not retained")

	func testTargetIsNotRetained()
	{
		let pool = BXCleanupPool()

		weak var weakTarget:Target?

		do
		{
			let target = Target()
			weakTarget = target
			pool.registerCleanup(target, \.optional, nil)
			pool.registerCleanup(target) { _ in Issue.record("a dead target must not be cleaned up") }
		}

		#expect(weakTarget == nil, "the pool retained the target")

		// ...and cleaning up afterwards is a no-op rather than a crash

		pool.cleanup()
	}


	/// The cleanup VALUE is the opposite case: it has to be held, or the value to write on cleanup could be gone
	/// before cleanup happens. It must then be let go, or the pool leaks everything it was ever given.

	@Test("The cleanup value is held until cleanup and released after")

	func testCleanupValueLifetime()
	{
		let pool = BXCleanupPool()
		let target = Target()

		weak var weakValue:NSObject?

		do
		{
			let value = NSObject()
			weakValue = value
			pool.registerCleanup(target, \.optional, value)
		}

		#expect(weakValue != nil, "the pool must hold the cleanup value until it is needed")

		pool.cleanup()
		target.optional = nil			// the target now holds it, so drop that reference too

		#expect(weakValue == nil, "the pool held on to the value after cleanup")
	}


//----------------------------------------------------------------------------------------------------------------------


	// MARK: - Re-entering the pool from a cleanup


	/// FIXED, and it was a stack overflow rather than a wrong answer. `cleanup()` used to run its items and empty the
	/// pool AFTERWARDS, so a closure that called cleanup() again - a handler tearing down the object that owns the
	/// pool is the obvious way to get there - re-entered over the same items and recursed until the stack was gone.
	///
	/// The pool is now emptied first, so a nested call finds nothing to do, and every item still runs exactly once.

	@Test("Cleaning up from inside a cleanup does not recurse")

	func testNestedCleanupDoesNotRecurse()
	{
		let pool = BXCleanupPool()
		let target = Target()

		pool.registerCleanup(target)
		{
			target in
			target.log.append("one")
			pool.cleanup()				// re-entrant
		}

		pool.registerCleanup(target) { $0.log.append("two") }

		pool.cleanup()

		#expect(target.log == ["one", "two"], "got \(target.log)")
	}


	/// Registering DURING cleanup is ignored, which stops an object that re-arms itself while being torn down from
	/// leaving the pool armed again afterwards. The entry is dropped, not deferred - a second cleanup does not find it.

	@Test("Registering during cleanup is ignored")

	func testRegistrationDuringCleanupIsIgnored()
	{
		let pool = BXCleanupPool()
		let target = Target()

		pool.registerCleanup(target)
		{
			target in
			target.log.append("first")
			pool.registerCleanup(target) { $0.log.append("nested") }
		}

		pool.cleanup()

		#expect(target.log == ["first"])

		pool.cleanup()

		#expect(target.log == ["first"], "the registration was deferred rather than dropped")
	}


	/// Registration works again once cleanup has finished - the pool is documented as reusable, and an object that
	/// is torn down and set up again relies on it.

	@Test("The pool is reusable and cleanup is idempotent")

	func testPoolIsReusable()
	{
		let pool = BXCleanupPool()
		let target = Target()

		pool.registerCleanup(target) { $0.log.append("first") }

		pool.cleanup()
		pool.cleanup()

		#expect(target.log == ["first"], "the second cleanup ran the same item again")

		pool.registerCleanup(target) { $0.log.append("second") }
		pool.cleanup()

		#expect(target.log == ["first", "second"])
	}
}


//----------------------------------------------------------------------------------------------------------------------
