//
//  CGPath+RoundedRect.swift
//  BXSwiftUtils
//
//  Created by Stefan Fochler on 16.10.18.
//  Copyright © 2018 Boinx Software Ltd. & Imagine GbR. All rights reserved.
//

import Foundation
import QuartzCore.CoreAnimation

public extension CGPath
{
    /**
     Creates the path of a rounded rect of size `bounds` where only the cordners of `corners` are rounded using `radius`.
     
     - parameter bounds: The outer bounds of the rect.
     - parameter corners: The corner mask containing the corners to be rounded. If empty, no corners will be rounded.
     - parameter radius: The radius to be applied to the rounded corners.
     */
    static func roundedRect(inBounds bounds: CGRect, corners: CACornerMask, radius: CGFloat) -> CGPath
    {
        let path = CGMutablePath()
        
        if corners.contains(.layerMinXMaxYCorner)
        {
            let start = CGPoint(x: bounds.minX, y: bounds.maxY - radius)
            path.move(to: start)
            path.addArc(tangent1End: CGPoint(x: bounds.minX, y: bounds.maxY), tangent2End: CGPoint(x: bounds.minX + radius, y: bounds.maxY), radius: 5.0)
        }
        else
        {
            path.move(to: CGPoint(x: bounds.minX, y: bounds.maxY))
        }
        
        if corners.contains(.layerMaxXMaxYCorner)
        {
            let start = CGPoint(x: bounds.maxX - radius, y: bounds.maxY)
            path.addLine(to: start)
            path.addArc(tangent1End: CGPoint(x: bounds.maxX, y: bounds.maxY), tangent2End: CGPoint(x: bounds.maxX, y: bounds.maxY - radius), radius: radius)
        }
        else
        {
            path.addLine(to: CGPoint(x: bounds.maxX, y: bounds.maxY))
        }
        
        if corners.contains(.layerMaxXMinYCorner)
        {
            let start = CGPoint(x: bounds.maxX, y: bounds.minY + radius)
            path.addLine(to: start)
            path.addArc(tangent1End: CGPoint(x: bounds.maxX, y: bounds.minY), tangent2End: CGPoint(x: bounds.maxX - radius, y: bounds.minY), radius: radius)
        }
        else
        {
            path.addLine(to: CGPoint(x: bounds.maxX, y: bounds.minY))
        }
        
        if corners.contains(.layerMinXMinYCorner)
        {
            let start = CGPoint(x: bounds.minX + radius, y: bounds.minY)
            path.addLine(to: start)
            path.addArc(tangent1End: CGPoint(x: bounds.minX, y: bounds.minY), tangent2End: CGPoint(x: bounds.minX, y: bounds.minY + radius), radius: radius)
        }
        else
        {
            path.addLine(to: CGPoint(x: bounds.minX, y: bounds.minY))
        }
        
        path.closeSubpath()
        
        return path
    }
}
