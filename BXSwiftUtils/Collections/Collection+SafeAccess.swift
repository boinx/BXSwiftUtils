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
    
    public subscript (safe range: Range<Index>) -> Self.SubSequence
    {
        let lowerBound = Swift.max(range.lowerBound, self.startIndex)
        let upperBound = Swift.min(range.upperBound, self.endIndex)
        
        // If the range was completely outside of the collection's index range, return an empty sub sequence.
        if lowerBound > upperBound
        {
            return self.prefix(0)
        }
        
        return self[lowerBound..<upperBound]
    }
    
    public subscript (safe range: ClosedRange<Index>) -> Self.SubSequence
    {
        // Use the implementation of safe Range access.
        return self[safe: range.lowerBound..<self.index(after: range.upperBound)]
    }
}
