//**********************************************************************************************************************
//
//  MTLComputeCommandEncoder+Extensions.swift
//	Adds convenience methods
//  Copyright ©2018 Peter Baumgartner. All rights reserved.
//
//**********************************************************************************************************************


import Metal
import CoreGraphics


//----------------------------------------------------------------------------------------------------------------------


@available(iOS 11.0,macOS 10.11, *)

public extension MTLComputeCommandEncoder
{

	/// Helper method that dispatches compute threads to the GPU. Depending on the OS version and the capabilties
	/// of the hardware, the optimum API calls are chosen.
	
	public func dispatchThreads(for pipeline:MTLComputePipelineState,_ texture:MTLTexture)
	{
		if #available(iOS 11.0,macOS 10.13,*)
		{
			let threadCount = self.threadCount(for:texture)
			let groupSize = self.threadGroupSize(for:pipeline)
			self.dispatchThreads(threadCount,threadsPerThreadgroup:groupSize)
		}
		else
		{
	
		}
		
	}

	// The total number of threads matches the number of pixels in our image
	
	internal func threadCount(for inputTexture:MTLTexture) -> MTLSize
	{
		let w = inputTexture.width
		let h = inputTexture.height
		return MTLSizeMake(w,h,1)
	}
	
	// The image is divided into thread groups according to hardware capabilities
	
	internal func threadGroupSize(for pipeline:MTLComputePipelineState) -> MTLSize
	{
		let w = pipeline.threadExecutionWidth					// number of threads that will always be executed in parallel
		let h = pipeline.maxTotalThreadsPerThreadgroup / w
		return MTLSizeMake(w,h,1)
	}
}


//----------------------------------------------------------------------------------------------------------------------
