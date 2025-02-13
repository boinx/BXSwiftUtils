//**********************************************************************************************************************
//
//  NSFileCoordinator+asyncAwait.swift
//	Adds async await support to NSFileCoordinator
//  Copyright ©2025 Peter Baumgartner. All rights reserved.
//
//**********************************************************************************************************************


import Foundation


//----------------------------------------------------------------------------------------------------------------------


public extension NSFileCoordinator
{
    /// Async method to coordinate reading access to a file
	///
	/// Please note that for a cloud based file (iCloud, Dropbox, One Drive, etc) that hasn't been downloaded yet, this call will block until
	/// the file has finished downloading, before the reader closure is called. Read access to the file is guarranteed in the closure.
    
	@discardableResult func coordinate<T>(readingItemAt url:URL, options:NSFileCoordinator.ReadingOptions = [], byAccessor reader:@escaping (URL) async throws -> T) async throws -> T
    {
        try await withCheckedThrowingContinuation
        {
			continuation in
			
            self.coordinate(readingItemAt:url, options:options, error:nil)
            {
				fileURL in
				
                Task
                {
                    do
                    {
                    	let result = try await reader(fileURL)
						continuation.resume(returning:result)
                    }
                    catch
                    {
                        continuation.resume(throwing:error)
                    }
                }
            }
        }
    }
    
    
    /// Async method to coordinate reading access to a file
	///
	/// Please note that for a cloud based file (iCloud, Dropbox, One Drive, etc) that hasn't been downloaded yet, this call will block until
	/// the file has finished downloading, before the reader closure is called. Read access to the file is guarranteed in the closure.
    
    @discardableResult class func coordinate<T>(readingItemAt url:URL, options:NSFileCoordinator.ReadingOptions = [], byAccessor reader:@escaping (URL) async throws -> T) async throws -> T
    {
		try await NSFileCoordinator(filePresenter:nil).coordinate(readingItemAt:url, options:options, byAccessor:reader)
    }
    
    /// Async method to coordinate writing access to a file (if needed)
    
    func coordinate(writingItemAt url:URL, options:NSFileCoordinator.WritingOptions = [], byAccessor writer:@escaping (URL) async throws -> Void) async throws
    {
        try await withCheckedThrowingContinuation
        {
			continuation in
			
            self.coordinate(writingItemAt:url, options:options, error:nil)
            {
				fileURL in
				
                Task
                {
                    do
                    {
                        try await writer(fileURL)
                        continuation.resume()
                    }
                    catch
                    {
                        continuation.resume(throwing: error)
                    }
                }
            }
        }
    }


    /// Async method to coordinate writing access to a file (if needed)
    
    class func coordinate(writingItemAt url:URL, options:NSFileCoordinator.WritingOptions = [], byAccessor writer:@escaping (URL) async throws -> Void) async throws
	{
		try await NSFileCoordinator(filePresenter:nil).coordinate(writingItemAt:url, options:options, byAccessor:writer)
	}

}


//----------------------------------------------------------------------------------------------------------------------


public extension URL
{
	/// If the file at this URL is a cloud based item (e.g. on iCloud Drive, Dropbox, One Drive, etc) and the file isn't available locally yet, this function triggers
	/// a download. The read closure is called when the download has finished.
	
    @discardableResult func downloadFromCloudIfNeeded<T>(options:NSFileCoordinator.ReadingOptions = [.resolvesSymbolicLink], byAccessor reader:@escaping (URL) async throws -> T) async throws -> T
    {
		try await NSFileCoordinator(filePresenter:nil).coordinate(readingItemAt:self, options:options, byAccessor:reader)
    }
}


//----------------------------------------------------------------------------------------------------------------------
