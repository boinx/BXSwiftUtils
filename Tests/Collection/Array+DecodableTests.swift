//
//  Array+DecodableTests.swift
//  BXSwiftUtils
//
//  Copyright © 2026 Boinx Software Ltd. & Imagine GbR. All rights reserved.
//

import Testing
import Foundation
@testable import BXSwiftUtils


//----------------------------------------------------------------------------------------------------------------------


fileprivate class VisualObject : NSObject, Codable
{
	let identifier:String

	init(identifier:String = UUID().uuidString)
	{
		self.identifier = identifier
		super.init()
	}

	private enum CodingKeys : String, CodingKey { case className, identifier }

	func encode(to encoder:Encoder) throws
	{
		var container = encoder.container(keyedBy:CodingKeys.self)
		try container.encode(self.identifier, forKey:.identifier)
	}

	required init(from decoder:Decoder) throws
	{
		let container = try decoder.container(keyedBy:CodingKeys.self)
		self.identifier = try container.decode(String.self, forKey:.identifier)
	}
}


fileprivate class ImageObject : VisualObject
{
	let url:String

	init(url:String)
	{
		self.url = url
		super.init(identifier:url)
	}

	private enum CodingKeys : String, CodingKey { case className, url }

	override func encode(to encoder:Encoder) throws
	{
		try super.encode(to:encoder)

		var container = encoder.container(keyedBy:CodingKeys.self)
		try container.encode("ImageObject", forKey:.className)
		try container.encode(self.url, forKey:.url)
	}

	required init(from decoder:Decoder) throws
	{
		let container = try decoder.container(keyedBy:CodingKeys.self)
		self.url = try container.decode(String.self, forKey:.url)
		try super.init(from:decoder)
	}
}


fileprivate class VideoObject : VisualObject
{
	let duration:Double

	init(duration:Double)
	{
		self.duration = duration
		super.init(identifier:"video")
	}

	private enum CodingKeys : String, CodingKey { case className, duration }

	override func encode(to encoder:Encoder) throws
	{
		try super.encode(to:encoder)

		var container = encoder.container(keyedBy:CodingKeys.self)
		try container.encode("VideoObject", forKey:.className)
		try container.encode(self.duration, forKey:.duration)
	}

	required init(from decoder:Decoder) throws
	{
		let container = try decoder.container(keyedBy:CodingKeys.self)
		self.duration = try container.decode(Double.self, forKey:.duration)
		try super.init(from:decoder)
	}
}


fileprivate typealias Mapper = (String) throws -> VisualObject.Type?

fileprivate struct MissingMapper : Error {}

fileprivate extension CodingUserInfoKey
{
	static let mapper = CodingUserInfoKey(rawValue:"BXSwiftUtils.tests.mapper")!
}


//----------------------------------------------------------------------------------------------------------------------


/// Decodes an array whose elements are different SUBCLASSES, which Codable cannot do on its own - it decodes each
/// element as the declared type and loses everything the subclass added.
///
/// It works by walking the array TWICE: once to ask the caller's mapper what each element's type is, and again to
/// decode each element as that type. Which means the two passes have to stay in step, and what happens when they do
/// not is the part worth testing.

@Suite("Array+Decodable")

struct Array_DecodableTests
{
	/// A container whose mapper can be swapped, so a test can decide what each element maps to.

	fileprivate struct Slide : Codable
	{
		let visualObjects:[VisualObject]

		init(visualObjects:[VisualObject]) { self.visualObjects = visualObjects }

		private enum CodingKeys : String, CodingKey { case visualObjects }
		private enum ChildKeys : String, CodingKey { case className }

		init(from decoder:Decoder) throws
		{
			let container = try decoder.container(keyedBy:CodingKeys.self)

			// The mapper travels in userInfo rather than in a static. Swift Testing runs these tests in PARALLEL,
			// and a shared static mapper meant one test's deliberately throwing mapper was picked up by another -
			// which is exactly what happened the first time this suite was written.

			guard let mapper = decoder.userInfo[.mapper] as? Mapper else { throw MissingMapper() }

			self.visualObjects = try container.decodeHeterogeneousArray(forKey:.visualObjects)
			{
				itemDecoder in

				let item = try itemDecoder.container(keyedBy:ChildKeys.self)
				let className = try item.decodeIfPresent(String.self, forKey:.className) ?? ""

				return try mapper(className)
			}
		}
	}


