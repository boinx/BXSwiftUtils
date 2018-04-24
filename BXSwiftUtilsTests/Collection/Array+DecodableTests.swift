//
//  AppDelegate.swift
//  encoding
//
//  Created by Stefan Fochler on 24.04.18.
//  Copyright © 2018 Stefan Fochler. All rights reserved.
//

import XCTest
import BXSwiftUtils


fileprivate struct Slide: Codable
{
    let visualObjects: [VisualObject]
    
    init(visualObjects: [VisualObject])
    {
        self.visualObjects = visualObjects
    }
    
    private enum CodingKeys: String, CodingKey
    {
        case visualObjects
    }
    
    private enum ChildCodingKeys: String, CodingKey
    {
    	case className1 = "class"
        case className2 = "className"
    }
    
    init(from decoder: Decoder) throws
    {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.visualObjects = try container.decodeHeterogeneousArray(forKey: .visualObjects)
        { decoder -> VisualObject.Type in
            let itemContainer = try decoder.container(keyedBy: ChildCodingKeys.self)
            let className1 = try itemContainer.decodeIfPresent(String.self, forKey: .className1)
            let className2 = try itemContainer.decodeIfPresent(String.self, forKey: .className2)
            let className = className1 ?? className2 ?? ""
            
            switch className
            {
                case "ImageObject", "ImageItem": return ImageObject.self
                case "VideoObject", "MovieItem": return VideoObject.self
                default: throw DecodingError.typeMismatch(VisualObject.self, DecodingError.Context(codingPath: decoder.codingPath,
                                                                                                   debugDescription: "Couldn't determine subtype"))
            }
        }
    }
}


fileprivate class VisualObject: NSObject, Codable
{
    let visible: Bool
    let identifier: String

    override init()
    {
        self.visible = true
        self.identifier = UUID().uuidString
        super.init()
    }
    
    private enum CodingKeys: String, CodingKey
    {
 		case className
		case identifier
        case visible
     }
    
    func encode(to encoder: Encoder) throws
    {
        var container = encoder.container(keyedBy: CodingKeys.self)
        // Class name must be encoded by child classes
        try container.encode(self.identifier, forKey: .identifier)
        try container.encode(self.visible, forKey: .visible)
    }
    
    required init(from decoder: Decoder) throws
    {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.identifier = try container.decode(String.self, forKey: .identifier)
        self.visible = try container.decode(Bool.self, forKey: .visible)
    }
}


fileprivate class ImageObject: VisualObject
{
    let url: String
    
    init(url: String = "image.png")
    {
        self.url = url
        super.init()
    }
    
    private enum CodingKeys: String, CodingKey
    {
        case className
        case url
    }
    
    override func encode(to encoder: Encoder) throws
    {
        try super.encode(to: encoder)
        
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode("ImageObject", forKey: .className)
        try container.encode(self.url, forKey: .url)
    }
    
    required init(from decoder: Decoder) throws
    {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.url = try container.decode(String.self, forKey: .url)
        try super.init(from: decoder)
    }
}


fileprivate class VideoObject: VisualObject
{
    let duration: Double
    
    override init()
    {
        self.duration = 5.0
        super.init()
    }
    
    private enum CodingKeys: String, CodingKey
    {
        case className
        case duration
    }
    
    override func encode(to encoder: Encoder) throws
    {
        try super.encode(to: encoder)
		var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode("VideoObject", forKey: .className)
        try container.encode(self.duration, forKey: .duration)
    }
    
    required init(from decoder: Decoder) throws
    {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.duration = try container.decode(Double.self, forKey: .duration)
        try super.init(from: decoder)
    }
}


class Array_DecodableTests: XCTestCase {

    /*
     Asserts that a heterogenous array is decoded to the correct types after encoding and decoding.
     */
    func testDecoding()
    {
        let visualObjects = [
    		ImageObject(url:"Image001.png"),
        	ImageObject(url:"Image002.png"),
       		VideoObject(),
          	ImageObject(url:"Image003.png"),
        ]
		
        let slide = Slide(visualObjects: visualObjects)
        
        // Encode
        let encoder = JSONEncoder()
        let data = try! encoder.encode(slide)
        
        // Decode
        let decoder = JSONDecoder()
        let result = try! decoder.decode(Slide.self, from: data)
        
        // Compare the array elements' types
        let expectedTypes: [String] = visualObjects.map({ $0.className })
        let resultTypes: [String] = result.visualObjects.map({ $0.className })
        
        XCTAssertEqual(expectedTypes, resultTypes)
    }
    
}

