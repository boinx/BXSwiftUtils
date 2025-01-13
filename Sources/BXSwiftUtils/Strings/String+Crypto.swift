//**********************************************************************************************************************
//
//  String+Crypto.swift
//	Functions to scramble a String
//  Copyright ©2021-2025 Peter Baumgartner. All rights reserved.
//
//**********************************************************************************************************************


import Foundation
import CommonCrypto


//----------------------------------------------------------------------------------------------------------------------


public extension String
{
	/// Returns a SHA256 encrypted version of this string
	
    var sha256:String
    {
        let length = Int(CC_SHA256_DIGEST_LENGTH)
        let messageData = self.data(using:.utf8)!
        var digestData = Data(count:length)

        digestData.withUnsafeMutableBytes
        {
			digestBytes in
			
            messageData.withUnsafeBytes
            {
				messageBytes in
				
                if let messageBytesBaseAddress = messageBytes.baseAddress,
                   let digestBytesBaseAddress = digestBytes.bindMemory(to: UInt8.self).baseAddress
				{
                	let messageLength = CC_LONG(messageData.count)
                    CC_SHA256(messageBytesBaseAddress, messageLength, digestBytesBaseAddress)
                }
            }
        }

        return digestData.map { String(format:"%02hhx",$0) }.joined()
    }


	/// Returns a MD5 encrypted version of this string.
	///
	/// Please note that MD% is deprecated and should not be used anymore, but I didn't delete the code yet, just in case we need
	/// to use it for some reason in the future.

//	var md5:String
//	{
//        let length = Int(CC_MD5_DIGEST_LENGTH)
//        let messageData = self.data(using:.utf8)!
//        var digestData = Data(count:length)
//
//        _ = digestData.withUnsafeMutableBytes
//        {
//			digestBytes -> UInt8 in
//			
//            messageData.withUnsafeBytes
//            {
//				messageBytes -> UInt8 in
//				
//                if let messageBytesBaseAddress = messageBytes.baseAddress,
//                   let digestBytesBlindMemory = digestBytes.bindMemory(to: UInt8.self).baseAddress
//                {
//                    let messageLength = CC_LONG(messageData.count)
//                    CC_MD5(messageBytesBaseAddress, messageLength, digestBytesBlindMemory)
//                }
//                
//                return 0
//            }
//        }
//        
//        return digestData.map { String(format:"%02hhx",$0) }.joined()
//	}
}


//----------------------------------------------------------------------------------------------------------------------
