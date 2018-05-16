//**********************************************************************************************************************
//
//  UndoManager+Disabling.swift
//	Adds method for temp disabling of undo registration
//  Copyright ©2018 Peter Baumgartner. All rights reserved.
//
//**********************************************************************************************************************


import Foundation


//----------------------------------------------------------------------------------------------------------------------


extension UndoManager
{

    /**
	
	Registering undo actions will be suppressed inside the supplied closure. That way some code that is known
	to contain undoable changes can be made non-undoable, where this is required in local contexts.
	## Example
	```
	self.document?.undomanager?.makeChangesWithoutUndoRegistration
	{
		performSomeWorkThatRecordsUnwantedUndoActions()
	}
	```
	- parameter closure: The closure (block) to be executed.
	
    */
	
	public func makeChangesWithoutUndoRegistration(_ closure:() throws -> Void) rethrows
	{
		self.disableUndoRegistration()
		defer { self.enableUndoRegistration() }
		try closure()
	}


//----------------------------------------------------------------------------------------------------------------------


    /**
	
	Any undo actions that are registered within the provided closure are automatically marked as discardable.
	This will ensure, that undo steps are still recorded, but since they are marked as discardable, there is
	a mechanism to not dirty the document.
	## Example
	```
	self.document?.undomanager?.makeDiscardableChanges
	{
		performSomeWorkThatRecordsUnwantedUndoActions()
	}
	```
	- parameter closure: The closure (block) to be executed.
	
    */
	
	public func makeDiscardableChanges(_ closure:() throws -> Void) rethrows
	{
		// Start a new group and mark everything inside that group as discardable
		
		self.beginUndoGrouping()
		
		defer
		{
			self.setActionIsDiscardable(true)
			self.endUndoGrouping()
		}
		
		// Now execute the closure, which we assume will register some undoable actions -
		// and hopefully also set a name to make debugging easier
		
		try closure()
	}

}


//----------------------------------------------------------------------------------------------------------------------
