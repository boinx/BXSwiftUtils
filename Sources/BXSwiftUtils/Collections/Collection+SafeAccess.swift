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
        // A closed range includes its upper bound, so the half-open equivalent ends one past it. Advancing past
        // that bound is the hazard: index(after:) is only defined for an index the collection actually has, and on
        // an Int indexed collection it OVERFLOWS at Index.max - so `list[safe: 0...Int.max]` used to crash, in a
        // subscript whose entire purpose is not to. Both ends are therefore clamped into the collection BEFORE any
        // index arithmetic happens, and the advance is skipped altogether when the bound is already past the end.

        let lower = Swift.max(range.lowerBound, self.startIndex)

        // The second condition is an EQUIVALENT MUTANT for an Int indexed collection - confirmed by mutation,
        // since a bound far below the start already fails the lower < upper check further down. It is kept for
        // the collections this extension also serves: a String or Dictionary index below startIndex is not a
        // thing index(after:) is defined for, and no test can construct one to prove it.

        guard lower < self.endIndex, range.upperBound >= self.startIndex else { return self.prefix(0) }

        let upper = range.upperBound < self.endIndex ? self.index(after: range.upperBound) : self.endIndex

        // Unreachable for any Collection that indexes the way the protocol requires - the guards above already
        // establish lower < upper. Kept because what makes it redundant is the index arithmetic of whatever type
        // conforms, which is not this file's to guarantee, and because the cost of being wrong here is the crash
        // this subscript exists to prevent.

        guard lower < upper else { return self.prefix(0) }

        return self[lower..<upper]
    }
}
