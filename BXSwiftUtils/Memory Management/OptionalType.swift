//
//  OptionalType.swift
//  BXSwiftUtils
//
//  Created by Stefan Fochler on 28.09.18.
//  Copyright © 2018 Boinx Software Ltd. & Imagine GbR. All rights reserved.
//

import Foundation

// Allow type inheritance of Swift.Optional through custom protocol
public protocol OptionalType {
    associatedtype Wrapped
    
    init(_: Wrapped)
}

extension Optional: OptionalType {}
