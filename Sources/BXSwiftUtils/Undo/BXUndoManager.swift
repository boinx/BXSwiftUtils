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
	
	public enum Kind : Int, Codable
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
	
	public struct Step : Codable
	{
		/// A unique identifier for this step is needed for SwiftUI based user interfaces
		
		public private(set) var id = Int.nextID
		
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

	public final class Group : Codable
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
		if _exceptionCount > 0 && kind != .error
		{
			return
		}
			
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


	// MARK: - Error Handling
	
	/// This error handler is called when an exception is thrown because the UndoManager is in an inconsistent state.
	/// The application can set this handler and alert the user, providing further instructions.
	
	public var errorHandler:((Error,String,@escaping ()->Void) -> Void)? = nil
	

	/// Executes the supplied closure. Any exception that are thrown by Apple in the superclass are caught, converted to a Swift error,
	/// and will be reported to the user via an external errorHandler.
	
	private func catchingExceptions(in functionName:StaticString = #function, _ closure:()->Void )
	{
		let stackTrace = Thread.callStackSymbols
		let stack = stackTrace.joined(separator: "\n")

		// Execute the supplied closure. Catch any NSException that are thrown (by Apple)
		// and convert them to a NSError.
		
		do
		{
			try NSException.toSwiftError
			{
				closure()
			}
		}
		
		// Any potential errors are handled here
		
		catch let error
		{
			_exceptionCount += 1
			_error = error
			_stack = stack

			// Log the error to the console
			
			BXSwiftUtils.log.error {"\(Self.self).\(functionName) ERROR \(error)\n\n\(stack)\n"}
			
			// Also log it in the BXUndoManager
			
			if _exceptionCount <= _exceptionLimit
			{
				let description = error.localizedDescription.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
				self.logStep("🛑 \(description)", stackTrace:stackTrace, kind:.error)
			}
		
			// Call the errorHandler (supplied by the host application), which will show an alert to the user
			
			DispatchQueue.main.asyncIfNeeded
			{
				self.performCoalesced(#selector(self.callErrorHandler))
			}
		}
	}

	/// This helper function calls the external errorHandler, which usually shows an alert to the user
	
	@objc private func callErrorHandler()
	{
		if _exceptionCount == 1, let _error = _error, let _stack = _stack
		{
			self.errorHandler?(_error,_stack)
			{
				[weak self] in
				
				DispatchQueue.main.asyncAfter(deadline:.now()+10)
				{
					self?._error = nil
					self?._stack = nil
					self?._exceptionCount = 0
				}
			}
		}
	}
	
	private var _error:Error? = nil
	private var _stack:String? = nil
	private var _exceptionCount = 0
	private let _exceptionLimit = 5
	
	
//----------------------------------------------------------------------------------------------------------------------


	// MARK: - Long Lived Groups
	
	
	/// Returns true if a long-lived group has been started
	
	fileprivate var _didOpenLongLivedUndoGroup = false

	/// Starts a long-lived undo group that lasts across multiple runloop cycles, e.g. from mouse down to mouse up during a drag event.
	
	fileprivate func _beginLongLivedUndoGrouping()
	{
		if self.groupingLevel > 0
		{
			let stackTrace = Thread.callStackSymbols
			self.logStep("🛑 beginLongLivedUndoGrouping() only allowed at top-level", stackTrace:stackTrace, kind:.error)
		}
		else if _didOpenLongLivedUndoGroup
		{
			let stackTrace = Thread.callStackSymbols
			self.logStep("🛑 beginLongLivedUndoGrouping() group already open", stackTrace:stackTrace, kind:.error)
		}
		else
		{
			self.groupsByEvent = false
			self.beginUndoGrouping()

			self._didOpenLongLivedUndoGroup = true
		}
	}
	
	/// Ends a long-lived undo group. If you called beginLongLivedUndoGrouping() in mouseDown() you should balance with endLongLivedUndoGrouping()
	/// in mouseUp().
	
	fileprivate func _endLongLivedUndoGrouping()
	{
		if _didOpenLongLivedUndoGroup
		{
			self._didOpenLongLivedUndoGroup = false
			
			// If the groupingLevel is already at 0 we cannot call endUndoGrouping() again, or this will cause an exception
			// that leads to a serious crash. Since we do not know the cause for the inconsistency, we will alert the user and
			// ask him/her to send us the undo log, so we can analyze it and track down the cause of the problem. The issue is
			// documented at https://boinx.assembla.com/spaces/fotomagico/tickets/realtime_cardwall?ticket=2395
			
			if self.groupingLevel == 0
			{
				let stackTrace = Thread.callStackSymbols
				self.logStep("🛑 endLongLivedUndoGrouping(): groupingLevel is already at 0", stackTrace:stackTrace, kind:.error)

				let location = stackTrace.joined(separator:"\n")
				let userInfo:[String:Any] = ["location":location]
				let error = NSError(domain:"NSInternalInconsistencyException", code:0, userInfo:userInfo)
				self.errorHandler?(error,location,{})
			}
			
			// If the groupingLevel is ok, then we can end the current undo group
			
			else
			{
				self.endUndoGrouping()
				self.groupsByEvent = true
			}
		}
//		else
//		{
//			let stackTrace = Thread.callStackSymbols
//			self.logStep("🛑 endLongLivedUndoGrouping(): no group open", stackTrace:stackTrace, kind:.error)
//		}
	}


//----------------------------------------------------------------------------------------------------------------------


	// MARK: - Actions
	
	
	// Override all functions and properties of UndoManager to log each step
	
	override open var groupsByEvent:Bool
	{
		set
		{
			self.catchingExceptions()
			{
				self.logStep("groupsByEvent = \(newValue)")
				super.groupsByEvent = newValue
			}
		}
		
		get
		{
			super.groupsByEvent
		}
	}

	override open var levelsOfUndo:Int
	{
		set
		{
			self.catchingExceptions()
			{
				self.logStep("levelsOfUndo = \(newValue)")
				super.levelsOfUndo = newValue
			}
		}
		
		get
		{
			super.levelsOfUndo
		}
	}

	override open func disableUndoRegistration()
    {
		self.catchingExceptions()
		{
			self.logStep(#function)
			super.disableUndoRegistration()
		}
    }
        
    override open func enableUndoRegistration()
    {
		self.catchingExceptions()
		{
			self.logStep(#function)
			super.enableUndoRegistration()
		}
    }
    
     override open func setActionIsDiscardable(_ discardable:Bool)
     {
		self.catchingExceptions()
		{
			self.logStep("setActionIsDiscardable(\(discardable))")
			super.setActionIsDiscardable(discardable)
		}
     }
          
	override open func setActionName(_ actionName:String)
	{
		self.catchingExceptions()
		{
			super.setActionName(actionName)
			self.logStep("actionName = \"\(actionName)\"", kind:.name) // Since super.setActionName can lazily start a new undo grou if necessary, log this step afterwards to get correct order
		}
	}
	
	override open func undoNestedGroup()
	{
		self.catchingExceptions()
		{
			self.logStep(#function, kind:.hidden)
			super.undoNestedGroup()
		}
	}
		
	override open func removeAllActions()
	{
		self.catchingExceptions()
		{
			self.logStep(#function, kind:.action)
			super.removeAllActions()
		}
	}

	override open func removeAllActions(withTarget target:Any)
	{
		self.catchingExceptions()
		{
			self.logStep("removeAllActions(withTarget:\(target))", kind:.action)
			super.removeAllActions(withTarget:target)
		}
	}


//----------------------------------------------------------------------------------------------------------------------


	override open func beginUndoGrouping()
	{
		self.catchingExceptions()
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
			
			let stackTrace = Thread.callStackSymbols
			self.logStep(#function, stackTrace:stackTrace)
			
			// Finally call super
			
			self.publishObjectWillChange()
			super.beginUndoGrouping()
		}
	}


//----------------------------------------------------------------------------------------------------------------------


	override open func endUndoGrouping()
	{
		self.catchingExceptions()
		{
			// Log the endUndoGrouping()
			
			let name = self.undoActionName
			if name.isEmpty { self.logStep("⚠️ No undo name", kind:.warning) }

			let stackTrace = Thread.callStackSymbols
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
	}
		
		
//----------------------------------------------------------------------------------------------------------------------


	override open func registerUndo(withTarget target:Any, selector:Selector, object:Any?)
	{
		self.catchingExceptions()
		{
			// Call super to actually record
			
			super.registerUndo(withTarget:target, selector:selector, object:object)
			
			// Log the step. Since registering an undo action can internally open a new undo group,
			// log this step after the group was opened.

			if isUndoRegistrationEnabled
			{
				self.logStep(#function, stackTrace:Thread.callStackSymbols, kind:.action)
			}
		}
	}
	
	
	override open func prepare(withInvocationTarget target:Any) -> Any
	{
		// Call super to actually record
		
		let proxy = super.prepare(withInvocationTarget:target)

		// Log the step. Since registering an undo action can internally open a new undo group,
		// log this step after the group was opened.
		
		if isUndoRegistrationEnabled
		{
			self.logStep(#function, stackTrace:Thread.callStackSymbols, kind:.action)
		}
		
		return proxy
	}
	
	// Unfortunately we cannot override the registerUndo(…) function as it is not defined in the base class,
	// but in an extension, so provide a new function with different name instead. Note the word "Operation"
	// appended to the function name.
	
    open func _registerUndoOperation<TargetType>(withTarget target:TargetType, callingFunction:String = #function, handler: @escaping (TargetType)->Void) where TargetType:AnyObject
    {
		self.catchingExceptions()
		{
			// Call "super" to actually record
			
			self.registerUndo(withTarget:target, handler:handler)

			// Log the step. Since registering an undo action can internally open a new undo group,
			// log this step after the group was opened.
			
			if isUndoRegistrationEnabled
			{
				self.logStep(#function, stackTrace:Thread.callStackSymbols, kind:.action)
			}
		}
	}
	

//----------------------------------------------------------------------------------------------------------------------


	override open func undo()
	{
		self.catchingExceptions()
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
	}
	
	
//----------------------------------------------------------------------------------------------------------------------


	override open func redo()
	{
		self.catchingExceptions()
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

	/// Closes the top level undo group
	
//	func endAllUndoGrouping()
//	{
//		while self.groupingLevel > 0
//		{
//			self.endUndoGrouping()
//		}
//	}
	
	/// Opens a local undo group, executes the supplied closure, and closes the group again. This makes sure that the NSUndoManager doesn't
	/// unexpectedly call beginUndoGrouping, which is then not balanced with a endUndoGrouping - a situation that causes serious trouble down
	/// the road.
	
	func withLocalUndoGroup(_ closure:()->Void)
	{
		let originalState = self.groupsByEvent
		
		self.groupsByEvent = false 			// Without this the following beginUndoGrouping() might be called twice!
		self.beginUndoGrouping()			// Open local group
		
		closure()
		
		self.endUndoGrouping()				// Close local group
		self.groupsByEvent = originalState	// Restore original state
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


// MARK: - Codable Support

public extension BXUndoManager
{
	/// Saves the current log to the specified URL
	
	func saveLog(to url:URL) throws
	{
		let data = try JSONEncoder().encode(self.log)
		try data.write(to:url)
	}

	/// Loads a log file at the specified URL
	
	func loadLog(from url:URL) throws
	{
		let data = try Data(contentsOf:url)
		let log = try JSONDecoder().decode(Array<Step>.self, from:data)
		self.log = log
	}
}


//----------------------------------------------------------------------------------------------------------------------


