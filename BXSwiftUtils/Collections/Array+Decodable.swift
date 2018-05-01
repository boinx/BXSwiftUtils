//
//  Array+Concatenation.swift
//  BXSwiftUtils
//
//  Created by Stefan Fochler & Peter Baumgartner on 24.04.18.
//  Copyright © 2018 Boinx Software Ltd. All rights reserved.
//

import Foundation


extension KeyedDecodingContainer
{
	/// This method decodes a heterogeneous array of T. Since the array can contain arbitrary subclass instances
	/// of T, the objectTypeMapper closure is used to determine the exact subclass type of each element in the array.
    
    @available(swift 4.1)
	public func decodeHeterogeneousArray<T: Decodable>(forKey key: Key, objectTypeMapper: (Decoder) throws -> T.Type) throws -> [T]
	{
		var arrayContainer = try self.nestedUnkeyedContainer(forKey:key)

		// Since this array can contain subclasses of T, we first have to determine the exact type of each element.

		var classTypes = [T.Type]()
		
        while !arrayContainer.isAtEnd
        {
        	let itemDecoder = try arrayContainer.superDecoder()
            classTypes += try objectTypeMapper(itemDecoder)
 		}
		
		// Once the complete list of classTypes (in the correct order) is known, get arrayContainer again so that
		// we can iterate it from the beginning. Then decode each object with its correct subclass type.
		
		arrayContainer = try self.nestedUnkeyedContainer(forKey:key)

        return try classTypes.map
        {
        	type in
            return try arrayContainer.decode(type)
        }
	}
    
}
