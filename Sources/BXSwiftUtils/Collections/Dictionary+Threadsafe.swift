//
//  ThreadsafeDictionary.swift
//  BXSwiftUtils
//
//  Created by Peter Baumgartner on 23.05.22.
//  Copyright ©2022 IMAGINE GbR. All rights reserved.
//

import Foundation


public extension Dictionary
{
	subscript(threadsafe key:Key) -> Value?
	{
        get
        {
			synchronized(self)
			{
				self[key]
			}
        }
        
        set
        {
            synchronized(self)
			{
				self[key] = newValue
			}
        }
    }
}


open class ThreadsafeDictionary<K,V> where K:Hashable, V:Any
{
	private var dict:[K:V]
	
	public init()
	{
		self.dict = [:]
	}

	public subscript(_ key:K) -> V?
	{
        get
        {
			synchronized(self)
			{
				dict[key]
			}
        }
        
        set
        {
            synchronized(self)
			{
				dict[key] = newValue
			}
        }
    }
}
