//
//  URL+QueryComponents.swift
//  BXSwiftUtils
//
//  Created by Achim Breidenbach on 12.04.21.
//  Copyright © 2021 Boinx Software Ltd. & Imagine GbR. All rights reserved.
//

import Foundation


//----------------------------------------------------------------------------------------------------------------------


// MARK: -

extension URL
{
	
	public var queryComponents: [String:String]
	{
		var result : [String:String] = [:]
		
		guard let query = self.query else { return result }
		
		let components = query.components(separatedBy: "&")
		for component in components
		{
			let parts = component.components(separatedBy: "=")
			if parts.count == 2
			{
				guard let key = (parts[0] as NSString).removingPercentEncoding else { continue }
				guard let value = (parts[1] as NSString).removingPercentEncoding else { continue }
				
				result[key] = value
			}
		}
		
		return result
	}
	
}
