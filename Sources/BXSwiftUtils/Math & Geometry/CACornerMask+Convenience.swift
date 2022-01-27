//
//  CACornerMask+Accessors.swift
//  BXSwiftUtils
//
//  Created by Stefan Fochler on 16.10.18.
//  Copyright © 2018 Boinx Software Ltd. & Imagine GbR. All rights reserved.
//

import QuartzCore.CoreAnimation

public extension CACornerMask
{
    static let allCorners: CACornerMask = [
        .layerMaxXMaxYCorner,
        .layerMaxXMinYCorner,
        .layerMinXMaxYCorner,
        .layerMinXMinYCorner
    ]
    
    #if os(macOS)
    static let bottomCorners: CACornerMask = [
        .layerMaxXMinYCorner,
        .layerMinXMinYCorner
    ]
    
    static let topCorners: CACornerMask = [
        .layerMinXMaxYCorner,
        .layerMaxXMaxYCorner
    ]
    #elseif os(iOS)
    static let bottomCorners: CACornerMask = [
        .layerMaxXMaxYCorner,
        .layerMinXMaxYCorner
    ]
    
    static let topCorners: CACornerMask = [
        .layerMinXMinYCorner,
        .layerMaxXMinYCorner
    ]
    #endif
    
    static let leftCorners: CACornerMask = [
        .layerMinXMinYCorner,
        .layerMinXMaxYCorner
    ]
    
    static let rightCorners: CACornerMask = [
        .layerMaxXMinYCorner,
        .layerMaxXMaxYCorner
    ]
}
