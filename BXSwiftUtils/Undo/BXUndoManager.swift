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
	/// Various types of entries
	
	public enum Kind
	{
		case group
		case hidden
		case action
		case name
		case warning
		case error
		case marker
	}

	/// A Step records info about a single undo step
	
	public struct Step
	{
		/// A unique identifier for this step is needed for SwiftUI based user interfaces
		
		public let id = Int.nextID
		
		/// A string that describes this step
		
		public var message:String = ""
		
		/// If set thsi step represents a sub-group, which can itself contain other steps
		
		public var group:Group? = nil
		
		/// A stacktrace can be attached to a step for debugging purposes
		
		public var stackTrace:[String]? = nil
		
		/// The kind describes the type of step that was logged
		
		public var kind:Kind = .hidden
	}
	
	
//----------------------------------------------------------------------------------------------------------------------


	// MARK: -
	
	/// A Group constains a list of Steps

	public class Group
	{
		public var name:String? = nil
		{
			willSet { self.publishObjectWillChange() }
		}
		
		public var kind:Kind = .group
		{
			willSet { self.publishObjectWillChange() }
		}
		
		public var steps:[Step] = []
		{
			willSet { self.publishObjectWillChange() }
		}
		
		public var firstWarningStep:Step?
		{
			for step in steps
			{
				if step.kind == .warning { return step }
			}
			
			return nil
		}
		
		public var firstErrorStep:Step?
		{
			for step in steps
			{
				if step.kind == .error { return step }
			}
			
			return nil
		}
	}
	
	/// The stack of open groups
	
	private var groupStack:[Group] = []
	
	/// The current group is at the top of the stack
	
	public var currentGroup:Group? { groupStack.last }

	
