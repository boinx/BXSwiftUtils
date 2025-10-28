//**********************************************************************************************************************
//
//  URL+download.swift
//  Provides reachabilty check and download functionality
//  Copyright ©2025 Imagine Software GmbH. All rights reserved.
//
//**********************************************************************************************************************


import Foundation


//----------------------------------------------------------------------------------------------------------------------


extension URL
{
    public enum DownloadError : Error
    {
        case invalidURL
        case fileNotFound
        case invalidResponse
		case httpStatus(code:Int)
        case networkError(underlying:Error)
		case fileMoveFailed(underlying:Error)
    }
    



    /// Checks if the URL is reachable using a completion handler.
    /// - For file URLs: returns true if the file exists on disk.
    /// - For remote URLs: sends a `HEAD` request to verify existence without downloading the full content.
	
    public func isReachable(_ completionHandler:@escaping (Bool,DownloadError?)->Void)
    {
		// File URLS just check whether the file file exists. No check for readability due to sandbox restrictions.
		
        if isFileURL
        {
            let exists = self.exists
            let error:DownloadError? = exists ? nil : .fileNotFound
            completionHandler(exists,error)
            return
        }
        
        // For internet URLs do a head request, which just checks if the URL is downloadable, without actually
        // doing the work of downloading it (important for large files)
        
        var request = URLRequest(url: self)
        request.httpMethod = "HEAD"
        request.timeoutInterval = 10
        
        let task = URLSession.shared.dataTask(with:request)
        {
			_,response,error in
			
			// Can we reach the internet?
			
            if let error = error
            {
                completionHandler(false,.networkError(underlying:error))
                return
            }
            
            // Did we get a response
            
            guard let httpResponse = response as? HTTPURLResponse else
            {
                completionHandler(false,.invalidResponse)
                return
            }
            
            // Check the HTTP response code
            
            if (200..<400).contains(httpResponse.statusCode)
            {
                completionHandler(true, nil)
            }
            else
            {
                completionHandler(false, .httpStatus(code: httpResponse.statusCode))
            }
        }
        
        task.resume()
    }
 
 
	/// Fetches the `Last-Modified` date of a remote resource if provided by the server.
	
    public func fetchModificationDate(_ completionHandler: @escaping (Date?,DownloadError?)->Void)
    {
		// For file URLs return the modification date immediately
		
        if self.isFileURL
        {
			let date = self.modificationDate
            completionHandler(date,nil)
            return
        }
        
        // For remote URLs ask the server via a HEAD request
        
        var request = URLRequest(url:self)
        request.httpMethod = "HEAD"
        request.timeoutInterval = 10
        
        let task = URLSession.shared.dataTask(with:request)
        {
			_,response,error in
			
			// Can we reach the internet?
			
            if let error = error
            {
                completionHandler(nil, .networkError(underlying: error))
                return
            }
            
            // Did we get a response
            
            guard let httpResponse = response as? HTTPURLResponse else
            {
                completionHandler(nil, .invalidResponse)
                return
            }
            
            // Check the HTTP response code
            
            guard (200..<400).contains(httpResponse.statusCode) else
            {
                completionHandler(nil, .httpStatus(code: httpResponse.statusCode))
                return
            }
            
            // Did the server return a Last-Modified?
            
            if let lastModifiedString = httpResponse.allHeaderFields["Last-Modified"] as? String
            {
                let formatter = DateFormatter()
                formatter.locale = Locale(identifier:"en_US_POSIX")
                formatter.dateFormat = "EEE',' dd MMM yyyy HH:mm:ss zzz"
                
                if let date = formatter.date(from:lastModifiedString)
                {
                    completionHandler(date,nil)
                    return
                }
            }
            
            completionHandler(nil,nil)
        }
        
        task.resume()
    }


    /// Downloads the contents of a remote URL and saves it to the specified folder.
	
    public func download(to dstFolder:URL? = nil, completionHandler: @escaping (URL?,DownloadError?) -> Void)
    {
        guard !isFileURL else
        {
            completionHandler(self,nil)
            return
        }
        
        let task = URLSession.shared.downloadTask(with:self)
        {
			tempURL,response,error in
			
			// Can we reach the internet?
			
            if let error = error
            {
                completionHandler(nil,.networkError(underlying:error))
                return
            }
            
            // Did we get a response
            
            guard let httpResponse = response as? HTTPURLResponse else
            {
                completionHandler(nil,.invalidResponse)
                return
            }
            
            // Check for server errors
            
            guard (200..<300).contains(httpResponse.statusCode) else
            {
                completionHandler(nil, .httpStatus(code: httpResponse.statusCode))
                return
            }
            
            // Get downloaded file in temp folder
            
            guard let tempURL = tempURL else
            {
                completionHandler(nil,.invalidResponse)
                return
            }
            
            // Move it to the final destination
            
            do
            {
                let dir = dstFolder ?? FileManager.default.temporaryDirectory
                let filename = self.lastPathComponent
                let fileURL = dir.appendingPathComponent(filename)
                
                if !dir.exists
                {
					try? FileManager.default.createDirectory(at:dir, withIntermediateDirectories:true)
				}
				
                try? FileManager.default.removeItem(at:fileURL)
                try FileManager.default.moveItem(at:tempURL, to:fileURL)
                completionHandler(fileURL,nil)
            }
            catch
            {
                completionHandler(nil,.fileMoveFailed(underlying:error))
            }
        }
        task.resume()
    }
}
 
    
//----------------------------------------------------------------------------------------------------------------------


// MARK: - Async Await Support

#if compiler(>=5.5) //&& canImport(_Concurrency)
    
@available(macOS 10.15, iOS 13.0, *) extension URL
{
    /// Checks if the URL is reachable
	
    public func isReachable() async throws -> Bool
    {
        try await withCheckedThrowingContinuation
        {
			continuation in
			
            self.isReachable
            {
				success,error in
				
                if let error = error
                {
                    continuation.resume(throwing:error)
                }
                else
                {
                    continuation.resume(returning:success)
                }
            }
        }
    }


	/// Fetches the modification data of a remote file from the server (if the server supports it)
	
	public func fetchModificationDate() async throws -> Date?
	{
        try await withCheckedThrowingContinuation
        {
			continuation in
			
            self.fetchModificationDate
            {
				date,error in
				
                if let error = error
                {
                    continuation.resume(throwing:error)
                }
                else if let date = date
                {
                    continuation.resume(returning:date)
                }
                else
                {
                    continuation.resume(returning:nil)
                }
            }
        }
    }
    
    
	/// Downloads this URL to the specified folder
	
    public func download(to dstFolder:URL? = nil) async throws -> URL
    {
        try await withCheckedThrowingContinuation
        {
			continuation in
			
            self.download(to:dstFolder)
            {
				fileURL,error in
				
                if let error = error
                {
                    continuation.resume(throwing:error)
                }
                else if let fileURL = fileURL
                {
                    continuation.resume(returning:fileURL)
                }
                else
                {
                    continuation.resume(throwing:DownloadError.invalidResponse)
                }
            }
        }
    }
}
    
#endif


//----------------------------------------------------------------------------------------------------------------------
