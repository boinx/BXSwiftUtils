//**********************************************************************************************************************
//
//  BXLogger+File.swift
//	File destination for BXLogger
//  Copyright ©2019 Peter Baumgartner. All rights reserved.
//
//**********************************************************************************************************************


#if os(iOS)
import UIKit
#elseif os(macOS)
import Foundation
#endif


//----------------------------------------------------------------------------------------------------------------------


extension BXLogger
{
	struct LogFile
	{
		var url:URL? = nil
		var handle:FileHandle? = nil
	}
	
	private static var logFile = LogFile()
	

//----------------------------------------------------------------------------------------------------------------------


	/// Discards the oldest lines in the logfile if it exceeds the specified maximum size
	
	public static func truncateLogFile(at url:URL, toMaxSize maxSize:Int) throws
	{
		if let text = try? String(contentsOf:url, encoding:.utf8), text.count > maxSize
		{
			let newText = String(text.suffix(maxSize))
			try newText.write(to:url, atomically:true, encoding:.utf8)
		}
	}
	
	/// Opens the logfile for writing
	
	public static func openLogFile(at url:URL) throws
	{
		do
		{
			if !url.exists
			{
				FileManager.default.createFile(atPath:url.path, contents:Data(), attributes:nil)
			}
			
			self.logFile.url = url
			self.logFile.handle = try FileHandle(forWritingTo:url)
			self.logFile.handle?.seekToEndOfFile()
		}
		catch let error
		{
			self.logFile.url = nil
			self.logFile.handle = nil
			throw error
		}
	}
	
	/// Appends the message to the end of the log file
	
	public static func fileDestination(level:Level, message:String)
	{
		if let data = message.data(using:.utf8)
		{
			self.logFile.handle?.write(data)
		}
	}

	/// Closes the logfile
	
	public static func closeLogFile()
	{
		self.logFile.handle?.closeFile()
		self.logFile.handle = nil
		self.logFile.url = nil
	}
	

//----------------------------------------------------------------------------------------------------------------------


	/// Sends the logfile to the specified email address
	
	public static func sendLogFile(at fileURL:URL, subject:String, to emailAddress:String) throws
	{
		if #available(iOS 13,*)
		{
			try self.logFile.handle?.synchronize()
		}
		else
		{
			self.logFile.handle?.synchronizeFile()
		}
		
		if fileURL.exists, let body = try? String(contentsOf:fileURL, encoding:.utf8)
		{
			let mailto = String(format:"mailto:%@?Subject=\"%@\"&body=\"%@\"", emailAddress, subject, body)
			
			if let mailtoURL = URL(string:mailto)
			{
				#if os(iOS)
				UIApplication.shared.open(mailtoURL, options:[:], completionHandler:nil)
				#elseif os(macOS)
				NSWorkspace.shared.open(url:mailtoURL)
				#endif
			}
		}
	}
}


//----------------------------------------------------------------------------------------------------------------------
