//**********************************************************************************************************************
//
//  NSUIApplication+isConnectedToInternet.swift
//  A class that loads server hosted defaults and copies them to NSUserDefaults
//  Copyright ©2019 Peter Baumgartner. All rights reserved.
//
//**********************************************************************************************************************


import SystemConfiguration

#if os(iOS)
import UIKit
typealias NSUIApplication  = UIApplication
#else
import AppKit
typealias NSUIApplication  = NSApplication
#endif


//----------------------------------------------------------------------------------------------------------------------


public extension NSUIApplication
{

	/// Returns true if this device is currently connect to the internet, false if offline
	
    class var isConnectedToInternet : Bool
    {
        var zeroAddress = sockaddr_in(sin_len:0, sin_family:0, sin_port:0, sin_addr:in_addr(s_addr:0), sin_zero:(0,0,0,0,0,0,0,0))
        zeroAddress.sin_len = UInt8(MemoryLayout.size(ofValue:zeroAddress))
        zeroAddress.sin_family = sa_family_t(AF_INET)

        let defaultRouteReachability = withUnsafePointer(to: &zeroAddress)
        {
            $0.withMemoryRebound(to:sockaddr.self, capacity:1)
            {
            	zeroSockAddress in
                SCNetworkReachabilityCreateWithAddress(nil,zeroSockAddress)
            }
        }

        var flags: SCNetworkReachabilityFlags = SCNetworkReachabilityFlags(rawValue:0)
		
        if SCNetworkReachabilityGetFlags(defaultRouteReachability!, &flags) == false
        {
            return false
        }

        /* Only Working for WIFI
        let isReachable = flags == .reachable
        let needsConnection = flags == .connectionRequired

        return isReachable && !needsConnection
        */

        // Working for Cellular and WIFI
		
        let isReachable = (flags.rawValue & UInt32(kSCNetworkFlagsReachable)) != 0
        let needsConnection = (flags.rawValue & UInt32(kSCNetworkFlagsConnectionRequired)) != 0
        let ret = (isReachable && !needsConnection)

        return ret
    }
}


//----------------------------------------------------------------------------------------------------------------------
