//**********************************************************************************************************************
//
//  NSAttributedString+Codable.swift
//  Adds codable support
//  Copyright ©2018-2025 Peter Baumgartner. All rights reserved.
//
//**********************************************************************************************************************


import Foundation

#if os(macOS)
import AppKit
#else
import UIKit
#endif


//----------------------------------------------------------------------------------------------------------------------


extension NSAttributedString
{
    public var data:Data
    {
        (try? NSKeyedArchiver.archivedData(withRootObject:self, requiringSecureCoding:false)) ?? Data()
    }
}

extension Foundation.NSAttributedString : Swift.Encodable
{
    public func encode(to encoder: Encoder) throws
    {
        var container = encoder.singleValueContainer()
        let data = try NSKeyedArchiver.archivedData(withRootObject:self, requiringSecureCoding:false)
        try container.encode(data)
    }
}

/*
 It's impossible to make NSAttributedString `Decodable`, because the required initializer cannot be defined in an
 extension.
 However, it is possible to patch the KeyedDecodingContainer to decode NSAttributedString as if it was.
 */
extension KeyedDecodingContainer
{
    public func decode(_ type: NSAttributedString.Type, forKey key: Key) throws -> NSAttributedString
    {
        let decoder = try self.superDecoder(forKey: key)
        let container = try decoder.singleValueContainer()
        let data = try container.decode(Data.self)

		#if os(macOS)
		let result = try NSKeyedUnarchiver.unarchivedObject(ofClasses:[NSAttributedString.self,NSDictionary.self,NSArray.self,NSString.self,NSNumber.self,NSColor.self,NSFont.self,NSParagraphStyle.self], from:data)
		#else
		let result = try NSKeyedUnarchiver.unarchivedObject(ofClasses:[NSAttributedString.self,NSDictionary.self,NSArray.self,NSString.self,NSNumber.self,UIColor.self,UIFont.self,NSParagraphStyle.self], from:data)
		#endif

        guard let str = result as? NSAttributedString else
        {
            throw DecodingError.typeMismatch(NSAttributedString.self,
				DecodingError.Context(
					codingPath: decoder.codingPath,
					debugDescription: "Expected NSAttributedString but found \(String(describing:result))"
				))
        }
        return str
    }
    
    public func decodeIfPresent(_ type: NSAttributedString.Type, forKey key: Key) throws -> NSAttributedString?
    {
        guard self.contains(key) else { return nil }
        
        return try self.decode(type, forKey: key)
    }
}


//----------------------------------------------------------------------------------------------------------------------


extension NSAttributedString
{
	/// Returns an array of all font names that are used in the archivedData created from an NSAttributedString.
	///
	/// Simply unarchiving an NSAttributedString and then enumerating its font attribute doesn't work, because
	/// at this point the OS has already replaced missing fonts with a default font, and all information which
	/// fonts are missing has been lost. For this reason this custom function parses the archivedData and extracts
	/// the relevant information.
	
	public class func usedFontNames(inArchivedData data:Data) -> [String]
	{
		var usedFontNames:[String] = []
		
		// The following code was developed by reverse engineering a plist read in from archived data:
		
		// First convert the archivedData to a property list
		
		var format = PropertyListSerialization.PropertyListFormat.binary

		if let info = try? PropertyListSerialization.propertyList(
			from:data,
			options:[],
			format:&format)
		{
			// Top level should be a dictionary
			
			if let dict = info as? [String:Any]
			{
				// Look for the $objects array
				
				if let objects = dict["$objects"] as? [Any]
				{
					// The second entry should be a dictionary with keys "NSString" and "NSAttributes"
					
					if let object1 = objects[1] as? [String:Any]
					{
						if object1.keys.contains("NSString") && object1.keys.contains("NSAttributes")
						{
							// We are interested in "NSAttributes"
							
							if let attributesDict = self.object(forCFKeyedArchiverUID:object1["NSAttributes"], from:objects) as? [AnyHashable:Any]
							{
								let keyAndObjectsList = self.keyAndObjectsList(from:attributesDict, objects:objects)
								
								for keyAndObjects in keyAndObjectsList
								{
									if let ns_keys = keyAndObjects["NS.keys"] as? [Any],
									   let ns_objects = keyAndObjects["NS.objects"] as? [Any]
									{
										// Find the correct index i for the "NSFont" entry
										
										for i in 0 ..< ns_keys.count
										{
											if let j = self.value(forCFKeyedArchiverUID:ns_keys[i]),
											   let str = objects[j] as? String,
											   str == "NSFont"
											{
												// Get the dictionary containing font info and follow to the "NSName" entry
												
												if let fontDict = self.object(forCFKeyedArchiverUID:ns_objects[i], from:objects) as? [String:Any],
												   let name = self.object(forCFKeyedArchiverUID:fontDict["NSName"], from:objects) as? String
												{
													usedFontNames += name
												}
											}
										}
									}
								}
							}
						}
					}
				}
			}
		}

