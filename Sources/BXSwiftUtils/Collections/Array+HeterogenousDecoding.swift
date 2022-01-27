//**********************************************************************************************************************
//
//  Array+HeterogenousDecoding.swift
//	Decodes a heterogenous Array from a Data object
//  Copyright ©2020 Peter Baumgartner. All rights reserved.
//
//**********************************************************************************************************************


import Foundation
import CoreGraphics


// Decoding a Data object to a heterogenous Array is not trivial. The following article provides an overview:

// https://medium.com/@kewindannerfjordremeczki/swift-4-0-decodable-heterogeneous-collections-ecc0e6b468cf


//----------------------------------------------------------------------------------------------------------------------


/// To support a new class family, create an enum that conforms to this protocol and contains the different types.

public protocol BXHeterogenousArrayFamily : Decodable
{
    /// The class name key
    
    static var classNameKey:BXClassNameKey { get }

    /// Returns the class type of the object coresponding to the value
    
    func getType() -> AnyObject.Type
}


/// Class name key enum used to retrieve discriminator fields in JSON payloads

public enum BXClassNameKey : String, CodingKey
{
    case className = "className"
 	case subclass = "subclass"
	case `class` = "class"
    case type = "type"
}


//----------------------------------------------------------------------------------------------------------------------


public class ClassWrapper<C:BXHeterogenousArrayFamily,T:Decodable> : Decodable
{
    /// The family enum containing the class information
    
    let family:C
    
    /// The decoded object. Can be any subclass of T
    
    let object:T?

	/// Create the helper wrapper
	
	required public init(from decoder:Decoder) throws
    {
        let container = try decoder.container(keyedBy:BXClassNameKey.self)
        
        // Decode the family
        
        self.family = try container.decode(C.self, forKey:C.classNameKey)
        
        // Decode the object by initialising the corresponding type
        
        if let type = family.getType() as? T.Type
        {
            self.object = try type.init(from:decoder)
        }
        else
        {
            self.object = nil
        }
    }
}

//----------------------------------------------------------------------------------------------------------------------


public extension PropertyListDecoder
{
    /// Decode a heterogeneous list of objects
    /// - parameter family: The ClassFamily enum type to decode with
    /// - parameter data: The data to decode
    /// - Returns: The list of decoded objects
    
    func decode<C:BXHeterogenousArrayFamily,T:Decodable>(family:C.Type, from data:Data) throws -> [T]
    {
        return try self.decode([ClassWrapper<C,T>].self, from:data).compactMap { $0.object }
    }
}


public extension JSONDecoder
{
    /// Decode a heterogeneous list of objects
    /// - parameter family: The ClassFamily enum type to decode with
    /// - parameter data: The data to decode
    /// - Returns: The list of decoded objects
    
    func decode<C:BXHeterogenousArrayFamily,T:Decodable>(family:C.Type, from data:Data) throws -> [T]
    {
        return try self.decode([ClassWrapper<C,T>].self, from:data).compactMap { $0.object }
    }
}


//----------------------------------------------------------------------------------------------------------------------

