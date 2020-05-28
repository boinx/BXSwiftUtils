//**********************************************************************************************************************
//
//  Array+DoubleLinkedList.swift
//	Double linked list support for arrays
//  Copyright ©2020 Peter Baumgartner. All rights reserved.
//
//**********************************************************************************************************************


public protocol BXDoubleLinkedListElement : class
{
	/// Reference to the preceeding element in the list. Returns nil if self is the first element in the list.
	
	/*weak*/ var prev:Self? { set get }

	/// Reference to the succeeding element in the list. Returns nil if self is the last element in the list.
	
	/*weak*/ var succ:Self? { set get }
}


//----------------------------------------------------------------------------------------------------------------------


public extension BXDoubleLinkedListElement
{
	/// Returns the first element in the list.

	var first:Self
	{
		return self.prev?.first ?? self
	}

	/// Returns the last element in the list.
	
	var last:Self
	{
		return self.succ?.last ?? self
	}
}


//----------------------------------------------------------------------------------------------------------------------


public extension Array where Element:BXDoubleLinkedListElement
{
	/// Creates the links between the list elements.
	///
	/// This function can be called after loading an array from a file to create the links for the first time. When manipulating the array later, the links should
	/// be carefully updated to avoid breaking the list.
	
	func generateLinkedList()
	{
		var prev:Element? = nil
		
		for curr in self
		{
			prev?.succ = curr
			curr.prev = prev
			prev = curr
		}
	}
	
	
	/// If for any reason the links in a list have been broken, call this function to repair the links.
	///
	/// Functionally this is the same as generateLinkedList() - it's just a semantically better name for this situation.
	
	func repairLinkedList()
	{
		self.generateLinkedList()
	}
	
	
	/// Returns true if the list links in this array are broken. If this is the case you should call the repairLinkedList() function.
	
	var isLinkedListBroken : Bool
	{
		let first:Element? = self.first
		let last:Element? = self.last
		var curr:Element? = first
		var prev:Element? = nil
		
		for elem in self
		{
			// Are all elements in the same order?
			
			if curr !== elem
			{
				return true
			}
			
			// Is the prev link broken?
			
			if elem !== first && elem.prev !== prev
			{
				return true
			}
			
			// Is the succ link broken?
			
			if elem !== last && elem.succ === nil
			{
				return true
			}
			
			prev = curr
			curr = curr?.succ
		}
		
		return false
	}
}


//----------------------------------------------------------------------------------------------------------------------
