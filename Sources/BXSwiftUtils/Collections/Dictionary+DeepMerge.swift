//
//  Dictionary+DeepMerge.swift
//  BXSwiftUtils
//
//  Created by Mladen Mikic on 03/12/2020.
//  Copyright © 2020 Boinx Software Ltd. & Imagine GbR. All rights reserved.
//

import Foundation


extension Dictionary {
    
    typealias AnyDict = [String: Any]
    
    /// Merges dictionaries of type [String: Any] recursively and returns the merged result.
    func deepMerge(_ d1: AnyDict, _ d2: AnyDict) -> AnyDict {
        var mergedD1 = d1
        for (k2, v2) in d2 {
            if let v1 = mergedD1[k2] as? AnyDict, let v2 = v2 as? AnyDict {
                mergedD1[k2] = deepMerge(v1, v2)
            } else {
                mergedD1[k2] = v2
            }
        }
        return mergedD1
    }
    
}
