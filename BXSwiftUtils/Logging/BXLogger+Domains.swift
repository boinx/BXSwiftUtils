//**********************************************************************************************************************
//
//  BXLogger+Domains.swift
//	Convenience setup for multiple flat logging domains
//  Copyright ©2017 Peter Baumgartner. All rights reserved.
//
//**********************************************************************************************************************


extension BXLogger
{
    /**
	 This convenience function dynamically creates a flat list of loggers with the specified domain keys.
	 Frameworks and applications can each create domains as needed at runtime. Make sure that the keys are
	 unique. Supplying a key that is already in use will cause an error to be thrown. After creating the
	 domains, the maxLevel should be sent on each domain (usually as stored in the preferences).
	
			try BXLogger.createDomains(["General","Audio","Video"])
			logDomain["General"].maxLevel = .error
			logDomain["Audio"].maxLevel = .debug
			logDomain["Video"].maxLevel = .error
	
	 - parameter keys: A list of domain keys. Make sure not to supply any keys that are already in use.
	 - throws: `BXLogger.Err.domainAlreadyExists` if one of the domain keys is already in use.
     */
	public static func createDomains(_ keys: [AnyHashable]) throws
	{
		for key in keys
		{
			if logDomain[key] != nil
			{
				throw Err.domainAlreadyExists
			}
			
			var logger = BXLogger()
			logger.addDestination(sendToGlobalLogger)
			logDomain[key] = logger
		}
	}

	
	/// List of possible errors that can occur during domain creation or access.
	
	public enum Err : Error
	{
		case domainAlreadyExists
	}


	// This destination simply passes its log message to the global logger, regardless of level,
	// since the 'force' parameter is true.

	private static func sendToGlobalLogger(level: BXLogger.Level, string: String)
	{
		log.print(level: level, force: true) { string }
	}
}


//----------------------------------------------------------------------------------------------------------------------


/// A flat list of global loggers that can be accessed via domain key.
///
///		logDomain["General"].debug {"This is a message"}

public var logDomain: [AnyHashable: BXLogger] = [:]


//----------------------------------------------------------------------------------------------------------------------
