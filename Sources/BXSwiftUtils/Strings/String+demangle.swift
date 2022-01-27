

// Taken from https://stackoverflow.com/questions/24321773/how-can-i-demangle-a-swift-class-name-dynamically/25990097


//----------------------------------------------------------------------------------------------------------------------


import Darwin


//----------------------------------------------------------------------------------------------------------------------


typealias Swift_Demangle = @convention(c) (_ mangledName: UnsafePointer<UInt8>?,
                                           _ mangledNameLength: Int,
                                           _ outputBuffer: UnsafeMutablePointer<UInt8>?,
                                           _ outputBufferSize: UnsafeMutablePointer<Int>?,
                                           _ flags: UInt32) -> UnsafeMutablePointer<Int8>?


//----------------------------------------------------------------------------------------------------------------------


/// Returns the human readable form of a mangled swift function name

public func swift_demangle(_ mangled:String) -> String?
{
    let RTLD_DEFAULT = dlopen(nil, RTLD_NOW)
    if let sym = dlsym(RTLD_DEFAULT, "swift_demangle")
    {
        let f = unsafeBitCast(sym, to: Swift_Demangle.self)
        if let cString = f(mangled, mangled.count, nil, nil, 0)
        {
            defer { cString.deallocate() }
            return String(cString: cString)
        }
    }
    return nil
}


//----------------------------------------------------------------------------------------------------------------------


public extension String
{
	/// Returns the human readable form of a mangled swift function name
	
	func demangled() -> String
	{
		return swift_demangle(self) ?? self
	}
}


//----------------------------------------------------------------------------------------------------------------------


