//**********************************************************************************************************************
//
//  BXLogger.swift
//	High level logging functions
//  Copyright ©2017-2019 Peter Baumgartner. All rights reserved.
//
//**********************************************************************************************************************


import Foundation


//----------------------------------------------------------------------------------------------------------------------


public struct BXLogger
{
	/// Initializes a new BXLogger instance without any destinations.
	///
    /// Initializer has to be made explicitly public s.t. instances can be created by consuming modules.
	
    public init() {}

//----------------------------------------------------------------------------------------------------------------------


	/// The level determines which log messages actually get performed at runtime.
	
	public enum Level : Int, Comparable
	{
		case none
		case error
		case warning
		case debug
		case verbose
		case all
		
		public static func <(lhs: Level, rhs: Level) -> Bool
		{
			return lhs.rawValue < rhs.rawValue
		}
	}
	
	/// The maximum level determines which messages actually get passed on to the destinations.
	
	public var maxLevel: Level = .warning
	

//----------------------------------------------------------------------------------------------------------------------


	// MARK: -

   	/// A Destination is simply a closure that takes a Level and a String as an argument and does whatever it
    /// deems appropriate with this info, e.g. send it to the console.
	
	public typealias Destination = (Level, String) -> ()


	/// An array of destinations. Logging output will be sent to all destinations.
	
	internal var destinations: [Destination] = []


    /// Adds a new destination to a BXLogger. Since a destination is simply a closure tthat takes a String as
    /// a parameter there are various things that can be achieved that way. One example would be to call NSLog()
    /// with this string. Another would be to send the string to another BXLogger instance to achieve complex
 	/// filtering through a graph of BXLogger objects.
	
	public mutating func addDestination(_ destination: @escaping Destination)
	{
		self.destinations.append(destination)
	}
	

//----------------------------------------------------------------------------------------------------------------------


	// MARK: -

    /// A Message is a closure that returns a string. The reason we do not use a String parameter directly, is
    /// that string generation may be expensive. By supplying a closure instead, that will only be executed if
    /// the level is right, we avoid costly CPU time if logging is disabled at the current level.
	
	public typealias Message = () -> String
	
	
    /// This is the central logging method. It takes a closure that returns a string. For performance optimization
    /// reasons, this closure will only be executed, if we are below the maximum allowed level. That way expensive
    /// string creation is suppressed, if logging is not needed at runtime.
    ///
    /// - parameter level: Determines whether the message will be logged.
    /// - parameter force: If set to true, the message will be logged regardless of the level
    /// - parameter showLocation: If set to true, the code location will prefix the message
    /// - parameter file: The filename of the logging location
    /// - parameter function: The function name of the logging location
    /// - parameter line: The line number of the logging location
    /// - parameter message: This closure builds and returns the message string that is to be logged.
	
	public func print(	level: Level,
						force: Bool = false,
						showLocation: Bool = false,
						file: String = #file,
						function: String = #function,
						line: Int = #line,
						message: Message)
	{
		if level <= self.maxLevel || force
		{
			var string = message()
			
			if showLocation
			{
				string = "\(file).\(function):\(line)  \(string)"
			}
			
			for destination in self.destinations
			{
				destination(level,string)
			}
		}
	}


    /// Convenience method for logging with error level.
    ///
    /// ## Example
	///
    ///     log.error {"An unknown error has occured"}
	
	public func error(	showLocation: Bool = false,
						file: String = #file,
						function: String = #function,
						line: Int = #line,
						message: Message)
	{
		self.print(		level: .error,
						showLocation: showLocation,
						file: file,
						function: function,
						line: line,
						message: message)
	}
	

    /// Convenience method for logging with warning level.
   	///
    /// ## Example
    ///
    ///    log.warning {"Be careful!"}

	public func warning(showLocation: Bool = false,
						file: String = #file,
						function: String = #function,
						line: Int = #line,
						message: Message)
	{
		self.print(		level: .warning,
						showLocation: showLocation,
						file: file,
						function: function,
						line: line,
						message: message)
	}
	

	/// Convenience method for logging with debug level.
    ///
    /// ## Example
    ///
    ///    log.debug(showLocation:true) {"Step 3"}
	
	public func debug(	showLocation: Bool = false,
						file: String = #file,
						function: String = #function,
						line: Int = #line,
						message: Message)
	{
		self.print(		level: .debug,
						showLocation: showLocation,
						file: file,
						function: function,
						line: line,
						message: message)
	}
	
	
	/// Convenience method for logging with verbose level.
    ///
    /// ## Example
    ///
    ///     log.verbose {"Something really chatty!"}

	public func verbose(showLocation: Bool = false,
						file: String = #file,
						function: String = #function,
						line: Int = #line,
						message: Message)
	{
		self.print(		level: .verbose,
						showLocation: showLocation,
						file: file,
						function: function,
						line: line,
						message: message)
	}
}


//----------------------------------------------------------------------------------------------------------------------


/// The global logger object with a single destination that sends output to the console

public var log: BXLogger =
{
	() -> BXLogger in
	
	var globalLogger = BXLogger()
	globalLogger.addDestination(consoleDestination)
	return globalLogger
}()


/// The standard system console destination uses NSLog()

public let consoleDestination: BXLogger.Destination =
{
    (level: BXLogger.Level, string: String) -> () in
    
	// If enough time elapsed since last log then automatically insert a blank line
	
	BXLogger.recordTimestamp()
	
	if BXLogger.shouldInsertBlankLine
    {
		Swift.print("\n")
	}
    
    // Depending on log level, prefix message with easy to see icons
    
	if level == .error
	{
		NSLog(" 🛑 "+string)
	}
	else if level == .warning
	{
		NSLog(" ⚠️ "+string)
	}
	else
	{
		NSLog("    "+string)
	}
}


//----------------------------------------------------------------------------------------------------------------------


extension BXLogger
{
	/// The time that has to elapsed before a blank line is automatically inserted into the log
	
	static var autoBlankLineDelay:CFAbsoluteTime = 2.0
	
	/// Returns true if a blank line should be inserted into the log
	
	static var shouldInsertBlankLine = false
	
	/// The last timestamp of a log message
	
	private static var lastTimestamp:CFAbsoluteTime = 0.0

	/// This function should be called once when sending a message to the default (console) destination
	
	static func recordTimestamp()
	{
		let now = CFAbsoluteTimeGetCurrent()
		Self.shouldInsertBlankLine = now >= Self.lastTimestamp + Self.autoBlankLineDelay
		Self.lastTimestamp = now
	}
}


//----------------------------------------------------------------------------------------------------------------------
