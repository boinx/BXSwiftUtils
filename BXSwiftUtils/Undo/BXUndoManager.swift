//**********************************************************************************************************************
//
//  BXUndoManager.swift
//	Custom UndoManager with debugging functionality
//  Copyright ©2020-2021 Peter Baumgartner. All rights reserved.
//
//**********************************************************************************************************************


import Foundation

#if canImport(Combine)
import Combine
#endif


//----------------------------------------------------------------------------------------------------------------------


open class BXUndoManager : UndoManager
{

	/// A Step records info about a single undo step
	
	public struct Step
	{
		/// A unique identifier for this step is needed for SwiftUI based user interfaces
		
		public let id = Self.nextID
		private static var nextID:Int { _id += 1; return _id }
		private static var _id = 0
		
		/// A string that describes this step
		
		public var message:String = ""
		
		/// If set thsi step represents a sub-group, which can itself contain other steps
		
		public var group:Group? = nil
		
		/// A stacktrace can be attached to a step for debugging purposes
		
		public var stackTrace:[String]? = nil
		
		/// The kind describes the type of step that was logged
		
		public var kind:Kind = .hidden
		
		public enum Kind
		{
			case group
			case hidden
			case action
			case name
			case warning
			case error
		}
	}
	
	
//----------------------------------------------------------------------------------------------------------------------


	// MARK: -
	
	/// A Group constains a list of Steps

	public class Group
	{
		public var isOpen:Bool = false
		
		public var steps:[Step] = []
		{
			willSet { self.publishObjectWillChange() }
		}
	}
	
	/// The stack of open groups
	
	private var groups:[Group] = []
	
	/// The current group is at the top of the stack
	
	private var currentGroup:Group? { groups.last }

	
//----------------------------------------------------------------------------------------------------------------------


	// MARK: - Logging
	
	/// Set to false to disabled debug logging. Use when performance is critical.
	
	public var enableLogging = true
	
	/// A list of all recorded Steps
	
	public private(set) var log:[Step] = []
	{
		willSet { self.publishObjectWillChange() }
	}
	
	/// Logs an undo related Step
	
	public func logStep(_ message:String, group:Group? = nil, stackTrace:[String]? = nil, kind:Step.Kind = .hidden)
	{
		if enableLogging
		{
			let step = Step(
				message:message,
				group:group,
				stackTrace:stackTrace,
				kind:kind)
			
			if let group = self.currentGroup
			{
				group.steps += step
			}
			else
			{
				self.log += step
			}
		}
	}
	

//----------------------------------------------------------------------------------------------------------------------


	/// Prints the current log to the console output
	
	fileprivate func _printLog()
	{
		Swift.print("\nUNDO LOG\n")
		Swift.print(_logDescription)
	}
	
	/// Returns the current log as a String, e.g. for logigng to the Console
	
	fileprivate var _logDescription:String
	{
		self.description(for:self.log)
	}
	
	/// Creates a descriptive String for a list of Steps
	
	private func description(for steps:[Step], indent:String = "") -> String
	{
		var description = ""
		
		for step in steps
		{
			if let group = step.group
			{
				description += self.description(for:group.steps, indent:indent+"   ")
			}
			else
			{
				description += "\(indent)\(step.message)\n"
			}
		}

		return description
	}


//----------------------------------------------------------------------------------------------------------------------


	// MARK: - Long Lived Groups
	
	
	/// Returns true if a long-lived group has been started
	
	fileprivate var _didOpenLongLivedUndoGroup = false

	/// Starts a long-lived undo group that lasts across multiple runloop cycles, e.g. from mouse down to mouse up during a drag event.
	
	fileprivate func _beginLongLivedUndoGrouping()
	{
		if !_didOpenLongLivedUndoGroup
		{
			self._didOpenLongLivedUndoGroup = true
			self.groupsByEvent = false
			self.beginUndoGrouping()
		}
	}
	
	/// Ends a long-lived undo group. Please note that this function has no effects, if no long-lived undo group has been started.
	
	fileprivate func _endLongLivedUndoGrouping()
	{
		if _didOpenLongLivedUndoGroup
		{
			self._didOpenLongLivedUndoGroup = false
			self.endUndoGrouping()
			self.groupsByEvent = true
		}
	}


//----------------------------------------------------------------------------------------------------------------------


	// MARK: - Actions
	
	
	// Override all functions an properties of UndoManager to log each step
	
	override open var groupsByEvent:Bool
	{
		willSet
		{
			self.logStep("groupsByEvent = \(newValue)")
		}
	}

	override open var levelsOfUndo:Int
	{
		willSet
		{
			self.logStep("levelsOfUndo = \(newValue)")
		}
	}

