//
//  Equatable+IsContainedIn.swift
//  BXSwiftUtils
//
//  Created by Stefan Fochler on 24.09.18.
//  Copyright © 2018 Boinx Software Ltd. & Imagine GbR. All rights reserved.
//

infix operator ~== : ComparisonPrecedence

public extension Equatable
{
    /**
     Checks whether the value is contained in the given collection.
     
     This function is basically syntactic sugar around `collection.contains...` that enhances the readability of that
     call and is much more concise than comparing against every value individually.
     
     Use of this function can be further abbreviated by the `~==` operator.
     
     ## Example
     
         if currentState ~== [.running, .scheduled]
         {
            // do something
         }
     
     - parameter collection: The collection of possible values that should be checked.
     - returns: `true` if the value is contained in the collection, `false` otherwise.
     */
    func isContained<C>(in collection: C) -> Bool where C: Collection, C.Element == Self
    {
        return collection.contains(self)
    }
    
    
    /// Implementation of `~==` operator that forwards call to `isContained(in:)`.
    static func ~== <C>(lhs: Self, rhs: C) -> Bool where C: Collection, C.Element == Self
    {
        return lhs.isContained(in: rhs)
    }
}