		return usedFontNames
	}
	
	
	/// Extracts the "NS.keys" and "NS.objects" arrays from objects
	
	private class func keyAndObjectsList(from attributesDict:[AnyHashable:Any], objects:[Any]) -> [[String:Any]]
	{
		guard let attributesDict = attributesDict as? [String:Any] else { return [] }
		
		if let classDict = self.object(forCFKeyedArchiverUID:attributesDict["$class"], from:objects) as? [AnyHashable:Any],
		   let classname = classDict["$classname"] as? String
		{
			if classname.contains("Dictionary"),
			   let _ = attributesDict["NS.keys"] as? [Any],
			   let _ = attributesDict["NS.objects"] as? [Any]
			{
				return [attributesDict]
			}
			else if classname.contains("Array"),
			   let ns_objects = attributesDict["NS.objects"] as? [Any]
			{
				var dicts:[[String:Any]] = []
				
				for uid in ns_objects
				{
					if let dict = self.object(forCFKeyedArchiverUID: uid, from:objects) as? [String:Any]
					{
						dicts += dict
					}
				}
				
				return dicts
			}
		}
		
		return []
	}
	
	
	/// Helper function that extracts the int value from the Apple private struct CFKeyedArchiverUID
	
	private class func value(forCFKeyedArchiverUID uid:Any?) -> Int?
	{
		guard let uid = uid else { return nil }
		
		let string = "\(uid)"

		if let regex = try? NSRegularExpression(pattern:"<.+>\\{value = (.+)\\}",options:.caseInsensitive)
		{
			let match = regex.firstMatch(in:string, options:[], range:NSMakeRange(0,string.count))

			if let match = match, match.numberOfRanges > 0
			{
				let range = match.range(at:1)

				if range.location != NSNotFound, let r = Range(range,in:string)
				{
					let valueString = String(string[r])
					return Int(valueString)
				}
			}
		}

		return nil
	}


	/// Helper function that returns the object specified by the CFKeyedArchiverUID
	
	private class func object(forCFKeyedArchiverUID uid:Any?, from objects:[Any]) -> Any?
	{
		guard let uid = uid else { return nil }

		if let index = self.value(forCFKeyedArchiverUID:uid)
		{
			return objects[index]
		}
		
		return nil
	}

}


//----------------------------------------------------------------------------------------------------------------------

extension NSAttributedString
{
	/// Returns an array of all font names that are used in the RTFD data.
	///
	/// Simply creating an NSAttributedString and then enumerating its font attribute doesn't work, because
	/// at this point the OS has already replaced missing fonts with a default font, and all information which
	/// fonts are missing has been lost. For this reason this custom function parses the RTFD data and extracts
	/// the relevant information.
	
	public class func usedFontNames(inRTFData data:Data) -> [String]
	{
		// {\fonttbl\f0\fnil\fcharset0 LithosPro-Regular;}

		var strings:[String] = []
		
		guard let string = String(bytes:data, encoding:.ascii) else { return strings }
		guard let regex = try? NSRegularExpression(pattern:"fonttbl.* +(.*);",options:[]) else { return strings }
		let matches = regex.matches(in:string, options:[], range:NSMakeRange(0,string.count))
		
		for match in matches
		{
			if match.numberOfRanges >= 2
			{
				let range = match.range(at:1)

				if range.location != NSNotFound, let r = Range(range,in:string)
				{
					let str = String(string[r])
					strings += str
				}
			}
		}
		
		return strings
	}
}

	
//----------------------------------------------------------------------------------------------------------------------
