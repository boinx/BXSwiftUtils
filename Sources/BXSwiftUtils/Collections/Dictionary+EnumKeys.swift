//
//  Dictionary+EnumKeys.swift
//  BXSwiftUtils
//
//  Created by Stefan Fochler on 18.04.18.
//  Copyright © 2018 Boinx Software Ltd. & Imagine GbR. All rights reserved.
//

import Foundation

/**
 Extension for dictionaries that allows values of string enums to be used as keys without appending `.rawValue` to
 obtain an actual string.
 
 NOTE: This only works when both the dictionary's key type and the enum raw value are strings. In all other cases, the
 enum value will be used as key, which is usually not desired.
 */
extension Dictionary
{
    public subscript<EnumKey: RawRepresentable>(key: EnumKey) -> Value?
    where EnumKey.RawValue == Dictionary.Key
    {
        get
        {
            return self[key.rawValue]
        }
        set
        {
            self[key.rawValue] = newValue
        }
    }

    /**
     Allows `closure` to modify a (proxy) dictionary that uses `keySpace` as its key type.
     
     The proxy dictionary will contain all entries from the real dictionary whose keys fit into `keySpace`.
     After `closure` has completed, all values will be copied back from the proxy dictionary into the real dictionary.
     
     - parameter keySpace: The enum which will be used as keyspace. Its `RawValue` must match the dictionary's key type.
     - parameter closure: Closure that will be given the mutable proxy dictionary.
     - parameter dict: The mutable proxy dictionary keyed by `KeySpace`.
     */
    public mutating func using<KeySpace: RawRepresentable>(_ keySpace: KeySpace.Type, closure: (_ dict: inout [KeySpace: Value]) -> Void)
    where KeySpace.RawValue == Key
    {
        var proxy = [KeySpace: Value]()
        
        for (key, value) in self
        {
            if let enumKey = KeySpace(rawValue: key)
            {
                proxy[enumKey] = value
            }
        }
        
        closure(&proxy)
        
        for (key, value) in proxy
        {
            self[key.rawValue] = value
        }
    }
}
