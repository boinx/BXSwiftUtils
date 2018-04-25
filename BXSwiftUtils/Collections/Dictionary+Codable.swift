//**********************************************************************************************************************
//
//  Dictionary+Codable.swift
//	Adds Codable support for [String:Any] dictionaries
//  Copyright ©2018 Peter Baumgartner. All rights reserved.
//
//**********************************************************************************************************************


// The type Dictionary<String,Any> is not Codable by default, because Any does not conform to the Codable protocol.
// The following extensions add Codable support for [String:Any] and [Any], so that arbitrary dictionary and arrays
// can be encoded and decoded.

// Inspired by https://stackoverflow.com/questions/44603248/how-to-decode-a-property-with-type-of-json-dictionary-in-swift-4-decodable-proto
// and https://stackoverflow.com/questions/47575309/how-to-encode-a-property-with-type-of-json-dictionary-in-swift-4-encodable-proto


//----------------------------------------------------------------------------------------------------------------------


import Foundation


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


// MARK: -

extension KeyedEncodingContainer
{

	/// Encodes a dictionary of type [String:Any]
	
	public mutating func encode(_ dict: [String:Any], forKey key: Key) throws
	{
  		var container = self.nestedContainer(keyedBy: DictionaryCodingKey.self, forKey: key)

		for (k,v) in dict
		{
			guard let key = DictionaryCodingKey(stringValue:k) else { continue }
			
			if let value = v as? Double
			{
				try container.encode(value, forKey: key)
			}
			else if let value = v as? Float
			{
				try container.encode(value, forKey: key)
			}
			else if let value = v as? Int
			{
				try container.encode(value, forKey: key)
			}
			else if let value = v as? Bool
			{
				try container.encode(value, forKey: key)
			}
			else if let value = v as? Date
			{
				try container.encode(value, forKey: key)
			}
			else if let value = v as? String
			{
				try container.encode(value, forKey: key)
			}
			else if let value = v as? [Any]
			{
				try container.encode(value, forKey: key)
			}
			else if let value = v as? [String:Any]
			{
				try container.encode(value, forKey: key)
			}
		}
	}


	/// Encodes an array of type [Any]

	public mutating func encode(_ array: [Any], forKey key: Key) throws
	{
  		var container = self.nestedUnkeyedContainer(forKey: key)

		for v in array
		{
			if let value = v as? Double
			{
				try container.encode(value)
			}
			else if let value = v as? Float
			{
				try container.encode(value)
			}
			else if let value = v as? Int
			{
				try container.encode(value)
			}
			else if let value = v as? Bool
			{
				try container.encode(value)
			}
			else if let value = v as? Date
			{
				try container.encode(value)
			}
			else if let value = v as? String
			{
				try container.encode(value)
			}
			else if let value = v as? [Any]
			{
				try container.encode(value)
			}
			else if let value = v as? [String:Any]
			{
				try container.encode(value)
			}
		}
	}
	
	
	/// Encodes a dictionary of type [String:Any]
	
	public mutating func encodeIfPresent(_ value: [String:Any]?, forKey key: Key) throws
	{
		if let value = value
		{
			try self.encode(value, forKey: key)
		}
	}


	/// Encodes an array of type [Any]
	
	public mutating func encodeIfPresent(_ value: [Any]?, forKey key: Key) throws
	{
		if let value = value
		{
			try self.encode(value, forKey: key)
		}
	}

}


//----------------------------------------------------------------------------------------------------------------------


// MARK: -

extension UnkeyedEncodingContainer
{

	/// Encodes an array of type [Any]

	public mutating func encode(_ array: [Any]) throws
	{
 		var container = self.nestedUnkeyedContainer()

		for value in array
		{
			if let value = value as? Double
			{
				try container.encode(value)
			}
			else if let value = value as? Float
			{
				try container.encode(value)
			}
			else if let value = value as? Int
			{
				try container.encode(value)
			}
			else if let value = value as? Bool
			{
				try container.encode(value)
			}
			else if let value = value as? Date
			{
				try container.encode(value)
			}
			else if let value = value as? String
			{
				try container.encode(value)
			}
			else if let value = value as? [Any]
			{
				try container.encode(value)
			}
			else if let value = value as? [String:Any]
			{
				try container.encode(value)
			}
		}
	}
	
	
	/// Encodes a dictionary of type [String:Any]
	
	public mutating func encode(_ dict: [String:Any]) throws
	{
        var container = self.nestedContainer(keyedBy: DictionaryCodingKey.self)
		
		for (k,v) in dict
		{
			guard let key = DictionaryCodingKey(stringValue:k) else { continue }
			
			if let value = v as? Double
			{
				try container.encode(value, forKey: key)
			}
			else if let value = v as? Float
			{
				try container.encode(value, forKey: key)
			}
			else if let value = v as? Int
			{
				try container.encode(value, forKey: key)
			}
			else if let value = v as? Bool
			{
				try container.encode(value, forKey: key)
			}
			else if let value = v as? Date
			{
				try container.encode(value, forKey: key)
			}
			else if let value = v as? String
			{
				try container.encode(value, forKey: key)
			}
			else if let value = v as? [Any]
			{
				try container.encode(value, forKey: key)
			}
			else if let value = v as? [String:Any]
			{
				try container.encode(value, forKey: key)
			}
		}
    }
	/// Encodes an array of type [Any]

