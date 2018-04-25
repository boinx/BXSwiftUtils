//**********************************************************************************************************************
//
//  Dictionary+Codable.swift
//	Adds Codable support for [String:Any] dictionaries
//  Copyright ©2018 Peter Baumgartner. All rights reserved.
//
//**********************************************************************************************************************


import Foundation


//----------------------------------------------------------------------------------------------------------------------


// Inspired by https://stackoverflow.com/questions/44603248/how-to-decode-a-property-with-type-of-json-dictionary-in-swift-4-decodable-proto


//----------------------------------------------------------------------------------------------------------------------


fileprivate struct DictionaryCodingKey : CodingKey
{
    var stringValue: String
    var intValue: Int?

    init?(stringValue: String)
    {
        self.stringValue = stringValue
    }

    init?(intValue: Int)
    {
        self.init(stringValue: "\(intValue)")
        self.intValue = intValue
    }
}


//----------------------------------------------------------------------------------------------------------------------


extension KeyedEncodingContainer
{
	/// Encodes a dictionary of type [String:Any]
	
	public mutating func encodeIfPresent(_ value: [String:Any]?, forKey key: Key) throws
	{
		if let value = value
		{
			try self.encode(value, forKey: key)
		}
	}

	/// Encodes a dictionary of type [String:Any]
	
	public mutating func encode(_ value: [String:Any], forKey key: Key) throws
	{
  		var container = self.nestedContainer(keyedBy: DictionaryCodingKey.self, forKey: key)
        try container.encode(value)
	}
	
	/// Encodes a dictionary of type [String:Any]
	
	public mutating func encode(_ dict: [String:Any]) throws
	{
//		for (k,v) in dict
//		{
//			guard let key = DictionaryCodingKey(stringValue:k) else { continue }
//			
//			if let value = v as? Bool
//			{
//				try self.encode(value,forKey:key)
//			}
//			else if let value = v as? Int
//			{
//				try self.encode(value,forKey:key)
//			}
//			else if let value = v as? Float
//			{
//				try self.encode(value,forKey:key)
//			}
//			else if let value = v as? Double
//			{
//				try self.encode(value,forKey:key)
//			}
//			else if let value = v as? String
//			{
//				try self.encode(value,forKey:key)
//			}
//			else if let value = v as? [String:Any]
//			{
//				try self.encode(value,forKey:key)
//			}
//			else if let value = v as? [Any]
//			{
//				try self.encode(value,forKey:key)
//			}
//		}
	}
}


extension UnkeyedEncodingContainer
{
	/// Encodes an array of type [Any]

	public mutating func encode(_ array: [Any]) throws
	{
		for value in array
		{
			if let value = value as? Bool
			{
				try self.encode(value)
			}
			else if let value = value as? Int
			{
				try self.encode(value)
			}
			else if let value = value as? Float
			{
				try self.encode(value)
			}
			else if let value = value as? Double
			{
				try self.encode(value)
			}
			else if let value = value as? String
			{
				try self.encode(value)
			}
			else if let value = value as? Date
			{
				try self.encode(value)
			}
			else if let value = value as? [Any]
			{
				try self.encode(value)
			}
			else if let value = value as? [String:Any]
			{
				try self.encode(value)
			}
		}
	}
	
	/// Encodes a dictionary of type [String:Any]
	
	public mutating func encode(_ dict: [String:Any]) throws
	{
        var nestedContainer = self.nestedContainer(keyedBy: DictionaryCodingKey.self)
        return try nestedContainer.encode(dict)
    }
}


//----------------------------------------------------------------------------------------------------------------------


extension KeyedDecodingContainer
{
	/// Decodes a dictionary of type [String:Any]
	
	public func decodeIfPresent(_ type: [String:Any].Type, forKey key: Key) throws -> [String:Any]?
	{
        guard self.contains(key) else {  return nil }
        guard try self.decodeNil(forKey: key) == false else { return nil }
        return try self.decode(type, forKey: key)
	}
	
	/// Decodes a dictionary of type [String:Any]
	
	public func decode(_ type: [String:Any].Type, forKey key: Key) throws -> [String:Any]
	{
  		let container = try self.nestedContainer(keyedBy: DictionaryCodingKey.self, forKey: key)
        return try container.decode(type)
	}
	
	/// Decodes a dictionary of type [String:Any]
	
	public func decode(_ type: [String:Any].Type) throws -> [String:Any]
	{
		var dictionary:[String:Any] = [:]

		for key in self.allKeys
		{
			if let value = try? decode(Bool.self,forKey:key)
			{
				dictionary[key.stringValue] = value
			}
			else if let value = try? decode(Int.self, forKey: key)
			{
				dictionary[key.stringValue] = value
			}
			else if let value = try? decode(Float.self, forKey: key)
			{
				dictionary[key.stringValue] = value
			}
			else if let value = try? decode(Double.self, forKey: key)
			{
				dictionary[key.stringValue] = value
			}
			else if let value = try? decode(String.self, forKey: key)
			{
				dictionary[key.stringValue] = value
			}
			else if let value = try? decode([String:Any].self, forKey: key)
			{
				dictionary[key.stringValue] = value
			}
			else if let value = try? decode([Any].self, forKey: key)
			{
				dictionary[key.stringValue] = value
			}
		}
		
		return dictionary
	}

	/// Decodes an array of type [Any]
	
	public func decodeIfPresent(_ type: [Any].Type, forKey key: Key) throws -> [Any]?
	{
        guard contains(key) else { return nil }
        guard try decodeNil(forKey: key) == false else { return nil }
        return try decode(type, forKey: key)
    }

	/// Decodes an array of type [Any]
	
	public func decode(_ type: [Any].Type, forKey key: Key) throws -> [Any]
	{
        var container = try self.nestedUnkeyedContainer(forKey: key)
        return try container.decode(type)
    }

}


//----------------------------------------------------------------------------------------------------------------------


extension UnkeyedDecodingContainer
{
	/// Decodes an array of type [Any]

	public mutating func decode(_ type: [Any].Type) throws -> [Any]
	{
		var array:[Any] = []

		while !self.isAtEnd
		{
			if try decodeNil()
			{
                continue
            }
			if let value = try? decode(Bool.self)
			{
				array += value
			}
			else if let value = try? decode(Int.self)
			{
				array += value
			}
			else if let value = try? decode(Float.self)
			{
				array += value
			}
			else if let value = try? decode(Double.self)
			{
				array += value
			}
			else if let value = try? decode(String.self)
			{
				array += value
			}
			else if let value = try? decode([String:Any].self)
			{
				array += value
			}
			else if let value = try? decode([Any].self)
			{
				array += value
			}
		}
		
		return array
	}
	
	/// Decodes a dictionary of type [String:Any]
	
	public mutating func decode(_ type: [String:Any].Type) throws -> [String:Any]
	{
        let nestedContainer = try self.nestedContainer(keyedBy: DictionaryCodingKey.self)
        return try nestedContainer.decode(type)
    }
}


//----------------------------------------------------------------------------------------------------------------------

