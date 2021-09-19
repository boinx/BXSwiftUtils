//**********************************************************************************************************************
//
//  BXUndoManager.swift
//	Custom UndoManager with debugging functionality
//  Copyright ©2020-2021 Peter Baumgartner. All rights reserved.
//
//**********************************************************************************************************************


import Foundation


//----------------------------------------------------------------------------------------------------------------------


open class BXUndoManager : UndoManager
{

	// MARK: - Logging
	
	/// A Step records info about a single undo step
	
	public struct Step
	{
		var level:Int = 0
		var message:String = ""
		var stackTrace:[String]? = nil
		var kind:Kind = .regular
		
		public enum Kind
		{
			case regular
			case unrecorded
			case warning
			case error
		}
	}
	
	/// A list of all recorded Steps
	
	public private(set) var debugLog:[Step] = []

	/// Set to false to disabled debug logging. Use when performance is critical.
	
	public var enableDebugLogging = true
	
	/// Logs an undo related Step
	
	public func logDebugStep(_ message:String, stackTrace:[String]? = nil, kind:Step.Kind = .regular)
	{
		if enableDebugLogging
		{
			self.debugLog += Step(
				level:groupingLevel,
				message:message,
				stackTrace:stackTrace,
				kind:kind)
		}
	}
	
	var _debugLogDescription:String
	{
		return self.debugLog
			.map { String(repeating:"    ", count:$0.level) + $0.message }
			.joined(separator:"\n")
	}
	
	/// Prints the current log to the console output
	
	public func _printDebugLog()
	{
		
		Swift.print("\n\n")
		Swift.print(_debugLogDescription)
	}
	
	
//----------------------------------------------------------------------------------------------------------------------


//	/// A Group includes all Steps between a beginUndoGrouping and endUndoGrouping call
//
//	public class Group
//	{
//		var isOpen:Bool = false
//		var steps:[Step] = []
//	}
//
//	public private(set) var undoStack:[Group] = []
//	public private(set) var redoStack:[Group] = []
//	public private(set) var currentGroup:Group? = nil
	
	
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
			self.logDebugStep("groupsByEvent = \(newValue)")
		}
	}

	override open var levelsOfUndo:Int
	{
		willSet
		{
			self.logDebugStep("levelsOfUndo = \(newValue)")
		}
	}

	override open func disableUndoRegistration()
    {
		self.logDebugStep(#function)
		super.disableUndoRegistration()
    }
        
    override open func enableUndoRegistration()
    {
		self.logDebugStep(#function)
		super.enableUndoRegistration()
    }
    
	override open func beginUndoGrouping()
	{
		self.logDebugStep(#function)
		super.beginUndoGrouping()
	}

	override open func endUndoGrouping()
	{
		let name = self.undoActionName
		
		if name.count == 0
		{
			self.logDebugStep("⚠️ No undo name set for current group", kind:.warning)
		}
		
		super.endUndoGrouping()
		self.logDebugStep(#function)
	}
		
     override open func setActionIsDiscardable(_ discardable:Bool)
     {
		self.logDebugStep("setActionIsDiscardable(\(discardable))")
		super.setActionIsDiscardable(discardable)
     }
          
	override open func setActionName(_ actionName:String)
	{
		self.logDebugStep("actionName = \"\(actionName)\"")
		super.setActionName(actionName)
	}
	
	override open func registerUndo(withTarget target:Any, selector:Selector, object:Any?)
	{
		let stacktrace = Array(Thread.callStackSymbols.dropFirst(3))
		let kind:Step.Kind = isUndoRegistrationEnabled ? .regular : .unrecorded
		self.logDebugStep(#function, stackTrace:stacktrace, kind:kind)
		super.registerUndo(withTarget:target, selector:selector, object:object)
	}
	
	override open func prepare(withInvocationTarget target:Any) -> Any
	{
		let stacktrace = Array(Thread.callStackSymbols.dropFirst(3))
		let kind:Step.Kind = isUndoRegistrationEnabled ? .regular : .unrecorded
		self.logDebugStep(#function, stackTrace:stacktrace, kind:kind)
		return super.prepare(withInvocationTarget:target)
	}
	
	// Unfortunately we cannot override the registerUndo(…) function as it is not defined in the base class,
	// but in an extension, so provide a new function with different name instead.
	
    open func _registerUndoOperation<TargetType>(withTarget target:TargetType, callingFunction:String = #function, handler: @escaping (TargetType)->Void) where TargetType:AnyObject
    {
		let stacktrace = Array(Thread.callStackSymbols.dropFirst(3)) // skip the first 3 internal function that are of no interest
		let kind:Step.Kind = isUndoRegistrationEnabled ? .regular : .unrecorded
		self.logDebugStep("registerUndoOperation() in \(callingFunction)", stackTrace:stacktrace, kind:kind)
		return self.registerUndo(withTarget:target, handler:handler)
	}
	
	override open func undo()
	{
		self.logDebugStep(#function)
		super.undo()
	}
	
	override open func redo()
	{
		self.logDebugStep(#function)
		super.redo()
	}
	

	override open func undoNestedGroup()
	{
		self.logDebugStep(#function)
		super.undoNestedGroup()
	}
		
	override open func removeAllActions()
	{
		self.logDebugStep(#function)
		super.removeAllActions()
	}

	override open func removeAllActions(withTarget target:Any)
	{
		self.logDebugStep("removeAllActions(withTarget:\(target))")
		super.removeAllActions(withTarget:target)
	}
}


//----------------------------------------------------------------------------------------------------------------------


// MARK: - Custom API

// The following mechanism exposed custom API to UndoManager, i.e. no need to cast to BXUndoManager at the call site

public extension UndoManager
{
	/// Casts self to BXUndoManager so that calling custom API is possible without having to cast to BXUndoManager at the call site
	
	func executeCustomAPI(_ closure:(BXUndoManager)->Void)
	{
		guard let undoManager = self as? BXUndoManager else
		{
			assertionFailure("Expected BXUndoManager but found instance of class \(self) instead!")
			return
		}
		
		closure(undoManager)
	}
	
	// Expose the following functions to UndoManager
	
	func beginLongLivedUndoGrouping()
	{
		self.executeCustomAPI()
		{
			$0._beginLongLivedUndoGrouping()
		}
	}

	func endLongLivedUndoGrouping()
	{
		self.executeCustomAPI()
		{
			$0._endLongLivedUndoGrouping()
		}
	}
	
	func registerUndoOperation<TargetType>(withTarget target:TargetType, callingFunction:String = #function, handler: @escaping (TargetType)->Void) where TargetType:AnyObject
    {
		self.executeCustomAPI()
		{
			$0._registerUndoOperation(withTarget:target, callingFunction:callingFunction, handler:handler)
		}
	}
	
	var debugLogDescription:String
	{
		guard let undoManager = self as? BXUndoManager else
		{
			assertionFailure("Expected BXUndoManager but found instance of class \(self) instead!")
			return ""
		}
		
		return undoManager._debugLogDescription
	}
	
	func printDebugLog()
	{
		self.executeCustomAPI()
		{
			$0._printDebugLog()
		}
	}
}


//----------------------------------------------------------------------------------------------------------------------

