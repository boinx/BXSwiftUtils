//**********************************************************************************************************************
//
//  BXJobQueue.swift
//	A threadsafe queue of job closures that need to be executed by the engine playback thread
//  Copyright ©2022 Peter Baumgartner. All rights reserved.
//
//**********************************************************************************************************************


/// A generic queue of job closures that can be executed by a specific thread.

public class BXJobQueue<Target>
{
	public typealias BXJob = (Target) throws -> Void
	
	private var jobs:[BXJob]
	

	/// Creates a new empty queue
	
	public init()
	{
		self.jobs = []
	}
	

	/// Adds a job closure to the queue
	
	public func addJob(_ job:@escaping BXJob)
	{
		synchronized(self)
		{
			self.jobs += job
		}
	}
	
	public func async(_ job:@escaping BXJob)
	{
		self.addJob(job)
	}
	
	/// Executes all jobs in the queue and empties the queue itself
	
	public func executeJobs(with target:Target) throws
	{
		// Get a local copy of the job list, and empty the queue
		
		let jobs = synchronized(self)
		{
			let copy = self.jobs
			self.jobs.removeAll()
			return copy
		}
		
		// Execute all jobs in the context of the calling thread. The target is supplied to
		// each job as an argument so that retain cycles due to capturing self can be avoided.
		
		for job in jobs
		{
			try job(target)
		}
	}
}


//----------------------------------------------------------------------------------------------------------------------
