//**********************************************************************************************************************
//
//  NSEvent+ModifierKeys.swift
//	Adds convenience methods for checking modified keys
//  Copyright ©2017 Peter Baumgartner. All rights reserved.
//
//**********************************************************************************************************************


import AppKit


//----------------------------------------------------------------------------------------------------------------------


extension NSEvent
{
	/// Returns the keycode, useful for arrow keys of other function keys.
	
    public var key:Int
	{
        let str = charactersIgnoringModifiers!.utf16
        return Int(str[str.startIndex])
    }

	/// Returns true if the command key is down.
	
    public var isCommandDown:Bool
	{
		return self.modifierFlags.contains(.command)
	}
	
	/// Returns true if the option key is down.
	
    public var isOptionDown:Bool
	{
		return self.modifierFlags.contains(.option)
	}
	
	/// Returns true if the control key is down.
	
	public var isControlDown:Bool
	{
		return self.modifierFlags.contains(.control)
	}
	
	/// Returns true if the shift key is down.
	
    public var isShiftDown:Bool
	{
		return self.modifierFlags.contains(.shift)
	}
	
	/// Returns true if the capslock key is down.
	
	public var isCapsLockDown:Bool
	{
		return self.modifierFlags.contains(.capsLock)
	}
	
	/// Returns true if no modifier keys are pressed.
	
	public var isNoModifierDown:Bool
	{
		return self.modifierFlags.intersection([.command,.option,.control,.shift,.capsLock]).isEmpty
	}
}


//----------------------------------------------------------------------------------------------------------------------
