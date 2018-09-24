//
//  DispatchQueue+Main.swift
//  BXSwiftUtils
//
//  Created by Stefan Fochler on 23.05.18.
//  Copyright © 2018 Boinx Software Ltd. & Imagine GbR. All rights reserved.
//

import Foundation


extension DispatchQueue
{
    /**
     Dispatches `block` for async execution or executes it directly if already on the correct queue.
 
     This function may only be called on the main queue. Using any other queue will result in an assertion being
     triggered during debug builds or incorrect operation in release builds.
     
     ## Example
     
         DispatchQueue.main.asyncIfNeeded
         {
            /*
             This code will run on the main queue.
             It will be ran synchronously if the caller was already on
             the main queue, or scheduled asynchrounsly otherise.
             */
         }
    
     */
	
    public func asyncIfNeeded(_ block: @escaping () -> Void)
    {
        assert(self === DispatchQueue.main, "\(#function) is only available for the main queue.")
        
        if Thread.isMainThread
        {
            block()
        }
        else
        {
            self.async(execute: block)
        }
    }

    public func syncIfNeeded(_ block: @escaping () -> Void)
    {
        assert(self === DispatchQueue.main, "\(#function) is only available for the main queue.")
		
        if Thread.isMainThread
        {
            block()
        }
        else
        {
            self.sync(execute: block)
        }
    }
}
