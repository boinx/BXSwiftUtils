//
//  BXMenuItem.swift
//  mimoLive
//
//  Created by Stefan Fochler on 15.03.18.
//  Copyright © 2018 Boinx Software Ltd. All rights reserved.
//

import Cocoa

/**
 A NSMenuItem alternative (subclass, in fact) that, instead of taking a target and selector, uses a handler closure
 that will be called with `representedObject` as arugment on selection.
 This simplifies the workflow of presenting a list of homogenous items and using the selection result.
 
 Unfortunately, testing this class requires a run loop or even a complete application and is therefore not feasible.
 */
public class BXMenuItem<T>: NSMenuItem
{
	private let handler: (T) -> ()
	
    public init(title string: String, representedObject: T, selectionHandler: @escaping (T) -> ())
	{
		self.handler = selectionHandler
		
		super.init(title: string, action: #selector(action(_:)), keyEquivalent: "")
		
		self.target = self
		self.representedObject = representedObject
	}
	
	required public init(coder decoder: NSCoder)
	{
		fatalError("init(coder:) has not been implemented")
	}
	
	@objc private func action(_ sender: Any)
	{
		self.handler(self.representedObject as! T)
	}
}
