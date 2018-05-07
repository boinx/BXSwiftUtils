//
//  Collection+Flatten.swift
//  BXSwiftUtils
//
//  Created by Stefan Fochler on 07.05.18.
//  Copyright © 2018 Boinx Software Ltd. & Imagine GbR. All rights reserved.
//

import Foundation

extension Collection where Element: Collection
{
    /**
     Method on collections of collections that allows flattening one level of nesting.
     */
    public func flatten() -> [Element.Element]
    {
        return self.reduce([], +)
    }
}
