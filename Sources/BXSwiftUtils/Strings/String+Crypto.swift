//**********************************************************************************************************************
//
//  String+Crypto.swift
//	Functions to scramble a String
//  Copyright ©2021 Peter Baumgartner. All rights reserved.
//
//**********************************************************************************************************************


import Foundation
import CommonCrypto


//----------------------------------------------------------------------------------------------------------------------


public extension String
{
	var md5 : String
	{
        let length = Int(CC_MD5_DIGEST_LENGTH)
        let messageData = self.data(using:.utf8)!
        var digestData = Data(count:length)

        _ = digestData.withUnsafeMutableBytes
        {
			digestBytes -> UInt8 in
			
            messageData.withUnsafeBytes
            {
				messageBytes -> UInt8 in
				
                if let messageBytesBaseAddress = messageBytes.baseAddress,
                   let digestBytesBlindMemory = digestBytes.bindMemory(to: UInt8.self).baseAddress
                {
                    let messageLength = CC_LONG(messageData.count)
                    CC_MD5(messageBytesBaseAddress, messageLength, digestBytesBlindMemory)
                }
                
                return 0
            }
        }
        
        return digestData.map
        {
			String(format: "%02hhx", $0) }.joined()
		}

}


//----------------------------------------------------------------------------------------------------------------------
