//----------------------------------------------------------------------------------------------------------------------
//
//  Copyright ©2022 Peter Baumgartner. All rights reserved.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//
//----------------------------------------------------------------------------------------------------------------------


import Foundation


//----------------------------------------------------------------------------------------------------------------------


// Since the following constants are not available on iOS we'll define them for cross-platform code

#if os(iOS) || os(tvOS)

public let kMDItemFSSize = "kMDItemFSSize" as CFString
public let kMDItemKind = "kMDItemKind" as CFString
public let kMDItemDescription = "kMDItemDescription" as CFString
public let kMDItemFSCreationDate = "kMDItemFSCreationDate" as CFString
public let kMDItemFSContentChangeDate = "kMDItemFSContentChangeDate" as CFString
public let kMDItemContentCreationDate = "kMDItemContentCreationDate" as CFString
public let kMDItemWhereFroms = "kMDItemWhereFroms" as CFString
public let kMDItemCopyright = "kMDItemCopyright" as CFString
public let kMDItemAuthorAddresses = "kMDItemAuthorAddresses" as CFString
public let kMDItemComment = "kMDItemComment" as CFString

public let kMDItemPixelWidth = "kMDItemPixelWidth" as CFString
public let kMDItemPixelHeight = "kMDItemPixelHeight" as CFString
public let kMDItemProfileName = "kMDItemProfileName" as CFString
public let kMDItemColorSpace = "kMDItemColorSpace" as CFString

public let kMDItemAperture = "kMDItemAperture" as CFString
public let kMDItemExposureTimeSeconds = "kMDItemExposureTimeSeconds" as CFString
public let kMDItemFocalLength35mm = "kMDItemFocalLength35mm" as CFString
public let kMDItemISOSpeed = "kMDItemISOSpeed" as CFString

public let kMDItemAltitude = "kMDItemAltitude" as CFString
public let kMDItemLatitude = "kMDItemLatitude" as CFString
public let kMDItemLongitude = "kMDItemLongitude" as CFString
public let kMDItemNamedLocation = "kMDItemNamedLocation" as CFString

public let kMDItemCodecs = "kMDItemCodecs" as CFString
public let kMDItemVideoBitRate = "kMDItemVideoBitRate" as CFString
public let kMDItemAudioBitRate = "kMDItemAudioBitRate" as CFString

public let kMDItemDurationSeconds = "kMDItemDurationSeconds" as CFString
public let kMDItemTitle = "kMDItemTitle" as CFString
public let kMDItemAlbum = "kMDItemAlbum" as CFString
public let kMDItemAuthors = "kMDItemAuthors" as CFString
public let kMDItemComposer = "kMDItemComposer" as CFString
public let kMDItemMusicalGenre = "kMDItemMusicalGenre" as CFString
public let kMDItemTempo = "kMDItemTempo" as CFString
public let kMDItemKeySignature = "kMDItemKeySignature" as CFString
public let kMDItemTimeSignature = "kMDItemTimeSignature" as CFString
public let kMDItemAudioSampleRate = "kMDItemAudioSampleRate" as CFString
public let kMDItemAudioChannelCount = "kMDItemAudioChannelCount" as CFString

#endif


//----------------------------------------------------------------------------------------------------------------------


public extension String
{
	// General metadata
	
	static let fileSizeKey = kMDItemFSSize as String
	static let kindKey = kMDItemKind as String
	static let descriptionKey = kMDItemDescription as String //"description"
	static let captureDateKey = kMDItemContentCreationDate as String 
	static let creationDateKey = kMDItemFSCreationDate as String //"creationDate"
	static let modificationDateKey = kMDItemFSContentChangeDate as String //"modificationDate"
	static let whereFromsKey = kMDItemWhereFroms as String
	static let copyrightKey = kMDItemCopyright as String
	static let authorAddressesKey = kMDItemAuthorAddresses as String

	// Image metadata
	
	static let widthKey = kMDItemPixelWidth as String
	static let heightKey = kMDItemPixelHeight as String
	static let orientationKey = "Orientation"
	static let profileNameKey = kMDItemProfileName as String //"ProfileName"
	static let modelKey = kMDItemColorSpace as String //"Model"

