//
//  Collection+SafeAccess.swift
//  BXSwiftUtils-macOS
//
//  Created by Stefan Fochler on 08.03.18.
//  Copyright © 2018 Boinx Software Ltd. All rights reserved.
//

import Foundation

extension Collection where Element: Any
{
    
    public subscript (safe index: Index) -> Element?
    {
        return indices.contains(index) ? self[index] : nil
    }
}
