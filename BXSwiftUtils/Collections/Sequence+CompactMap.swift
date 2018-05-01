//
//  Sequence+CompactMap.swift
//  BXSwiftUtils
//
//  Created by Stefan Fochler on 01.05.18.
//  Copyright © 2018 Boinx Software Ltd. & Imagine GbR. All rights reserved.
//

import Foundation

extension Sequence where Element
{
    #if !swift(>=4.1)
    public func compactMap<ResultType>(_ transform: (Element) throws -> ResultType?) rethrows -> [ResultType]
    {
        return try flatMap(transform)
    }
    #endif
}
