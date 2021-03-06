//**********************************************************************************************************************
//
//  UndoManager+AutomaticName.swift
//	Registers undo action with an automatic action name
//  Copyright ©2019 Peter Baumgartner. All rights reserved.
//
//**********************************************************************************************************************


import Foundation


//----------------------------------------------------------------------------------------------------------------------


extension UndoManager
{
	/// This function automatically sets the action name to the name of the calling function before registering an undo action 
	
    public func registerUndoWithAutomaticName<TargetType>(target:TargetType, actionName:String = #function, handler: @escaping (TargetType)->Void) where TargetType:AnyObject
    {
		if _enableAutomaticUndoNames
		{
			self.setActionName(actionName)
		}
		
		return self.registerUndo(withTarget:target, handler:handler)
	}
	
	/// Set to true to enable automatically setting undo names when registering undo actions
	
	public static var enableAutomaticUndoNames: Bool
	{
		set { _enableAutomaticUndoNames = newValue }
		get { return _enableAutomaticUndoNames }
	}
}

private var _enableAutomaticUndoNames = false


//----------------------------------------------------------------------------------------------------------------------
