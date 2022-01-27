//**********************************************************************************************************************
//
//  BXStopWatch.swift
//	High level time measuring for customer machines (i.e. where OSSignpost is not usable)
//  Copyright ©2019 Peter Baumgartner. All rights reserved.
//
//**********************************************************************************************************************


import Foundation


//----------------------------------------------------------------------------------------------------------------------


/// BXStopWatch is a small lightweight struct that lets you log execution time of function on customer machines
/// and log the results to the console.
///
///	    func example()
///	    {
///	        let stopwatch = BXStopWatch()
///
///	        ...
///
///	        stopwatch.stop()
///	        {
///	            log.verbose { "Function example() took \($0.microsecs) µs to execute" }
///	        }
///	    }

public struct BXStopWatch
{
	/// The recorded start time (in seconds)
	
	public private(set) var startTime: CFAbsoluteTime = 0.0

	/// The recorded stop time (in seconds)
	
	public private(set) var stopTime: CFAbsoluteTime = 0.0


	// MARK: -
	
	/// Creates as BXStopWatch instance and records the startTime
	
    public init()
    {
		self.startTime = CFAbsoluteTimeGetCurrent()
    }

	// Records the stopTime and calls the loggingHandler
	
	public mutating func stop(with loggingHandler: (BXStopWatch)->Void)
	{
		self.stopTime = CFAbsoluteTimeGetCurrent()
		loggingHandler(self)
	}


	// MARK: -
	
	public var seconds: Double
	{
		return stopTime - startTime
	}
	
	public var millisecs: Int
	{
		return Int(self.seconds * 1000.0 + 0.5)
	}
	
	public var microsecs: Int
	{
		return Int(self.seconds * 1000000.0 + 0.5)
	}
	
	public var nanosecs: Int
	{
		return Int(self.seconds * 1000000000.0 + 0.5)
	}
}


//----------------------------------------------------------------------------------------------------------------------
