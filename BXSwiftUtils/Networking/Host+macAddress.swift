//**********************************************************************************************************************
//
//  Host+macAddress.swift
//  MAC address of the ethernet device
//  Copyright ©2021 Peter Baumgartner. All rights reserved.
//
//**********************************************************************************************************************


import IOKit


//----------------------------------------------------------------------------------------------------------------------


extension Host
{

	/// Returns the MAC address of the last ethernet interface
	
	public var macAddress:String?
	{
		var macAddress:String?
		
		if let ethernetInterfaces = findEthernetInterfaces()
		{
			if let address = self.macAddress(for:ethernetInterfaces)
			{
				macAddress = address
					.map { String(format:"%02x",$0) }
					.joined(separator:":")
			}

			IOObjectRelease(ethernetInterfaces)
		}
		
		return macAddress
	}


	/// Returns the MAC address of the last ethernet interface.
	
	private func macAddress(for intfIterator:io_iterator_t) -> [UInt8]?
	{
		var macAddress : [UInt8]?
		var intfService = IOIteratorNext(intfIterator)
		
		while intfService != 0
		{
			var controllerService : io_object_t = 0
			
			if IORegistryEntryGetParentEntry(intfService, kIOServicePlane, &controllerService) == KERN_SUCCESS
			{
				let dataUM = IORegistryEntryCreateCFProperty(controllerService, "IOMACAddress" as CFString, kCFAllocatorDefault, 0)
				
				if dataUM != nil
				{
					let data = (dataUM!.takeRetainedValue() as! CFData) as Data
					macAddress = [0, 0, 0, 0, 0, 0]
					data.copyBytes(to: &macAddress!, count: macAddress!.count)
				}
				
				IOObjectRelease(controllerService)
			}

			IOObjectRelease(intfService)
			intfService = IOIteratorNext(intfIterator)
		}

		return macAddress
	}
	
	
	/// Returns an iterator for all ethernet interfaces
	
	private func findEthernetInterfaces() -> io_iterator_t?
	{
		let matchingDictUM = IOServiceMatching("IOEthernetInterface");
		// Note that another option here would be:
		// matchingDict = IOBSDMatching("en0");
		// but en0: isn't necessarily the primary interface, especially on systems with multiple Ethernet ports.

		if matchingDictUM == nil
		{
			return nil
		}

		let matchingDict = matchingDictUM! as NSMutableDictionary
		matchingDict["IOPropertyMatch"] = [ "IOPrimaryInterface" : true]

		var matchingServices : io_iterator_t = 0
		if IOServiceGetMatchingServices(kIOMasterPortDefault, matchingDict, &matchingServices) != KERN_SUCCESS
		{
			return nil
		}

		return matchingServices
	}
}


//----------------------------------------------------------------------------------------------------------------------
