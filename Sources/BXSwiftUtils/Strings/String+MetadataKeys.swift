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

#if os(iOS)

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
	
	static var fileSizeKey = kMDItemFSSize as String
	static var kindKey = kMDItemKind as String
	static var descriptionKey = kMDItemDescription as String //"description"
	static var captureDateKey = kMDItemContentCreationDate as String 
	static var creationDateKey = kMDItemFSCreationDate as String //"creationDate"
	static var modificationDateKey = kMDItemFSContentChangeDate as String //"modificationDate"
	static var whereFromsKey = kMDItemWhereFroms as String
	static var copyrightKey = kMDItemCopyright as String
	static var authorAddressesKey = kMDItemAuthorAddresses as String

	// Image metadata
	
	static var widthKey = kMDItemPixelWidth as String
	static var heightKey = kMDItemPixelHeight as String
	static var orientationKey = "Orientation"
	static var profileNameKey = kMDItemProfileName as String //"ProfileName"
	static var modelKey = kMDItemColorSpace as String //"Model"

	static var exifApertureKey = kMDItemAperture as String //"ApertureValue"
	static var exifExposureTimeKey = kMDItemExposureTimeSeconds as String //"ExposureTime"
	static var exifFocalLengthKey = kMDItemFocalLength35mm as String //"FocalLenIn35mmFilm"
	static var exifISOSpeedKey = kMDItemISOSpeed as String
	static var exifCaptureDateKey = "DateTimeOriginal"

	static var altitudeKey = kMDItemAltitude as String
	static var latitudeKey = kMDItemLatitude as String
	static var longitudeKey = kMDItemLongitude as String
	static var locationNameKey = kMDItemNamedLocation as String

	// Video metadata
	
	static var codecsKey = kMDItemCodecs as String
	static var videoCodecKey = "videoCodec"
	static var audioCodecKey = "audioCodec"
	static var videoBitRateKey = kMDItemVideoBitRate as String
	static var audioBitRateKey = kMDItemAudioBitRate as String
	static var fpsKey = "fps"

	// Audio metadata
	
	static var durationKey = kMDItemDurationSeconds as String
	static var titleKey = kMDItemTitle as String
	static var albumKey = kMDItemAlbum as String
	static var authorsKey = kMDItemAuthors as String
	static var composerKey = kMDItemComposer as String
	static var genreKey = kMDItemMusicalGenre as String
	static var tempoKey = kMDItemTempo as String
	static var keySignatureKey = kMDItemKeySignature as String
	static var timeSignatureKey = kMDItemTimeSignature as String
	static var audioSampleRateKey = kMDItemAudioSampleRate as String
	static var audioChannelCountKey = kMDItemAudioChannelCount as String
}

//public extension String
//{
//	// General metadata
//
//	static var fileSizeKey = "kMDItemFSSize"
//	static var kindKey = "kMDItemKind"
//	static var descriptionKey = "kMDItemDescription"
//	static var creationDateKey = "kMDItemFSCreationDate"
//	static var modificationDateKey = "kMDItemFSContentChangeDate"
//	static var whereFromsKey = "kMDItemWhereFroms"
//	static var copyrightKey = "kMDItemCopyright"
//	static var authorAddressesKey = "kMDItemAuthorAddresses"
//
//	// Image metadata
//
//	static var widthKey = "kMDItemPixelWidth"
//	static var heightKey = "kMDItemPixelHeight"
//	static var profileNameKey = "kMDItemProfileName"
//	static var modelKey = "kMDItemColorSpace"
//
//	static var exifApertureKey = "kMDItemAperture"
//	static var exifExposureTimeKey = "kMDItemExposureTimeSeconds"
//	static var exifFocalLengthKey = "kMDItemFocalLength35mm"
//	static var exifISOSpeedKey = "kMDItemISOSpeed"
//	static var exifCaptureDateKey = "DateTimeOriginal"
//
//	static var altitudeKey = "kMDItemAltitude"
//	static var latitudeKey = "kMDItemLatitude"
//	static var longitudeKey = "kMDItemLongitude"
//	static var locationNameKey = "kMDItemNamedLocation"
//
//	// Video metadata
//
//	static var codecsKey = "kMDItemCodecs"
//	static var videoCodecKey = "videoCodec"
//	static var audioCodecKey = "audioCodec"
//	static var videoBitRateKey = "kMDItemVideoBitRate"
//	static var audioBitRateKey = "kMDItemAudioBitRate"
//	static var fpsKey = "fps"
//
//	// Audio metadata
//
//	static var durationKey = "kMDItemDurationSeconds"
//	static var titleKey = "kMDItemTitle"
//	static var albumKey = "kMDItemAlbum"
//	static var authorsKey = "kMDItemAuthors"
//	static var composerKey = "kMDItemComposer"
//	static var genreKey = "kMDItemMusicalGenre"
//	static var tempoKey = "kMDItemTempo"
//	static var keySignatureKey = "kMDItemKeySignature"
//	static var timeSignatureKey = "kMDItemTimeSignature"
//	static var audioSampleRateKey = "kMDItemAudioSampleRate"
//	static var audioChannelCountKey = "kMDItemAudioChannelCount"
//}


//----------------------------------------------------------------------------------------------------------------------

