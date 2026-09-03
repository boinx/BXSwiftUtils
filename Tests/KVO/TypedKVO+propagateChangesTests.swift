//
//  TypedKVO+propagateChangesTests.swift
//  BXSwiftUtils
//
//  Copyright © 2026 Boinx Software Ltd. & Imagine GbR. All rights reserved.
//

import Testing
import Foundation
@testable import BXSwiftUtils


//----------------------------------------------------------------------------------------------------------------------


/// `propagateChanges` fakes a change notification on one property whenever another one changes, for the cases where
/// KVO's own dependent keys cannot be used - a dependent key living on an NSArrayController, say.
///
/// The thing to hold on to while reading these tests is that NO VALUE IS COPIED. It sends willChangeValue and
/// didChangeValue around nothing at all, so what propagates is the notification and never the data.

@Suite("TypedKVO+propagateChanges")

struct TypedKVO_PropagateChangesTests
{
	final class Origin : NSObject
	{
		@objc dynamic var source:String = "source"
	}


	final class Destination : NSObject
	{
		@objc dynamic var destination:String = "destination"
	}


	/// Counts callbacks that may arrive on another queue.

	final class Counter : @unchecked Sendable
	{
		private var count = 0
		private let lock = NSLock()

		func increment()
		{
			self.lock.lock() ; defer { self.lock.unlock() }
			self.count += 1
		}

		var value:Int
		{
			self.lock.lock() ; defer { self.lock.unlock() }
			return self.count
		}
	}


//----------------------------------------------------------------------------------------------------------------------


	// MARK: - Propagating


	@Test("A change on the origin is reported on the target")

	func testBasicPropagation()
	{
		let origin = Origin()
		let target = Destination()
		let counter = Counter()

		let observation = TypedKVO(target, \.destination, options:[]) { _, _ in counter.increment() }
		let propagation = TypedKVO.propagateChanges(from:origin, \.source, to:target, \.destination)

		#expect(counter.value == 0, "propagation must not fire on creation")

		origin.source = "changed"

		#expect(counter.value == 1)

		withExtendedLifetime((observation, propagation)) { }
	}


	/// THE PART THAT IS EASY TO MISREAD. Only the NOTIFICATION is propagated - the target's property is never
	/// assigned, so anything reading it sees the value it always had.
	///
	/// That is the intended design (it exists to make a computed or derived property re-read itself), but the name
	/// "propagateChanges" invites the other reading, and nothing in the original suite ruled it out.

	@Test("The value itself is not propagated")

	func testValueIsNotCopied()
	{
		let origin = Origin()
		let target = Destination()

		let propagation = TypedKVO.propagateChanges(from:origin, \.source, to:target, \.destination)

		origin.source = "changed"

		#expect(target.destination == "destination", "the value was copied, not just the notification")
		#expect(origin.source == "changed")

		withExtendedLifetime(propagation) { }
	}


	@Test("Releasing the token stops the propagation")

	func testTokenControlsThePropagation()
	{
		let origin = Origin()
		let target = Destination()
		let counter = Counter()

		let observation = TypedKVO(target, \.destination, options:[]) { _, _ in counter.increment() }

		weak var weakPropagation:TypedKVO<Origin,String>?

		do
		{
			let propagation = TypedKVO.propagateChanges(from:origin, \.source, to:target, \.destination)
			weakPropagation = propagation

			origin.source = "first"

			#expect(counter.value == 1)

			withExtendedLifetime(propagation) { }
		}

		#expect(weakPropagation == nil, "the token outlived its scope, so the rest proves nothing")

		origin.source = "second"

		#expect(counter.value == 1, "the propagation outlived its token")

		withExtendedLifetime(observation) { }
	}


	/// The documentation says the target is not retained, and it needs to be true: the usual arrangement has the
	/// target owning the token, so retaining the target would be a cycle that neither side can break.

	@Test("The target is not retained")

	func testTargetIsNotRetained()
	{
		let origin = Origin()
		var propagation:TypedKVO<Origin,String>?

		weak var weakTarget:Destination?

		do
		{
			let target = Destination()
			weakTarget = target
			propagation = TypedKVO.propagateChanges(from:origin, \.source, to:target, \.destination)
		}

		#expect(weakTarget == nil, "the propagation retained its target")

		// ...and firing it now is a no-op rather than a crash

		origin.source = "changed"

		propagation = nil

		#expect(propagation == nil)
	}


//----------------------------------------------------------------------------------------------------------------------


	// MARK: - Delivering on a queue


	/// With a queue, the notification is delivered later rather than inline - which is the whole reason to pass one,
	/// since a synchronous re-entrant notification is exactly what a caller is usually trying to avoid.
	///
	/// Drained with `queue.sync {}` rather than a timeout: on a serial queue that returns only after everything
	/// queued before it has run, so the test is deterministic instead of merely probable.

	@Test("A queue defers the propagation")

	func testAsyncPropagation()
	{
		let origin = Origin()
		let target = Destination()
		let counter = Counter()
		let queue = DispatchQueue(label:"propagation-test")

		let observation = TypedKVO(target, \.destination, options:[]) { _, _ in counter.increment() }
		let propagation = TypedKVO.propagateChanges(from:origin, \.source, to:target, \.destination, asyncOn:queue)

		origin.source = "changed"

		#expect(counter.value == 0, "the propagation was delivered inline despite a queue")

		queue.sync { }

		#expect(counter.value == 1)

		withExtendedLifetime((observation, propagation)) { }
	}


	/// PINS A TRAP. The queue is captured WEAKLY, so a caller who does not keep a strong reference to it - passing
	/// `asyncOn:DispatchQueue(label:"x")` inline is the obvious way - loses the queue immediately, and propagation
	/// silently falls back to being SYNCHRONOUS.
	///
	/// Not a no-op, which would at least be noticeable: the caller gets the inline, re-entrant delivery they passed a
	/// queue to avoid, on whatever thread happened to touch the property. Nothing reports it, and it depends on a
	/// reference the call site may not realise it has to hold.
	///
	/// The `[weak queue]` looks like the `[weak target]` on the line above it rather than a decision - a queue does
	/// not retain the token, so there is no cycle to break here. Capturing it strongly would be a one word fix.

	#warning("PINNED BEHAVIOR: propagateChanges captures its queue weakly, so an unretained queue makes delivery synchronous")

	@Test("An unretained queue silently makes propagation synchronous")

	func testQueueIsCapturedWeakly()
	{
		let origin = Origin()
		let target = Destination()
		let counter = Counter()

		let observation = TypedKVO(target, \.destination, options:[]) { _, _ in counter.increment() }

		var propagation:TypedKVO<Origin,String>?

		do
		{
			let queue = DispatchQueue(label:"transient")
			propagation = TypedKVO.propagateChanges(from:origin, \.source, to:target, \.destination, asyncOn:queue)
		}

		// The queue is gone now. Nothing was retaining it but the closure, and that reference is weak.

		origin.source = "changed"

		#expect(counter.value == 1, "delivery neither happened inline nor was deferred - the propagation did nothing")

		withExtendedLifetime((observation, propagation)) { }
	}
}


//----------------------------------------------------------------------------------------------------------------------
