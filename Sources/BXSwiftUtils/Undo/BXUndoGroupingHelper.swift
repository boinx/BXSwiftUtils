//**********************************************************************************************************************
//
//  BXUndoGroupingHelper.swift
//	A helper class for balancing beginUndoGrouping and endUndoGrouping
//  Copyright ©2022 Peter Baumgartner. All rights reserved.
//
//**********************************************************************************************************************


#if os(macOS)

import Foundation
import AppKit


//----------------------------------------------------------------------------------------------------------------------


/// Use this helper class with SwiftUI DragGesture to make sure that begin/endUndoGrouping is always properly balanced,
/// even if the onEnded closure is not called for some reason.

public class BXUndoGroupingHelper : NSObject
{
	public var undoManager:UndoManager? = nil
	public private(set) var didBegin = false
	public private(set) var didEnd = false
	
	/// Starts a new undo group if it wasn't already started before
	
	public func beginUndoGrouping()
	{
		guard let undoManager = undoManager else { return }

		if !didBegin
		{
			undoManager.groupsByEvent = false
			undoManager.beginUndoGrouping()
			
			self.didBegin = true
			self.didEnd = false
			
			self.checkMouseUp()
		}
	}
	
	/// Ends an existing undo group, if it was started before.
	
	public func endUndoGrouping(_ undoName:String? = nil)
	{
		guard let undoManager = undoManager else { return }
		
		if didBegin && !didEnd
		{
			if let undoName = undoName
			{
				undoManager.setActionName(undoName)
			}
			
			undoManager.endUndoGrouping()
			undoManager.groupsByEvent = true

			self.didBegin = false
			self.didEnd = true
		}
	}
	
	/// Checks if the mouse button is already released (up) and the undo group was not closed yet. In this case the group is closed manually.
	/// If the mouse button is still down, then check again in a while.
	
	@objc func checkMouseUp()
	{
		if !didEnd
		{
			if NSEvent.pressedMouseButtons == 0  // Is mouse button up again, but endUndoGrouping wasn't called yet?
			{
				self.endUndoGrouping()
			}
			else
			{
				self.perform(#selector(checkMouseUp), with:nil, afterDelay:0.25)
			}
		}
	}
	
	deinit
	{
		self.cancelAllDelayedPerforms()
	}
}


//----------------------------------------------------------------------------------------------------------------------


#endif
