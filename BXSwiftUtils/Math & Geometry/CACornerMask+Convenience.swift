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
    public static let allCorners: CACornerMask = [
        .layerMaxXMaxYCorner,
        .layerMaxXMinYCorner,
        .layerMinXMaxYCorner,
        .layerMinXMinYCorner
    ]
    
    #if os(macOS)
    public static let bottomCorners: CACornerMask = [
        .layerMaxXMinYCorner,
        .layerMinXMinYCorner
    ]
    
    public static let topCorners: CACornerMask = [
        .layerMinXMaxYCorner,
        .layerMaxXMaxYCorner
    ]
    #elseif os(iOS)
    public static let bottomCorners: CACornerMask = [
        .layerMaxXMaxYCorner,
        .layerMinXMaxYCorner
    ]
    
    public static let topCorners: CACornerMask = [
        .layerMinXMinYCorner,
        .layerMaxXMinYCorner
    ]
    #endif
    
    public static let leftCorners: CACornerMask = [
        .layerMinXMinYCorner,
        .layerMinXMaxYCorner
    ]
    
    public static let rightCorners: CACornerMask = [
        .layerMaxXMinYCorner,
        .layerMaxXMaxYCorner
    ]
}
