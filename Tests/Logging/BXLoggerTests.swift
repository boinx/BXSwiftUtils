//
//  BXLoggerTests.swift
//  BXSwiftUtils
//
//  Copyright © 2026 Boinx Software Ltd. & Imagine GbR. All rights reserved.
//

import Testing
import Foundation
@testable import BXSwiftUtils


//----------------------------------------------------------------------------------------------------------------------


/// A logger is mostly a filter, so most of its behavior is about which messages get through - and the original suite
/// covered that part well.
///
/// What it did not cover is the reason the API is shaped the way it is. `Message` is a CLOSURE rather than a String
/// specifically so that building an expensive message costs nothing when the level would discard it, and nothing
/// anywhere checked that the closure is actually left unevaluated. That contract is invisible in every result the
/// logger produces: it can be broken without changing a single logged line.

@Suite("BXLogger")

struct BXLoggerTests
{
	/// Collects what a destination was handed, so a test can assert on levels, messages and ordering.

	final class Sink
	{
		private(set) var entries:[(level:BXLogger.Level, message:String)] = []

		var destination:BXLogger.Destination
		{
			{ level, message in self.entries.append((level, message)) }
		}

		var count:Int { self.entries.count }
		var levels:[BXLogger.Level] { self.entries.map { $0.level } }
		var messages:[String] { self.entries.map { $0.message } }
	}


//----------------------------------------------------------------------------------------------------------------------


	// MARK: - The closure contract


	/// THE REASON `Message` IS A CLOSURE. A message that the level would discard must never be BUILT, or every
	/// suppressed log line still costs whatever its string interpolation costs.
	///
	/// Nothing in the original suite could see this - a suppressed message produces no output either way, so the
	/// contract can be broken without changing anything observable about the logging itself.

	@Test("A suppressed message is never built")

	func testSuppressedMessageIsNotBuilt()
	{
		var built = 0

		var logger = BXLogger()
		logger.addDestination { _, _ in }

		logger.verbose { built += 1 ; return "verbose" }
		logger.debug { built += 1 ; return "debug" }

		#expect(built == 0, "the message closure was evaluated for a level that was filtered out")

		logger.warning { built += 1 ; return "warning" }

		#expect(built == 1, "a message that passes the filter must be built exactly once")
	}


	/// ...and it is built ONCE regardless of how many destinations receive it. The string is made before the loop,
	/// and moving it inside would be an easy and invisible refactor - invisible because every destination would still
	/// receive the same text.

	@Test("A message is built once, not once per destination")

	func testMessageIsBuiltOncePerCall()
	{
		var built = 0

		var logger = BXLogger()
		let first = Sink()
		let second = Sink()
		let third = Sink()

		logger.addDestination(first.destination)
		logger.addDestination(second.destination)
		logger.addDestination(third.destination)

		logger.error { built += 1 ; return "once" }

		#expect(built == 1, "the message was rebuilt for each destination")
		#expect(first.messages == ["once"])
		#expect(second.messages == ["once"])
		#expect(third.messages == ["once"])
	}


//----------------------------------------------------------------------------------------------------------------------


	// MARK: - Filtering


	@Test("Levels are ordered from none to all")

	func testLevelOrdering()
	{
		#expect(BXLogger.Level.none < .error)
		#expect(BXLogger.Level.error < .warning)
		#expect(BXLogger.Level.warning < .debug)
		#expect(BXLogger.Level.debug < .verbose)
		#expect(BXLogger.Level.verbose < .all)

		// Comparable derives the rest from `<`, so this is the whole ordering

		#expect(BXLogger.Level.verbose > .warning)
		#expect(BXLogger.Level.warning >= .warning)
	}


	/// The default is `.warning`, which the original suite pinned deliberately so that a change to it cannot pass
	/// unnoticed - consumers depend on debug and verbose being silent unless they ask for them.

	@Test("The default level admits errors and warnings only")

	func testDefaultLevel()
	{
		var logger = BXLogger()
		let sink = Sink()

		#expect(logger.maxLevel == .warning)

		logger.addDestination(sink.destination)

		logger.verbose { "verbose" }
		logger.debug { "debug" }
		logger.warning { "warning" }
		logger.error { "error" }

		#expect(sink.levels == [.warning, .error])
	}


	/// Raising the level admits more, and the message arrives tagged with ITS OWN level rather than the logger's.

	@Test("Raising the level admits more messages")

