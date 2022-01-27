//
//  Array+AllEqual.swift
//  BXSwiftUtils-macOS
//
//  Created by Stefan Fochler on 14.03.18.
//  Copyright © 2018 Boinx Software Ltd. & Imagine GbR. All rights reserved.
//

import Foundation

extension Array where Element: Equatable
{
    /**
     Tests if all objects of the array are equal to the given value.
     For empty arrays, this method returns `nil` so that the caller has to decide what is the correct default value for
     in the concrete situation.
     
     - parameter element: The element that is compared against.
     - returns: `nil` for empty arrays, `true` if all elements match and `false` if at least one element doesn't match.
     */
    public func allEqual(to element: Element) -> Bool?
    {
        if self.isEmpty { return nil }
        
        return !self.contains(where: { $0 != element })
    }
}