	override open func disableUndoRegistration()
    {
		self.logStep(#function)
		super.disableUndoRegistration()
    }
        
    override open func enableUndoRegistration()
    {
		self.logStep(#function)
		super.enableUndoRegistration()
    }
    
	override open func beginUndoGrouping()
	{
		let group = Group()
		group.isOpen = true
		self.logStep("Group", group:group, kind:.group)
		self.groups += group

		self.logStep(#function)
		super.beginUndoGrouping()
	}

	override open func endUndoGrouping()
	{
		let name = self.undoActionName
		
		if name.count == 0
		{
			self.logStep("⚠️ No undo name set for current group", kind:.warning)
		}
		
		self.logStep(#function)
		super.endUndoGrouping()

		self.currentGroup?.isOpen = false
		self.groups.removeLast()
	}
		
     override open func setActionIsDiscardable(_ discardable:Bool)
     {
		self.logStep("setActionIsDiscardable(\(discardable))")
		super.setActionIsDiscardable(discardable)
     }
          
	override open func setActionName(_ actionName:String)
	{
		self.logStep("actionName = \"\(actionName)\"", kind:.name)
		super.setActionName(actionName)
	}
	
	override open func registerUndo(withTarget target:Any, selector:Selector, object:Any?)
	{
		let stacktrace = Array(Thread.callStackSymbols.dropFirst(3))
		let kind:Step.Kind = isUndoRegistrationEnabled ? .action : .hidden
		self.logStep(#function, stackTrace:stacktrace, kind:kind)
		super.registerUndo(withTarget:target, selector:selector, object:object)
	}
	
	override open func prepare(withInvocationTarget target:Any) -> Any
	{
		let stacktrace = Array(Thread.callStackSymbols.dropFirst(3))
		let kind:Step.Kind = isUndoRegistrationEnabled ? .action : .hidden
		self.logStep(#function, stackTrace:stacktrace, kind:kind)
		return super.prepare(withInvocationTarget:target)
	}
	
	// Unfortunately we cannot override the registerUndo(…) function as it is not defined in the base class,
	// but in an extension, so provide a new function with different name instead.
	
    open func _registerUndoOperation<TargetType>(withTarget target:TargetType, callingFunction:String = #function, handler: @escaping (TargetType)->Void) where TargetType:AnyObject
    {
		let stacktrace = Array(Thread.callStackSymbols.dropFirst(3)) // skip the first 3 internal function that are of no interest
		let kind:Step.Kind = isUndoRegistrationEnabled ? .action : .hidden
		self.logStep("registerUndoOperation() in \(callingFunction)", stackTrace:stacktrace, kind:kind)
		return self.registerUndo(withTarget:target, handler:handler)
	}
	
	override open func undo()
	{
		let level = self.groupingLevel
		
		if level == 0
		{
			self.logStep(#function, kind:.action)
		}
		else
		{
			self.logStep("\(#function) called with groupingLevel \(level)", kind:.error)
		}
		
		super.undo()
	}
	
	override open func redo()
	{
		let level = self.groupingLevel
		
		if level == 0
		{
			self.logStep(#function, kind:.action)
		}
		else
		{
			self.logStep("\(#function) called with groupingLevel \(level)", kind:.error)
		}
		
		super.redo()
	}
	

	override open func undoNestedGroup()
	{
		self.logStep(#function, kind:.hidden)
		super.undoNestedGroup()
	}
		
	override open func removeAllActions()
	{
		self.logStep(#function, kind:.action)
		super.removeAllActions()
	}

	override open func removeAllActions(withTarget target:Any)
	{
		self.logStep("removeAllActions(withTarget:\(target))", kind:.action)
		super.removeAllActions(withTarget:target)
	}
}


//----------------------------------------------------------------------------------------------------------------------


// MARK: - Custom API

// The following mechanism exposes custom API to UndoManager, i.e. no need to cast to BXUndoManager at the call site

public extension UndoManager
{
	/// Casts self to BXUndoManager so that calling custom API is possible without having to cast to BXUndoManager at the call site

	var bxUndoManager:BXUndoManager?
	{
		guard let undoManager = self as? BXUndoManager else
		{
			assertionFailure("Expected BXUndoManager but found instance of class \(self) instead!")
			return nil
		}
		
		return undoManager
	}

	func beginLongLivedUndoGrouping()
	{
		bxUndoManager?._beginLongLivedUndoGrouping()
	}

	func endLongLivedUndoGrouping()
	{
		bxUndoManager?._endLongLivedUndoGrouping()
	}
	
	func registerUndoOperation<TargetType>(withTarget target:TargetType, callingFunction:String = #function, handler: @escaping (TargetType)->Void) where TargetType:AnyObject
    {
		bxUndoManager?._registerUndoOperation(withTarget:target, callingFunction:callingFunction, handler:handler)
	}
	
	var logDescription:String
	{
		return bxUndoManager?._logDescription ?? ""
	}
	
	func printLog()
	{
		bxUndoManager?._printLog()
	}
}


//----------------------------------------------------------------------------------------------------------------------


// MARK: - Combine Compatibility

// When running on moderns systems, provide compatibilty with SwiftUI

@available(macOS 10.15, iOS 13, *) extension BXUndoManager : ObservableObject
{

}

@available(macOS 10.15, iOS 13, *) extension BXUndoManager.Group : ObservableObject
{

}

public extension BXUndoManager
{
	@objc func publishObjectWillChange()
	{
		if #available(macOS 10.15, iOS 13, *)
		{
			DispatchQueue.main.asyncIfNeeded
			{
				self.objectWillChange.send()
			}
		}
	}
}

public extension BXUndoManager.Group
{
	@objc func publishObjectWillChange()
	{
		if #available(macOS 10.15, iOS 13, *)
		{
			DispatchQueue.main.asyncIfNeeded
			{
				self.objectWillChange.send()
			}
		}
	}
}


//----------------------------------------------------------------------------------------------------------------------

