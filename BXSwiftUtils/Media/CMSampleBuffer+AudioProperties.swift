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
    var formatDescription: CMFormatDescription? {
        return CMSampleBufferGetFormatDescription(self)
    }
    
    var basicDescription: UnsafePointer<AudioStreamBasicDescription>? {
        guard let formatDesc = self.formatDescription else { return nil }
        return CMAudioFormatDescriptionGetStreamBasicDescription(formatDesc)
    }
        
    var sampleRate: Float64? {
        return self.basicDescription?.pointee.mSampleRate
    }
}
