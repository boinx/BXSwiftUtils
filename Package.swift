// swift-tools-version:5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(

    name: "BXSwiftUtils",
    defaultLocalization: "en",
    
    platforms:
    [
		.macOS(.v12),
		.iOS(.v14)
    ],
    
	// Products define the executables and libraries a package produces, and make them visible to other packages
        
    products:
    [
        .library(name:"BXSwiftUtils", targets:["BXSwiftUtils"]),
    ],
    
	// Dependencies declare other packages that this package depends on
	
    dependencies:
    [
        // .package(url: /* package url */, from: "1.0.0"),
    ],
    
	// Targets are the basic building blocks of a package. A target can define a module or a test suite.
	// Targets can depend on other targets in this package, and on products in packages this package depends on.

    targets:
    [
        // Objective-C helper that NSException+catch.swift relies on. Lives outside Sources/ so it needs its own target.
        .target(name:"BXSwiftUtilsObjC", path:"C", publicHeadersPath:"."),

        .target(name:"BXSwiftUtils", dependencies:["BXSwiftUtilsObjC"], resources:
        [
            .process("Int+localizedString.xcstrings"),
            .process("Strings/NSAttributedString+Markup.xcstrings"),
        ]),
//		.testTarget( name:"BXMediaBrowserTests", dependencies:["BXMediaBrowser"]),
    ]
)
