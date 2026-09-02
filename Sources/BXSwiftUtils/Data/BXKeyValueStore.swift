//**********************************************************************************************************************
//
//  BXKeyValueStore.swift
//	An abstraction over UserDefaults, so that the storage behind a preference can be swapped out
//  Copyright ©2026 Peter Baumgartner. All rights reserved.
//
//**********************************************************************************************************************


import Foundation


//----------------------------------------------------------------------------------------------------------------------


/// The slice of UserDefaults that most code actually needs, expressed so that the storage can be swapped out.
///
/// The reason it exists is TESTABILITY, and specifically a failure UserDefaults cannot be talked out of: an app with
/// the App Sandbox entitlement keeps its preferences in a container keyed to the app's code signature, so a signature
/// the container does not recognize - an ad-hoc one is enough - makes every write fail SILENTLY. Code that stores a
/// value and reads it back then looks broken for a reason that has nothing to do with it. Injecting a store that keeps
/// its values in memory removes that whole class of problem, and as a bonus a test stops reading and rewriting the
/// preferences of whoever happens to run it.
///
/// Note a scratch `UserDefaults(suiteName:)` is NOT a substitute - it is written through the very same container.
///
/// ## Absence is reported as nil, deliberately
///
/// UserDefaults answers 0, 0.0 or false for a key it has never seen, which is indistinguishable from a stored zero.
/// That has already cost this codebase a real bug: a preference nothing had registered read as 0.0 and was then raised
/// to a power, yielding 0 or NaN, with nothing anywhere to say the value had simply never been set. These accessors
/// return optionals so that a caller has to state what absence means, in the one place that actually knows.
///
/// ## Why the names differ from UserDefaults'
///
/// `stringValue(forKey:)` rather than `string(forKey:)`, so that conforming UserDefaults gains no second overload
/// beside methods it already has - and so that its `double(forKey:) -> Double` and this protocol's
/// `doubleValue(forKey:) -> Double?` can never be mistaken for one another at a call site.

public protocol BXKeyValueStore : AnyObject
{
	func stringValue(forKey key:String) -> String?
	func boolValue(forKey key:String) -> Bool?
	func intValue(forKey key:String) -> Int?
	func doubleValue(forKey key:String) -> Double?
	func dataValue(forKey key:String) -> Data?

	/// Passing nil removes the value, so that the accessors above report it as absent again

	func setStringValue(_ value:String?, forKey key:String)
	func setBoolValue(_ value:Bool?, forKey key:String)
	func setIntValue(_ value:Int?, forKey key:String)
	func setDoubleValue(_ value:Double?, forKey key:String)
	func setDataValue(_ value:Data?, forKey key:String)

	/// Forgets the value entirely. Equivalent to setting nil, but says so without having to name a type it may not be.

	func removeValue(forKey key:String)
}


//----------------------------------------------------------------------------------------------------------------------


// MARK: -

/// UserDefaults is the production store, and this is the only conformance that ships.
///
/// Each accessor asks `object(forKey:)` whether the key is there AT ALL, and only then defers to UserDefaults' own
/// typed getter. That keeps UserDefaults' coercion behavior intact - a value written by an older build as a string
/// still reads back as a number, exactly as before - while adding the one thing it cannot express on its own. The
/// registration domain is still consulted, so a REGISTERED default is correctly reported as present rather than nil.

extension UserDefaults : BXKeyValueStore
{
	public func stringValue(forKey key:String) -> String?
	{
		return self.string(forKey:key)
	}

	public func boolValue(forKey key:String) -> Bool?
	{
		guard self.object(forKey:key) != nil else { return nil }
		return self.bool(forKey:key)
	}

	public func intValue(forKey key:String) -> Int?
	{
		guard self.object(forKey:key) != nil else { return nil }
		return self.integer(forKey:key)
	}

	public func doubleValue(forKey key:String) -> Double?
	{
		guard self.object(forKey:key) != nil else { return nil }
		return self.double(forKey:key)
	}

	/// Already optional in UserDefaults, so there is nothing to add - archived values (a color, say) are the reason
	/// Data belongs in this protocol at all.

	public func dataValue(forKey key:String) -> Data?
	{
		return self.data(forKey:key)
	}


//----------------------------------------------------------------------------------------------------------------------


	public func setStringValue(_ value:String?, forKey key:String)
	{
		self.setOrRemove(value, forKey:key)
	}

	public func setBoolValue(_ value:Bool?, forKey key:String)
	{
		self.setOrRemove(value, forKey:key)
	}

	public func setIntValue(_ value:Int?, forKey key:String)
	{
		self.setOrRemove(value, forKey:key)
	}

	public func setDoubleValue(_ value:Double?, forKey key:String)
	{
		self.setOrRemove(value, forKey:key)
	}

	public func setDataValue(_ value:Data?, forKey key:String)
	{
		self.setOrRemove(value, forKey:key)
	}

	public func removeValue(forKey key:String)
	{
		self.removeObject(forKey:key)
	}


	/// UserDefaults.set(nil, forKey:) already removes, so the else branch is an EQUIVALENT MUTANT - confirmed:
	/// collapsing this to a bare set() survives the whole suite, and no test can be written that would notice.
	/// Kept anyway, because what makes it redundant is Foundation's documented nil handling rather than anything
	/// in this file, and because stating the removal explicitly is what makes the four setters above uniform.

	private func setOrRemove(_ value:Any?, forKey key:String)
	{
		if let value = value
		{
			self.set(value, forKey:key)
		}
		else
		{
			self.removeObject(forKey:key)
		}
	}
}


//----------------------------------------------------------------------------------------------------------------------