	func testCustomLevel()
	{
		var logger = BXLogger()
		let sink = Sink()

		logger.maxLevel = .debug
		logger.addDestination(sink.destination)

		logger.verbose { "verbose" }
		logger.debug { "debug" }
		logger.warning { "warning" }
		logger.error { "error" }

		#expect(sink.levels == [.debug, .warning, .error])
		#expect(sink.messages == ["debug", "warning", "error"])
	}


	/// The two ends of the scale, neither of which had a test. `.none` silences EVERYTHING including errors, which is
	/// the one that matters - it is easy to assume errors always get through.

	@Test("The extremes of the scale behave as their names suggest")

	func testLevelExtremes()
	{
		var silent = BXLogger()
		let silentSink = Sink()
		silent.maxLevel = .none
		silent.addDestination(silentSink.destination)

		silent.error { "error" }
		silent.warning { "warning" }
		silent.verbose { "verbose" }

		#expect(silentSink.count == 0, "maxLevel .none must swallow even errors")

		var everything = BXLogger()
		let everythingSink = Sink()
		everything.maxLevel = .all
		everything.addDestination(everythingSink.destination)

		everything.error { "error" }
		everything.warning { "warning" }
		everything.debug { "debug" }
		everything.verbose { "verbose" }

		#expect(everythingSink.count == 4)
	}


	/// `force` overrides the filter, and it overrides even `.none` - so it really is unconditional rather than merely
	/// generous. It also has to build the message, since it is going to be sent.

	@Test("force bypasses the filter completely")

	func testForce()
	{
		var logger = BXLogger()
		let sink = Sink()
		var built = 0

		logger.maxLevel = .none
		logger.addDestination(sink.destination)

		logger.print(level:.verbose, force:true) { built += 1 ; return "forced" }

		#expect(sink.messages == ["forced"])
		#expect(built == 1)
	}


//----------------------------------------------------------------------------------------------------------------------


	// MARK: - Composition


	@Test("Destinations receive messages in the order they were added")

	func testDestinationOrder()
	{
		var logger = BXLogger()
		var order:[String] = []

		logger.addDestination { _, _ in order.append("first") }
		logger.addDestination { _, _ in order.append("second") }
		logger.addDestination { _, _ in order.append("third") }

		logger.error { "message" }

		#expect(order == ["first", "second", "third"])
	}


	/// PINS A GOTCHA. `BXLogger` is a STRUCT, so it has value semantics: a copy taken before a destination is added
	/// does not have that destination, and a logger passed into a function by value cannot be configured by it.
	///
	/// Easy to trip over precisely because loggers are usually long-lived shared objects in other frameworks, and
	/// because `addDestination` is `mutating` without that being obvious at the call site.

	#warning("PINNED BEHAVIOR: BXLogger is a struct with value semantics")

	@Test("A logger is a value, so copies do not share destinations")

	func testValueSemantics()
	{
		var original = BXLogger()
		let originalSink = Sink()
		original.addDestination(originalSink.destination)

		var copy = original
		let copySink = Sink()
		copy.addDestination(copySink.destination)

		original.error { "message" }

		#expect(originalSink.count == 1)
		#expect(copySink.count == 0, "the copy's destination received a message sent to the original")

		copy.error { "message" }

		#expect(originalSink.count == 2, "the copy still carries the destination it was copied with")
		#expect(copySink.count == 1)
	}


	/// `showLocation` prefixes the message with where it was logged from. Asserted by structure rather than by exact
	/// text, since the file path depends on where the checkout lives.

	@Test("showLocation prefixes the message with the call site")

	func testShowLocation()
	{
		var logger = BXLogger()
		let sink = Sink()
		logger.addDestination(sink.destination)

		logger.error(showLocation:false) { "plain" }
		logger.error(showLocation:true) { "located" }

		#expect(sink.messages.first == "plain", "the location must not be added when it was not asked for")

		let located = sink.messages.last ?? ""

		#expect(located.hasSuffix("located"))
		#expect(located.contains("BXLoggerTests"), "the file should be part of the prefix")
		#expect(located.contains("testShowLocation"), "the function should be part of the prefix")
		#expect(located != "located", "showLocation had no effect")
	}


//----------------------------------------------------------------------------------------------------------------------


	// MARK: - The global logger


	/// The global `log` exists, is configured with the console destination, and starts at the same default level as a
	/// fresh instance. Worth pinning: it is a `var`, so anything in the process can reconfigure it, and a change to
	/// its starting state would be felt everywhere at once.

	@Test("The global logger starts with one destination at the default level")

	func testGlobalLogger()
	{
		#expect(log.maxLevel == .warning)
		#expect(log.destinations.count == 1, "the global logger should have exactly the console destination")
	}
}


//----------------------------------------------------------------------------------------------------------------------
