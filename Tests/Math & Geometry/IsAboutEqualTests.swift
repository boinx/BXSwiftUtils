//
//  IsAboutEqualTests.swift
//  BXSwiftUtils
//
//  Copyright © 2026 Boinx Software Ltd. & Imagine GbR. All rights reserved.
//

import Testing
import Foundation
import CoreGraphics
@testable import BXSwiftUtils


//----------------------------------------------------------------------------------------------------------------------


/// isAboutEqual is the comparison every FotoMagico test suite reaches for, so a change in what it accepts changes
/// what several hundred assertions mean. Its edge behavior is also what distinguishes it from the neighboring
/// Double.isEqual, and picking the wrong one of those is an easy mistake to make.

@Suite("isAboutEqual")

struct IsAboutEqualTests
{
	// MARK: - Ordinary values


	@Test("Values within the tolerance are equal", arguments:
	[
		(1.0, 1.0),
		(1.0, 1.0 + 1e-12),
		(0.0, -0.0),
		(-5.0, -5.0),
		(1e10, 1e10),
	])

	func testWithinTolerance(_ a:Double, _ b:Double)
	{
		#expect(isAboutEqual(a, b))
	}


	@Test("Values outside the tolerance are not equal", arguments:
	[
		(1.0, 1.1),
		(0.0, 1e-6),
		(-1.0, 1.0),
	])

	func testOutsideTolerance(_ a:Double, _ b:Double)
	{
		#expect(!isAboutEqual(a, b))
	}


	/// The tolerance is INCLUSIVE, so a difference of exactly epsilon still counts as equal.

	@Test("A difference of exactly epsilon is equal")

	func testToleranceIsInclusive()
	{
		#expect(isAboutEqual(1.0, 1.5, epsilon:0.5))
		#expect(!isAboutEqual(1.0, 1.5, epsilon:0.4999))
	}


//----------------------------------------------------------------------------------------------------------------------


	// MARK: - The edges that distinguish it from Double.isEqual


	/// Two infinities of the SAME SIGN are equal. This is the behavior a test needs when a computation is expected
	/// to overflow and the assertion is that it did - and it is where Double.isEqual differs, reporting any
	/// infinity as unequal to everything.

	@Test("Infinities equal themselves, by sign")

	func testInfinities()
	{
		#expect(isAboutEqual(.infinity, .infinity))
		#expect(isAboutEqual(-.infinity, -.infinity))
		#expect(!isAboutEqual(.infinity, -.infinity))
		#expect(!isAboutEqual(.infinity, 1e308))
		#expect(!isAboutEqual(1.0, .infinity))

		// The distinction from the neighboring helper, stated so a change to either is deliberate

		#expect(Double.isEqual(.infinity, .infinity) == false)
	}


	/// NaN is never equal to anything, not even itself, so a caller that accidentally produces one fails loudly
	/// rather than passing on a comparison that is false for the wrong reason.

	@Test("NaN is never equal to anything")

	func testNaN()
	{
		#expect(!isAboutEqual(.nan, .nan))
		#expect(!isAboutEqual(.nan, 1.0))
		#expect(!isAboutEqual(1.0, .nan))
		#expect(!isAboutEqual(.nan, .infinity))
	}


//----------------------------------------------------------------------------------------------------------------------


	// MARK: - The geometry overloads


	@Test("Points compare in both coordinates")

	func testPoints()
	{
		#expect(isAboutEqual(CGPoint(x:1, y:2), CGPoint(x:1, y:2)))
		#expect(!isAboutEqual(CGPoint(x:1, y:2), CGPoint(x:1, y:3)))
		#expect(!isAboutEqual(CGPoint(x:1, y:2), CGPoint(x:9, y:2)))
	}


	@Test("Sizes compare in both dimensions")

	func testSizes()
	{
		#expect(isAboutEqual(CGSize(width:1, height:2), CGSize(width:1, height:2)))
		#expect(!isAboutEqual(CGSize(width:1, height:2), CGSize(width:1, height:3)))
		#expect(!isAboutEqual(CGSize(width:1, height:2), CGSize(width:9, height:2)))
	}


	/// A rect compares origin AND size - all four fields, so a difference in any one of them is caught.

	@Test("Rects compare all four fields")

	func testRects()
	{
		let rect = CGRect(x:1, y:2, width:3, height:4)

		#expect(isAboutEqual(rect, CGRect(x:1, y:2, width:3, height:4)))
		#expect(!isAboutEqual(rect, CGRect(x:9, y:2, width:3, height:4)))
		#expect(!isAboutEqual(rect, CGRect(x:1, y:9, width:3, height:4)))
		#expect(!isAboutEqual(rect, CGRect(x:1, y:2, width:9, height:4)))
		#expect(!isAboutEqual(rect, CGRect(x:1, y:2, width:3, height:9)))
	}


	/// The epsilon reaches every component of the compound overloads rather than only the first.

	@Test("The epsilon applies to every component")

	func testEpsilonReachesEveryComponent()
	{
		let a = CGRect(x:0, y:0, width:0, height:0)
		let b = CGRect(x:0.4, y:0.4, width:0.4, height:0.4)

		#expect(isAboutEqual(a, b, epsilon:0.5))
		#expect(!isAboutEqual(a, b, epsilon:0.3))
	}
}


//----------------------------------------------------------------------------------------------------------------------
