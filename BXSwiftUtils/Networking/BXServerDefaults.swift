//**********************************************************************************************************************
//
//  BXServerDefaults.swift
//  A class that loads server hosted defaults and copies them to NSUserDefaults
//  Copyright ©2019 Peter Baumgartner. All rights reserved.
//
//**********************************************************************************************************************


import Foundation


//----------------------------------------------------------------------------------------------------------------------


public class BXServerDefaults
{
	public static let shared = BXServerDefaults()
	
	
	public enum Error : Swift.Error
	{
		case notAvailable
	}
	
	
	/// Loads a plist dictionary from a remote URL and optionally copies its key/value pairs to the local NSUserDefaults

	public func load(from remoteURL:URL, localFallbackURL:URL? = nil, copyToUserDefaults:Bool = true, completionHandler:(([String:Any]?,Swift.Error?)->Void)? = nil)
	{
		// If we were given a localFallbackURL, then first load its contents into the fallbackPlist Dictionary
		
		var fallbackPlist: [String:Any]? = nil
		
		if let url = localFallbackURL
		{
			fallbackPlist = NSDictionary(contentsOf: url) as? [String:Any]
			
			if let plist = fallbackPlist, copyToUserDefaults
			{
				UserDefaults.standard.register(defaults: plist)
			}
		}

		// Then load the contents of remoteURL over the internet
		
		let task = URLSession.shared.dataTask(with: remoteURL)
		{
			(data,_,networkError) in

			DispatchQueue.main.async
			{
				// In case of a networking error, return the error if we don't have a fallbackPlist
				
				if let networkError = networkError
				{
					if fallbackPlist != nil
					{
						completionHandler?(fallbackPlist,nil)
					}
					else
					{
						completionHandler?(nil,networkError)
					}
					return
				}
				
				// If we received some data then convert it to a Dictionary and (optionally) copy it to local UserDefaults
				
				if let data = data
				{
					do
					{
						if let plist = try PropertyListSerialization.propertyList(from:data, options:[], format:nil) as? [String:Any]
						{
							if copyToUserDefaults
							{
								for (key,value) in plist
								{
									UserDefaults.standard.set(value, forKey:key)
								}
							}

							completionHandler?(plist,nil)
							return
						}
					}
					catch let decodeError
					{
						completionHandler?(nil,decodeError)
						return
					}
				}
				
				// Okay, we didn't get anything from the server, so simply return the fallbackPlist Dictionary
				
				if fallbackPlist != nil
				{
					completionHandler?(fallbackPlist,nil)
				}
				else
				{
					completionHandler?(nil, BXServerDefaults.Error.notAvailable)
				}
			}
		}
		
		task.resume()
	}
}


//----------------------------------------------------------------------------------------------------------------------