//----------------------------------------------------------------------------------------------------------------------


	// MARK: - Logging
	
	/// Set to false to disabled debug logging. Use when performance is critical.
	
	public var enableLogging = true
	
	/// If you want to limit the memory footprint of the log, set this property to the meximum number of top-level steps that are kept in the log
	
	public var maxTopLevelSteps:Int? = nil
	
	/// A list of all recorded Steps
	
	public private(set) var log:[Step] = []
	{
		willSet { self.publishObjectWillChange() }
	}
	
	/// Logs an undo related Step
	
	public func logStep(_ message:String, group:Group? = nil, stackTrace:[String]? = nil, kind:Kind = .hidden)
	{
		if enableLogging
		{
			// Create new Step struct
			
			let step = Step(
				message:message,
				group:group,
				stackTrace:stackTrace,
				kind:kind)
			
			// If we have an open group, then append to the group
			
			if let group = self.currentGroup
			{
				group.steps += step
			}
			
			// Otherwise append to top-level steps
			
			else
			{
				self.log += step
				
				// Optionally, limit the size of the top-level log by purging the oldest entries
				
				if let n1 = self.maxTopLevelSteps
				{
					let n2 = self.log.count
					
					if n2 > n1
					{
						let n3 = n2-n1
						self.log.removeFirst(n3)
					}
				}
			}
		}
	}
	

	/// Resets this UndoManager to an safe state, which can be useful after reaching a corrupted invalid state that would lead to potential crashes if you continued.
	
	open func reset()
	{
		self.addMarker()
		self.logStep(#function, kind:.action)

		while self.groupingLevel > 0
		{
			self.endUndoGrouping()
		}
		
		self.removeAllActions()
		
		_didOpenLongLivedUndoGroup = false
		self.groupStack = []
	}


	/// Appends a marker to the log
	
	open func addMarker()
	{
		self.logStep("", kind:.marker)
	}
	
	
	/// Clear the undo log
	
	open func clearLog()
	{
		self.log = []
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
		self._description(for:self.log)
	}
	
	/// Creates a descriptive String for a list of Steps
	
	private func _description(for steps:[Step], indent:String = "", includeStackTrace:Bool = false) -> String
	{
		var description = ""
		
		for step in steps
		{
			if let group = step.group
			{
				description += self._description(for:group.steps, indent:indent+"   ", includeStackTrace:group.name == nil)
			}
			else
			{
				description += "\(indent)\(step.message)\n"
				
				if let stackTrace = step.stackTrace, includeStackTrace
				{
					for line in stackTrace
					{
						description += "\(indent)    \(line)\n"
					}
				}
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
		else
		{
			let stackTrace = Array(Thread.callStackSymbols.dropFirst(3))
			self.logStep("🛑 beginLongLivedUndoGrouping(): group already open", stackTrace:stackTrace, kind:.error)
		}
	}
	
	/// Ends a long-lived undo group. If you called beginLongLivedUndoGrouping() in mouseDown() you should balance with endLongLivedUndoGrouping()
	/// in mouseUp().
	
	fileprivate func _endLongLivedUndoGrouping()
	{
		if _didOpenLongLivedUndoGroup
		{
			self._didOpenLongLivedUndoGroup = false
			self.endUndoGrouping()
			self.groupsByEvent = true
		}
		else
		{
			let stackTrace = Array(Thread.callStackSymbols.dropFirst(3))
			self.logStep("🛑 endLongLivedUndoGrouping(): no group open", stackTrace:stackTrace, kind:.error)
		}
	}


//----------------------------------------------------------------------------------------------------------------------


	// MARK: - Actions
	
	
	// Override all functions and properties of UndoManager to log each step
	
	override open var groupsByEvent:Bool
	{
		willSet { self.logStep("groupsByEvent = \(newValue)") }
	}

	override open var levelsOfUndo:Int
	{
		willSet { self.logStep("levelsOfUndo = \(newValue)") }
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


//----------------------------------------------------------------------------------------------------------------------


	override open func beginUndoGrouping()
	{
		// Create a new group with an appropriate initial name and kind
		
		var kind:Kind = .warning
		var name = "⚠️ No undo name"
		
		if self.isUndoing
		{
			kind = .group
			name = self.undoActionName
		}
		else if self.isRedoing
		{
			kind = .group
			name = self.redoActionName
		}

		if name.isEmpty
		{
			kind = .warning
			name = "⚠️ No undo name"
		}
		
		let group = Group()
		group.kind = kind
		group.name = name

		// Push the group onto the stack
		
		self.logStep(name, group:group, kind:.group)
		self.groupStack.append(group)

		// Log the beginUndoGrouping()
		
		let stackTrace = Array(Thread.callStackSymbols.dropFirst(3))
		self.logStep(#function, stackTrace:stackTrace)
		
		// Finally call super
		
		self.publishObjectWillChange()
		super.beginUndoGrouping()
	}


//----------------------------------------------------------------------------------------------------------------------


	override open func endUndoGrouping()
	{
		// Log the endUndoGrouping()
		
		let name = self.undoActionName
		if name.isEmpty { self.logStep("⚠️ No undo name", kind:.warning) }
		let stackTrace = Array(Thread.callStackSymbols.dropFirst(3))
		self.logStep(#function, stackTrace:stackTrace)

		// Call super to actually close a group
		
		self.publishObjectWillChange()
		super.endUndoGrouping()

		// Update the preliminary name of a group. It might have been "No undo name" when the group was started,
		// but multiple actionNames might have been set in the meantime, so find the correct name and set it on
		// the group.
		
		if let currentGroup = self.currentGroup, !self.isUndoing && !self.isRedoing
		{
			if let step = currentGroup.firstErrorStep
			{
				currentGroup.kind = step.kind
				currentGroup.name = step.message
			}
			else if let step = currentGroup.firstWarningStep
			{
				currentGroup.kind = step.kind
				currentGroup.name = step.message
			}
			else
			{
				currentGroup.kind = .group
				currentGroup.name = name
			}
		}
		
		// Pop the group off the stack
		
		self.groupStack.removeLast()
	}
		
		
//----------------------------------------------------------------------------------------------------------------------


	override open func registerUndo(withTarget target:Any, selector:Selector, object:Any?)
	{
		// Log the step. Since registering an undo action can internally open a new undo group,
		// defer logging this step until after the group was opened.
		
		defer
		{
			let stacktrace = Array(Thread.callStackSymbols.dropFirst(3))
			let kind:Kind = isUndoRegistrationEnabled ? .action : .hidden
			self.logStep(#function, stackTrace:stacktrace, kind:kind)
		}
		
		// Call super to actually record
		
		super.registerUndo(withTarget:target, selector:selector, object:object)
	}
	
	
	override open func prepare(withInvocationTarget target:Any) -> Any
	{
		// Log the step. Since registering an undo action can internally open a new undo group,
		// defer logging this step until after the group was opened.
		
		defer
		{
			let stacktrace = Array(Thread.callStackSymbols.dropFirst(3))
			let kind:Kind = isUndoRegistrationEnabled ? .action : .hidden
			self.logStep(#function, stackTrace:stacktrace, kind:kind)
		}
		
		// Call super to actually record
		
		return super.prepare(withInvocationTarget:target)
	}
	
	// Unfortunately we cannot override the registerUndo(…) function as it is not defined in the base class,
	// but in an extension, so provide a new function with different name instead. Note the word "Operation"
	// appended to the function name.
	
    open func _registerUndoOperation<TargetType>(withTarget target:TargetType, callingFunction:String = #function, handler: @escaping (TargetType)->Void) where TargetType:AnyObject
    {
		// Log the step. Since registering an undo action can internally open a new undo group,
		// defer logging this step until after the group was opened.
		
		defer
		{
			let stacktrace = Array(Thread.callStackSymbols.dropFirst(3))
			let kind:Kind = isUndoRegistrationEnabled ? .action : .hidden
			self.logStep(#function, stackTrace:stacktrace, kind:kind)
		}
		
		// Call "super" to actually record
		
		return self.registerUndo(withTarget:target, handler:handler)
	}
	

//----------------------------------------------------------------------------------------------------------------------


	override open func undo()
	{
		let level = self.groupingLevel
		
		// If we are at top level, log step and call super to actually undo
		
		if level == 0
		{
			self.logStep(#function, kind:.action)
			super.undo()
		}
		
		// If we still have an open group this is an inconstistent state. Log an error and
		// DO NOT call super, as this would lead to a crash due to unhandled exception.
		
		else if let currentGroup = self.currentGroup
		{
			let message = "🛑 \(#function) called with groupingLevel \(level)"
			self.logStep(message, kind:.error)
			currentGroup.kind = .error
			currentGroup.name = message

//			super.undo() // This would crash due to an exception
		}
	}
	
	
//----------------------------------------------------------------------------------------------------------------------


	override open func redo()
	{
		let level = self.groupingLevel
		
		// If we are at top level, log step and call super to actually redo
		
		if level == 0
		{
			self.logStep(#function, kind:.action)
			super.redo()
		}

		// If we still have an open group this is an inconstistent state. Log an error and
		// DO NOT call super, as this would lead to a crash due to unhandled exception.
		
		else if let currentGroup = self.currentGroup
		{
			let message = "🛑 \(#function) called with groupingLevel \(level)"
			self.logStep(message, kind:.error)
			currentGroup.kind = .error
			currentGroup.name = message

//			super.redo() // This would crash due to an exception
		}
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
		self as? BXUndoManager
	}
	
	var logDescription:String
	{
		bxUndoManager?._logDescription ?? ""
	}
	
	func printLog()
	{
		bxUndoManager?._printLog()
	}

	func beginLongLivedUndoGrouping()
	{
		if let undoManager = bxUndoManager
		{
			undoManager._beginLongLivedUndoGrouping()
		}
		else
		{
			self.groupsByEvent = false
			self.beginUndoGrouping()
		}
	}

	func endLongLivedUndoGrouping()
	{
		if let undoManager = bxUndoManager
		{
			undoManager._endLongLivedUndoGrouping()
		}
		else
		{
			self.endUndoGrouping()
			self.groupsByEvent = true
		}
	}
	
	var isLongLivedUndoGroupOpen : Bool
	{
		bxUndoManager?._didOpenLongLivedUndoGroup ?? false
	}
	
	func registerUndoOperation<TargetType>(withTarget target:TargetType, callingFunction:String = #function, handler: @escaping (TargetType)->Void) where TargetType:AnyObject
    {
		if let undoManager = bxUndoManager
		{
			undoManager._registerUndoOperation(withTarget:target, callingFunction:callingFunction, handler:handler)
		}
		else
		{
			self.registerUndo(withTarget:target, handler:handler)
		}
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


/// Helper to create lightweight, consectutive ID numbers

fileprivate extension Int
{
	static var nextID:Self
	{
		_id += 1
		return _id
	}
	
	static var _id = 0
}


//----------------------------------------------------------------------------------------------------------------------