	static let exifApertureKey = kMDItemAperture as String //"ApertureValue"
	static let exifExposureTimeKey = kMDItemExposureTimeSeconds as String //"ExposureTime"
	static let exifFocalLengthKey = kMDItemFocalLength35mm as String //"FocalLenIn35mmFilm"
	static let exifISOSpeedKey = kMDItemISOSpeed as String
	static let exifCaptureDateKey = "DateTimeOriginal"

	static let altitudeKey = kMDItemAltitude as String
	static let latitudeKey = kMDItemLatitude as String
	static let longitudeKey = kMDItemLongitude as String
	static let locationNameKey = kMDItemNamedLocation as String

	// Video metadata
	
	static let codecsKey = kMDItemCodecs as String
	static let videoCodecKey = "videoCodec"
	static let audioCodecKey = "audioCodec"
	static let videoBitRateKey = kMDItemVideoBitRate as String
	static let audioBitRateKey = kMDItemAudioBitRate as String
	static let fpsKey = "fps"

	// Audio metadata
	
	static let durationKey = kMDItemDurationSeconds as String
	static let titleKey = kMDItemTitle as String
	static let albumKey = kMDItemAlbum as String
	static let authorsKey = kMDItemAuthors as String
	static let composerKey = kMDItemComposer as String
	static let genreKey = kMDItemMusicalGenre as String
	static let tempoKey = kMDItemTempo as String
	static let keySignatureKey = kMDItemKeySignature as String
	static let timeSignatureKey = kMDItemTimeSignature as String
	static let audioSampleRateKey = kMDItemAudioSampleRate as String
	static let audioChannelCountKey = kMDItemAudioChannelCount as String
}

//public extension String
//{
//	// General metadata
//
//	static let fileSizeKey = "kMDItemFSSize"
//	static let kindKey = "kMDItemKind"
//	static let descriptionKey = "kMDItemDescription"
//	static let creationDateKey = "kMDItemFSCreationDate"
//	static let modificationDateKey = "kMDItemFSContentChangeDate"
//	static let whereFromsKey = "kMDItemWhereFroms"
//	static let copyrightKey = "kMDItemCopyright"
//	static let authorAddressesKey = "kMDItemAuthorAddresses"
//
//	// Image metadata
//
//	static let widthKey = "kMDItemPixelWidth"
//	static let heightKey = "kMDItemPixelHeight"
//	static let profileNameKey = "kMDItemProfileName"
//	static let modelKey = "kMDItemColorSpace"
//
//	static let exifApertureKey = "kMDItemAperture"
//	static let exifExposureTimeKey = "kMDItemExposureTimeSeconds"
//	static let exifFocalLengthKey = "kMDItemFocalLength35mm"
//	static let exifISOSpeedKey = "kMDItemISOSpeed"
//	static let exifCaptureDateKey = "DateTimeOriginal"
//
//	static let altitudeKey = "kMDItemAltitude"
//	static let latitudeKey = "kMDItemLatitude"
//	static let longitudeKey = "kMDItemLongitude"
//	static let locationNameKey = "kMDItemNamedLocation"
//
//	// Video metadata
//
//	static let codecsKey = "kMDItemCodecs"
//	static let videoCodecKey = "videoCodec"
//	static let audioCodecKey = "audioCodec"
//	static let videoBitRateKey = "kMDItemVideoBitRate"
//	static let audioBitRateKey = "kMDItemAudioBitRate"
//	static let fpsKey = "fps"
//
//	// Audio metadata
//
//	static let durationKey = "kMDItemDurationSeconds"
//	static let titleKey = "kMDItemTitle"
//	static let albumKey = "kMDItemAlbum"
//	static let authorsKey = "kMDItemAuthors"
//	static let composerKey = "kMDItemComposer"
//	static let genreKey = "kMDItemMusicalGenre"
//	static let tempoKey = "kMDItemTempo"
//	static let keySignatureKey = "kMDItemKeySignature"
//	static let timeSignatureKey = "kMDItemTimeSignature"
//	static let audioSampleRateKey = "kMDItemAudioSampleRate"
//	static let audioChannelCountKey = "kMDItemAudioChannelCount"
//}


//----------------------------------------------------------------------------------------------------------------------

