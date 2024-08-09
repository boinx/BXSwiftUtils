//**********************************************************************************************************************
//
//  NSView+EDRMixin.swift
//	Adds EDR support to NSView
//  Copyright ©2024 Peter Baumgartner. All rights reserved.
//
//**********************************************************************************************************************


#if os(macOS)

import AppKit
import Foundation


//----------------------------------------------------------------------------------------------------------------------


/// This mixin protocol adds support for get notified when the maximum EDR headroom value of the screen that the NSView resides on changes.

public protocol EDRMixin : AnyObject
{
	/// Call this function from an override of NSView.viewDidMoveToWindow() to install the necessary observers
	
	func setupEDRObservers(_ handler:((Bool,Double)->Void)?)

	/// This handler will be called whenever the EDR maximum headroom value changes
	
	var edrDidChangeHandler:((Bool,Double)->Void)? { set get }
	
	// Required properties to adopt this mixin
	
	var windowObserver:Any? { set get }
	var screenObserver:Any? { set get }
}


//----------------------------------------------------------------------------------------------------------------------


extension EDRMixin where Self:NSView
{
	public func setupEDRObservers(_ handler:((Bool,Double)->Void)? = nil)
	{
		self.setupWindowObserver()
		self.setupScreenObserver()
		
		self.edrDidChangeHandler = handler
		self.edrDidChange()
	}
	
	public func cleanupEDRObservers()
	{
		self.windowObserver = nil
		self.screenObserver = nil
	}
	
	private func setupWindowObserver()
	{
		self.windowObserver = NotificationCenter.default.publisher(for:NSWindow.didChangeScreenNotification, object:self.window).sink
		{
			[weak self] _ in
			self?.setupWindowObserver()
			self?.edrDidChange()
		}
	}

	private func setupScreenObserver()
	{
		self.screenObserver = NotificationCenter.default.publisher(for:NSApplication.didChangeScreenParametersNotification, object:nil).sink
		{
			[weak self] _ in
			self?.edrDidChange()
		}
	}
	
	private func edrDidChange()
	{
		var supportsEDR = false
		var potentialHeadroom:CGFloat = 1.0
		var currentHeadroom:CGFloat = 1.0
		
		if let screen = self.window?.screen
		{
			potentialHeadroom = screen.maximumPotentialExtendedDynamicRangeColorComponentValue 	// Static
			currentHeadroom = screen.maximumExtendedDynamicRangeColorComponentValue				// Dynamic
			supportsEDR = potentialHeadroom > 1.0 && currentHeadroom > 1.0
		}
		
		self.edrDidChangeHandler?(supportsEDR,currentHeadroom)
	}
}


//----------------------------------------------------------------------------------------------------------------------

#endif
