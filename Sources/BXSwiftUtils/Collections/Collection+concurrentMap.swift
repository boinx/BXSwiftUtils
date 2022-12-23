//**********************************************************************************************************************
//
//  Collection+concurrentMap.swift
//	Adds a parallelized version of the map function
//  Copyright ©2021 Peter Baumgartner. All rights reserved.
//
//**********************************************************************************************************************


import Foundation


//----------------------------------------------------------------------------------------------------------------------


public extension Collection
{
	/// This function works like the regular map(), except that work is distributed concurrently across multiple cores.
	///
	/// - parameter transform: This closure returns a result for each array element.
	
    func concurrentMap<T>(_ transform:@escaping (Element)->T) -> [T]
    {
		let n = self.count
        let lock = NSRecursiveLock()
        var values:[T?] = .init(repeating:nil, count:n)
        
        DispatchQueue.concurrentPerform(iterations:n)
        {
			i in
			
			let element = self[index(startIndex,offsetBy:i)]
            let value = transform(element)
            
            lock.lock()
            values[i] = value
            lock.unlock()
        }

        return values.compactMap { $0 }
    }
}


//----------------------------------------------------------------------------------------------------------------------
