//**********************************************************************************************************************
//
//  NSAttributedString+Codable.swift
//    Adds codable support
//  Copyright ©2018 Peter Baumgartner. All rights reserved.
//
//**********************************************************************************************************************


import Foundation


//----------------------------------------------------------------------------------------------------------------------


extension NSAttributedString
{
    public var data:Data
    {
        return NSKeyedArchiver.archivedData(withRootObject: self)
    }
}

extension NSAttributedString: Encodable
{
    public func encode(to encoder: Encoder) throws
    {
        var container = encoder.singleValueContainer()
        try container.encode(self.data)
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
        
        let result = NSKeyedUnarchiver.unarchiveObject(with: data)
        guard let str = result as? NSAttributedString else
        {
            throw DecodingError.typeMismatch(NSAttributedString.self, DecodingError.Context(
                codingPath: decoder.codingPath,
                debugDescription: "Expected NSAttributedString but found \(String(describing: result))"
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
