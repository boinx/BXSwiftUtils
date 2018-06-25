//
//  TypedKVO+propagateChanges.swift
//  BXSwiftUtils
//
//  Created by Stefan Fochler on 25.06.18.
//  Copyright © 2018 Boinx Software Ltd. & Imagine GbR. All rights reserved.
//

import Foundation

extension TypedKVO
{
    public static func propagateChanges<Target, TargetValue>(from origin: Root, _ fromKeyPath: KeyPath<Root, Value>, to target: Target, _ toKeyPath: KeyPath<Target, TargetValue>, asyncOn queue: DispatchQueue? = nil) -> TypedKVO where Target: NSObject
    {
        let notify = { [weak target] in
            target?.willChangeValue(for: toKeyPath)
            target?.didChangeValue(for: toKeyPath)
        }
    
        return TypedKVO(origin, fromKeyPath, options: [])
        { [weak queue] (_, _) in
            if let queue = queue
            {
                queue.async(execute: notify)
            }
            else
            {
                notify()
            }
        }
    }
}