	public mutating func encodeIfPresent(_ array: [Any]?) throws
	{
		if let array = array
		{
			try self.encode(array)
		}
	}
	
	
	/// Encodes a dictionary of type [String:Any]
	
	public mutating func encodeIfPresent(_ dict: [String:Any]?) throws
	{
		if let dict = dict
		{
			try self.encode(dict)
		}
	}
	
}


//----------------------------------------------------------------------------------------------------------------------


// MARK: -

extension KeyedDecodingContainer
{

	/// Decodes a dictionary of type [String:Any]
	
	public func decode(_ type: [String:Any].Type, forKey key: Key) throws -> [String:Any]
	{
  		let container = try self.nestedContainer(keyedBy: DictionaryCodingKey.self, forKey: key)
		var dictionary:[String:Any] = [:]

		for k in container.allKeys
		{
			if let value = try? container.decode(Double.self, forKey: k)
			{
				dictionary[k.stringValue] = value
			}
			else if let value = try? container.decode(Float.self, forKey: k)
			{
				dictionary[k.stringValue] = value
			}
			else if let value = try? container.decode(Int.self, forKey: k)
			{
				dictionary[k.stringValue] = value
			}
			else if let value = try? container.decode(Bool.self,forKey:k)
			{
				dictionary[k.stringValue] = value
			}
			else if let value = try? container.decode(Date.self, forKey: k)
			{
				dictionary[k.stringValue] = value
			}
			else if let value = try? container.decode(String.self, forKey: k)
			{
				dictionary[k.stringValue] = value
			}
			else if let value = try? container.decode([Any].self, forKey: k)
			{
				dictionary[k.stringValue] = value
			}
			else if let value = try? container.decode([String:Any].self, forKey: k)
			{
				dictionary[k.stringValue] = value
			}
		}
		
		return dictionary
	}


	/// Decodes an array of type [Any]
	
	public func decode(_ type: [Any].Type, forKey key: Key) throws -> [Any]
	{
        var container = try self.nestedUnkeyedContainer(forKey: key)
        return try container.decode(type)
    }


	/// Decodes a dictionary of type [String:Any]
	
	public func decodeIfPresent(_ type: [String:Any].Type, forKey key: Key) throws -> [String:Any]?
	{
        guard self.contains(key) else {  return nil }
        guard try self.decodeNil(forKey: key) == false else { return nil }
        return try self.decode(type, forKey: key)
	}
	
	
	/// Decodes an array of type [Any]
	
	public func decodeIfPresent(_ type: [Any].Type, forKey key: Key) throws -> [Any]?
	{
        guard contains(key) else { return nil }
        guard try decodeNil(forKey: key) == false else { return nil }
        return try decode(type, forKey: key)
    }


}


//----------------------------------------------------------------------------------------------------------------------


// MARK: -

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
			else if let value = try? decode(Double.self)
			{
				array += value
			}
			else if let value = try? decode(Float.self)
			{
				array += value
			}
			else if let value = try? decode(Int.self)
			{
				array += value
			}
			else if let value = try? decode(Bool.self)
			{
				array += value
			}
			else if let value = try? decode(Date.self)
			{
				array += value
			}
			else if let value = try? decode(String.self)
			{
				array += value
			}
			else if let value = try? decode([Any].self)
			{
				array += value
			}
			else if let value = try? decode([String:Any].self)
			{
				array += value
			}
		}
		
		return array
	}
	
	
	/// Decodes a dictionary of type [String:Any]
	
	public mutating func decode(_ type: [String:Any].Type) throws -> [String:Any]
	{
        let container = try self.nestedContainer(keyedBy: DictionaryCodingKey.self)
		var dictionary:[String:Any] = [:]

		for k in container.allKeys
		{
			if let value = try? container.decode(Double.self, forKey: k)
			{
				dictionary[k.stringValue] = value
			}
			else if let value = try? container.decode(Float.self, forKey: k)
			{
				dictionary[k.stringValue] = value
			}
			else if let value = try? container.decode(Int.self, forKey: k)
			{
				dictionary[k.stringValue] = value
			}
			else if let value = try? container.decode(Bool.self,forKey:k)
			{
				dictionary[k.stringValue] = value
			}
			else if let value = try? container.decode(Date.self, forKey: k)
			{
				dictionary[k.stringValue] = value
			}
			else if let value = try? container.decode(String.self, forKey: k)
			{
				dictionary[k.stringValue] = value
			}
			else if let value = try? container.decode([Any].self, forKey: k)
			{
				dictionary[k.stringValue] = value
			}
			else if let value = try? container.decode([String:Any].self, forKey: k)
			{
				dictionary[k.stringValue] = value
			}
		}
		
		return dictionary
    }


	/// Decodes an array of type [Any]

	public mutating func decodeIfPresent(_ type: [Any].Type) throws -> [Any]?
	{
		return try? self.decode(type)
	}
	
	
	/// Decodes an array of type [Any]

	public mutating func decodeIfPresent(_ type: [String:Any].Type) throws -> [String:Any]?
	{
		return try? self.decode(type)
	}
	
}


//----------------------------------------------------------------------------------------------------------------------

