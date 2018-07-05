//
//  NSMenu.swift
//  BXSwiftUtils-macOS
//
//  Created by Stefan Fochler on 27.06.18.
//  Copyright © 2018 Boinx Software Ltd. & Imagine GbR. All rights reserved.
//

import AppKit

extension NSMenu
{
    /**
     Appends a menu item to a menu using a conventient notation.
     */
    public static func +=(menu: NSMenu, item: NSMenuItem)
    {
        menu.addItem(item)
    }
}
