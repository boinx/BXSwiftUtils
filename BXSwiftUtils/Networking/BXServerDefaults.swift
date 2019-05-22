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
	/// Shared singlton instance of this class
	
	public static let shared = BXServerDefaults()
	
	/// Custom errors
	
	public enum Error : Swift.Error
	{
		case notAvailable
	}
	
	
//----------------------------------------------------------------------------------------------------------------------


	/// Loads a plist from a remote URL and optionally copies its key/value pairs to the local NSUserDefaults
	///
	/// Example Code:
	///
	///	    let remoteURL = URL(string:"https://www.boinx.com/fotomagico/inapp/ipad/com.boinx.FotoMagico6.iOS.plist")!
	///	    let localURL = Bundle.main.url(forResource:"com.boinx.FotoMagico6.iOS.plist", withExtension:nil)
	///	    BXServerDefaults.shared.load(from:remoteURL, localFallbackURL:localURL, copyToUserDefaults:true)
	///
	/// - parameter remoteURL: The URL of the plist file that is hosted on the server
	/// - parameter localFallbackURL: The URL of the fallback plist file that resides in the app bundle
	/// - parameter copyToUserDefaults: Set to true if the contents of the plist should be copied to the local NSUserDefaults
	/// - parameter completionHandler: An optional completion handler that returns the resulting plist

	public func load(from remoteURL:URL, localFallbackURL:URL? = nil, copyToUserDefaults:Bool = true, completionHandler:((Any?,Swift.Error?)->Void)? = nil)
	{
		// If we were given a localFallbackURL, then first load its contents into the fallbackPlist
		
		var fallbackPlist: Any? = nil
		
		if let url = localFallbackURL,
		   let data = try? Data(contentsOf: url),
		   let plist = try? PropertyListSerialization.propertyList(from:data, format:nil)
		{
			fallbackPlist = plist

			if let dict = fallbackPlist as? [String:Any], copyToUserDefaults
			{
				UserDefaults.standard.register(defaults: dict)
			}
		}

		// Then load the contents of remoteURL over the internet
		
		let task = URLSession.shared.dataTask(with: remoteURL)
		{
			(data,response,networkError) in

			DispatchQueue.main.async
			{
				// In case of a networking error, return the error if we don't have a fallbackPlist
				
				if let networkError = networkError
				{
					if fallbackPlist != nil
					{
						completionHandler?(fallbackPlist,nil)
						return
					}
					else
					{
						completionHandler?(nil,networkError)
						return
					}
				}
				
				// If the resource at the remote URL doesn't exist, then return the fallbackPlist instead
				
				if let response = response as? HTTPURLResponse, response.statusCode == 404
				{
					if fallbackPlist != nil
					{
						completionHandler?(fallbackPlist,nil)
						return
					}
					else
					{
						completionHandler?(nil, BXServerDefaults.Error.notAvailable)
						return
					}
				}
				
				// If we received some data then convert it to a Dictionary and (optionally) copy it to local UserDefaults
				
				if let data = data
				{
					do
					{
						let plist = try PropertyListSerialization.propertyList(from:data, options:[], format:nil)
						
						if let dict = plist as? [String:Any], copyToUserDefaults
						{
							for (key,value) in dict
							{
								UserDefaults.standard.set(value, forKey:key)
							}
						}

						completionHandler?(plist,nil)
						return
					}
					catch let decodeError
					{
						completionHandler?(nil,decodeError)
						return
					}
				}
				
				// Okay, we didn't get anything from the server, so simply return the fallbackPlist
				
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


//----------------------------------------------------------------------------------------------------------------------


}
