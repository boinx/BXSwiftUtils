//**********************************************************************************************************************
//
//  CMSampleBuffer+AudioProperties.swift
//  A extension which allows easier access to audio properties of a CMSampleBuffer.
//  Copyright © 2020 Boinx Software Ltd. & Imagine GbR. All rights reserved.
//
//**********************************************************************************************************************

import Foundation
import CoreMedia

public extension CMSampleBuffer
{
    var formatDesc: CMFormatDescription? {
        return CMSampleBufferGetFormatDescription(self)
    }
    
    var basicDescription: UnsafePointer<AudioStreamBasicDescription>? {
        guard let formatDesc = self.formatDesc else { return nil }
        return CMAudioFormatDescriptionGetStreamBasicDescription(formatDesc)
    }
        
    var sampleRate: Float64? {
        return self.basicDescription?.pointee.mSampleRate
    }
    
    var sampleCount: CMItemCount {
        return CMSampleBufferGetNumSamples(self)
    }
    
    var dataLength: Int {
        guard let blockBuffer = CMSampleBufferGetDataBuffer(self) else { return 0 }
        return CMBlockBufferGetDataLength(blockBuffer)
    }
    
    var presentationTimeStamp: CMTime {
        return CMSampleBufferGetPresentationTimeStamp(self)
    }
    
}

public extension CMSampleBuffer {
    func logAll() {
        print("\n**************************")
        print("\tLogging :\(self).")
        print("\n")
        print("\tformatDesc:\(String(describing: self.formatDesc))")
        print("\tbasicDescription:\(String(describing: self.basicDescription))")
        print("\tsampleRate:\(String(describing: self.sampleRate))")
        print("\tsampleCount:\(self.sampleCount)")
        print("\tdataLength:\(self.dataLength)")
        print("\tpresentationTimeStamp:\(self.presentationTimeStamp)")
        print("\n**************************\n")
    }
}
