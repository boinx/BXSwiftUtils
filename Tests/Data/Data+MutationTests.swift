//
//  Data+MutationTests.swift
//  BXSwiftUtils
//
//  Copyright © 2026 Boinx Software Ltd. & Imagine GbR. All rights reserved.
//

import Testing
import Foundation
@testable import BXSwiftUtils


//----------------------------------------------------------------------------------------------------------------------


/// Two byte-level operations, both of which walk the bytes by index - which is exactly where Data is easy to get
/// wrong, because a Data SLICE keeps its parent's indices rather than starting at zero.

@Suite("Data+Mutation")

struct Data_MutationTests
{
	static func bytes(_ values:[UInt8]) -> Data { Data(values) }
	static func repeated(_ value:UInt8, _ count:Int) -> Data { Data(repeating:value, count:count) }


	// MARK: - XOR


	/// XOR is its own inverse, which is the property the whole thing rests on - applying the same key twice gets the
	/// original back. Asserted as that property rather than as a table of remembered byte values.

	@Test("Applying the same key twice restores the original", arguments:[1, 7, 64, 1000])

	func testXorIsItsOwnInverse(_ count:Int)
	{
		let original = Self.repeated(0x55, count)
		let key = Self.repeated(0xF0, count)

		var data = original
		data.xor(with:key)

		#expect(data != original, "the key had no effect at all")

		data.xor(with:key)

		#expect(data == original)
	}


	@Test("Bytes are combined with the key", arguments:
	[
		// self, key, expected
		([0x00, 0x00], [0xFF, 0xFF], [0xFF, 0xFF]),
		([0xFF, 0xFF], [0xFF, 0xFF], [0x00, 0x00]),
		([0x55, 0x55], [0xFF, 0xFF], [0xAA, 0xAA]),
		([0x0F, 0xF0], [0xFF, 0x0F], [0xF0, 0xFF]),
	])

	func testXorValues(_ input:[UInt8], _ key:[UInt8], _ expected:[UInt8])
	{
		var data = Self.bytes(input)
		data.xor(with:Self.bytes(key))

		#expect(data == Self.bytes(expected))
	}


	/// A key shorter than the data repeats. With no repeat limit it repeats for as long as there are bytes.

	@Test("A short key repeats over the whole length")

	func testShortKeyRepeats()
	{
		var data = Self.repeated(0x00, 1000)
		data.xor(with:Self.repeated(0xFF, 100))

		#expect(data == Self.repeated(0xFF, 1000))
	}


	/// `maximumRepeatCount` stops after that many passes of the key, leaving the rest untouched - which is what makes
	/// it useful for stamping a header rather than a whole buffer.

	@Test("A repeat limit stops the key early")

	func testRepeatLimit()
	{
		var data = Self.repeated(0x00, 6)
		data.xor(with:Self.bytes([0xFF]), maximumRepeatCount:3)

		#expect(data == Self.bytes([0xFF, 0xFF, 0xFF, 0x00, 0x00, 0x00]))

		// A limit longer than the data is simply never reached

		var full = Self.repeated(0x00, 3)
		full.xor(with:Self.bytes([0xFF]), maximumRepeatCount:99)

		#expect(full == Self.bytes([0xFF, 0xFF, 0xFF]))
	}


	/// FIXED. An EMPTY key made `i % n2` a division by zero, which traps. It is now a no-op, which is the only
	/// sensible reading: there is nothing to combine with.

	@Test("An empty key does nothing rather than trapping")

	func testEmptyKey()
	{
		var data = Self.bytes([0x01, 0x02, 0x03])

		data.xor(with:Data())

		#expect(data == Self.bytes([0x01, 0x02, 0x03]))

		data.xor(with:Data(), maximumRepeatCount:2)

		#expect(data == Self.bytes([0x01, 0x02, 0x03]))
	}


	@Test("Empty data has nothing to combine")

	func testEmptyData()
	{
		var data = Data()
		data.xor(with:Self.bytes([0xFF]))

		#expect(data.isEmpty)
	}


	/// FIXED, and this was a CRASH. Both methods walked `0..<count` and subscripted with those numbers, but a Data
	/// SLICE keeps its parent's indices - so `original[2...]` has indices 2..<4, and reading index 0 either returns
	/// the wrong byte or runs off the end and traps.
	///
	/// Not exotic: a slice is what you get from `data[header.count...]`, which is how anyone reads a file format.

	@Test("A slice is combined by its own indices")

	func testSlicesAreHandledByIndex()
	{
		let original = Self.bytes([0x01, 0x02, 0x03, 0x04])

		var slice = original[2...]
		slice.xor(with:Self.bytes([0xFF]))

		#expect(Array(slice) == [0xFC, 0xFB])

		// ...and a slice may equally be the KEY

		var data = Self.bytes([0x00, 0x00])
		data.xor(with:original[2...])

		#expect(Array(data) == [0x03, 0x04])
	}


//----------------------------------------------------------------------------------------------------------------------


	// MARK: - Inverting


	@Test("Every bit is flipped", arguments:
	[
		([0x00], [0xFF]),
		([0xFF], [0x00]),
		([0x55, 0xAA], [0xAA, 0x55]),
		([], []),
	])

	func testInverted(_ input:[UInt8], _ expected:[UInt8])
	{
		#expect(Self.bytes(input).inverted() == Self.bytes(expected))
	}


	/// It returns a COPY - the receiver is untouched, which is the difference between it and `xor` and is not obvious
	/// from a name that could equally describe a mutation.

	@Test("Inverting does not modify the original")

	func testInvertedIsNonMutating()
	{
		let original = Self.bytes([0x0F, 0xF0])
		let inverted = original.inverted()

		#expect(original == Self.bytes([0x0F, 0xF0]))
		#expect(inverted == Self.bytes([0xF0, 0x0F]))
		#expect(inverted.inverted() == original, "inverting twice is the identity")
	}


	/// FIXED alongside xor - the same index assumption, and the same crash on a slice.

	@Test("A slice is inverted by its own indices")

	func testInvertingASlice()
	{
		let original = Self.bytes([0x01, 0x02, 0x03, 0x04])

		let inverted = original[2...].inverted()

		#expect(Array(inverted) == [0xFC, 0xFB])
		#expect(inverted.count == 2)
	}
}


//----------------------------------------------------------------------------------------------------------------------