	fileprivate static let byClassName:(String) -> VisualObject.Type? =
	{
		switch $0
		{
			case "ImageObject":	return ImageObject.self
			case "VideoObject":	return VideoObject.self
			default:			return nil
		}
	}


	fileprivate static func roundTrip(_ objects:[VisualObject], mapper:@escaping Mapper) throws -> [VisualObject]
	{
		let data = try JSONEncoder().encode(Slide(visualObjects:objects))

		let decoder = JSONDecoder()
		decoder.userInfo[.mapper] = mapper

		return try decoder.decode(Slide.self, from:data).visualObjects
	}


//----------------------------------------------------------------------------------------------------------------------


	/// The whole point: each element comes back as the subclass it went in as, with the subclass's own properties.

	@Test("Elements come back as their own subclasses")

	func testHeterogeneousRoundTrip() throws
	{
		let originals:[VisualObject] =
		[
			ImageObject(url:"one.png"),
			ImageObject(url:"two.png"),
			VideoObject(duration:5.0),
			ImageObject(url:"three.png"),
		]

		let decoded = try Self.roundTrip(originals, mapper:Self.byClassName)

		#expect(decoded.count == 4)
		#expect(decoded.map { NSStringFromClass(type(of:$0)) } == originals.map { NSStringFromClass(type(of:$0)) })

		#expect((decoded[0] as? ImageObject)?.url == "one.png")
		#expect((decoded[2] as? VideoObject)?.duration == 5.0)
		#expect((decoded[3] as? ImageObject)?.url == "three.png")
	}


	@Test("An empty array decodes to an empty array")

	func testEmptyArray() throws
	{
		#expect(try Self.roundTrip([], mapper:Self.byClassName).isEmpty)
	}


	/// PINS A REAL DEFECT. A mapper returning nil does NOT skip that element - it drops the LAST one instead, and
	/// every element after the nil is decoded as the wrong type.
	///
	/// The first pass appends only the non-nil types, so it ends up with fewer types than there are elements. The
	/// second pass then walks the array from the beginning and decodes elements 0, 1, 2... against types 0, 1, 2...
	/// which are no longer the types of those elements. Here three identical images with the MIDDLE one unmapped come
	/// back as the first two - the third is silently lost, and no error is raised.
	///
	/// A caller would reasonably expect either "skip that element" or "throw". It does neither.

	#warning("PINNED BEHAVIOR: decodeHeterogeneousArray drops the LAST element when its type mapper returns nil")

	@Test("A nil from the mapper misaligns the array rather than skipping an element")

	func testNilMapperMisalignsTheArray() throws
	{
		let originals:[VisualObject] =
		[
			ImageObject(url:"one.png"),
			ImageObject(url:"two.png"),
			ImageObject(url:"three.png"),
		]

		var seen = 0

		// Refuse to map the SECOND element, and accept the others

		let decoded = try Self.roundTrip(originals)
		{
			className in
			defer { seen += 1 }
			return seen == 1 ? nil : Self.byClassName(className)
		}

		#expect(seen == 3, "the mapper is asked about every element")

		#expect(decoded.count == 2, "one fewer element came back, as expected")

		// ...but it is the LAST that is missing, not the one that was refused

		#expect((decoded[0] as? ImageObject)?.url == "one.png")
		#expect((decoded[1] as? ImageObject)?.url == "two.png", "the refused element was decoded anyway")
	}


	/// An error from the mapper propagates rather than being swallowed, which is the only way a caller can reject an
	/// element it does not recognise and have anybody notice.

	@Test("An error from the mapper reaches the caller")

	func testMapperErrorPropagates()
	{
		struct Unrecognised : Error {}

		#expect(throws:Unrecognised.self)
		{
			_ = try Self.roundTrip([ImageObject(url:"one.png")]) { _ in throw Unrecognised() }
		}
	}


	/// Decoding an element as a type that does not fit its JSON throws, rather than producing a half-built object -
	/// so a mapper that is merely wrong fails loudly, unlike one that returns nil.

	@Test("A mapper naming the wrong type throws")

	func testWrongTypeThrows()
	{
		#expect(throws:(any Error).self)
		{
			_ = try Self.roundTrip([ImageObject(url:"one.png")]) { _ in VideoObject.self }
		}
	}
}


//----------------------------------------------------------------------------------------------------------------------
