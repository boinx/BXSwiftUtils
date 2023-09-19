//**********************************************************************************************************************
//
//  URL+Metadata.swift
//	Media file metadata
//  Copyright ©2020 Peter Baumgartner. All rights reserved.
//
//**********************************************************************************************************************


import Foundation
import AVFoundation
import CoreSpotlight

#if canImport(UniformTypeIdentifiers)
import UniformTypeIdentifiers
#endif

#if canImport(MobileCoreServices)
import MobileCoreServices
#endif



//----------------------------------------------------------------------------------------------------------------------


public extension URL
{
	/// Returns true if this is an image file
	
	var isImageFile:Bool
	{
		guard let uti = self.uti else { return false }
		return UTTypeConformsTo(uti as CFString, kUTTypeImage)
	}

	/// Returns true if this is an audio file
	
	var isAudioFile:Bool
	{
		guard let uti = self.uti else { return false }
		return UTTypeConformsTo(uti as CFString, kUTTypeAudio)
	}
	
	/// Returns true if this is a video file
	
	var isVideoFile:Bool
	{
		guard let uti = self.uti else { return false }
		return UTTypeConformsTo(uti as CFString, kUTTypeMovie)
	}

    /// Returns true if the file at the specified URL is an Apple Loop file that cannot be used because it is
	/// incomplete, e.g. because it has not been fully downloaded yet.
	
    var isCorruptedAppleLoopFile:Bool
    {
		// Is this a caf file in "Library/Audio/Apple Loops/"
		
		guard self.pathExtension == "caf" else { return false }
		guard self.path.contains("Apple Loops") else { return false }
		
		// The check for file size < 30K is reasonable fast, but of course it is by no means reliable!
		
		// Looks like the file size correlates with the audio duration, e.g. a 10s loop has approximately 10K bytes
		// file size. This would be a more reliable check, but then we would have to get the audio duration, which
		// is too expensive a t this point.
		
		let size = self.fileSize ?? 0
		return size < 30000
    }
}


//----------------------------------------------------------------------------------------------------------------------


// MARK: -

public extension URL
{

	/// Returns metadata for an image file
	
	var imageMetadata:[CFString:Any]
	{
		guard let source = CGImageSourceCreateWithURL(self as CFURL,nil) else { return [:] }
		guard let properties = CGImageSourceCopyPropertiesAtIndex(source,0,nil) else { return [:] }
		
		let spotlight = self.spotlightMetadata(for:[kMDItemFSSize,kMDItemFSCreationDate])

		var metadata = properties as? [CFString:Any] ?? [:]
		metadata[kMDItemFSSize] = spotlight[kMDItemFSSize]
		metadata[kMDItemFSCreationDate] = spotlight[kMDItemFSCreationDate]
		return metadata
	}


	/// Returns metadata for an audio file
	
	var audioMetadata:[CFString:Any]
	{
		// First gather all metadata we can find
		
		let keys:[CFString] =
		[
			kMDItemDurationSeconds,
			kMDItemTitle,
			kMDItemAuthors,
			kMDItemComposer,
			kMDItemAlbum,
			kMDItemWhereFroms,
			kMDItemCopyright,
			kMDItemMusicalGenre,
			kMDItemAudioBitRate,
			kMDItemAudioChannelCount,
			kMDItemAudioSampleRate,
			kMDItemTempo,
			kMDItemKeySignature,
			kMDItemTimeSignature,
			kMDItemKind,
			kMDItemComment,
			kMDItemFSSize
		]
		
		let spotlight = self.spotlightMetadata(for:keys)
		let asset = AVURLAsset(url:self)
		let common = asset.commonMetadata
		let id3 = asset.metadata(forFormat:.id3Metadata)
		
		// Duration
		
		var duration:Double? = nil
		
		if duration == nil
		{
			duration = spotlight[kMDItemDurationSeconds] as? Double
		}

//		if duration == nil
//		{
//			duration = self.values(from:id3, key:AVMetadataID3MetadataKeyTime, space:AVMetadataKeySpaceID3).first
//		}

		if duration == nil
		{
			duration = CMTimeGetSeconds(asset.duration)
		}
		
		// Title
		
		var title:String? = nil
		
		if title == nil
		{
			title = self.values(from:id3, key:AVMetadataKey.id3MetadataKeyTitleDescription, space:AVMetadataKeySpace.id3).first
		}
		
		if title == nil
		{
			title = self.values(from:common, key:AVMetadataKey.commonKeyTitle, space:AVMetadataKeySpace.common).first
		}
		
		if title == nil
		{
			title = spotlight[kMDItemTitle] as? String
		}

		// Comment
	
		var comment:String? = nil
		
		if comment == nil
		{
			comment = spotlight[kMDItemComment] as? String
		}

		if comment == nil
		{
			comment = self.values(from:id3, key:AVMetadataKey.id3MetadataKeyComments, space:AVMetadataKeySpace.id3).first
		}

		// Authors
		
		var authors:[String] = []
		
		authors += (spotlight[kMDItemAuthors] as? [String]) ?? []
		authors += self.values(from:common, key:AVMetadataKey.commonKeyArtist, space:AVMetadataKeySpace.common)
		authors += self.values(from:common, key:AVMetadataKey.commonKeyAuthor, space:AVMetadataKeySpace.common)
		authors += self.values(from:common, key:AVMetadataKey.commonKeyCreator, space:AVMetadataKeySpace.common)
		authors += self.values(from:id3, key:AVMetadataKey.id3MetadataKeyOriginalArtist, space:AVMetadataKeySpace.id3)
		authors += self.values(from:id3, key:AVMetadataKey.id3MetadataKeyLeadPerformer, space:AVMetadataKeySpace.id3)
		authors += self.values(from:id3, key:AVMetadataKey.id3MetadataKeyBand, space:AVMetadataKeySpace.id3)
		
		// Composer

		var composer:String? = nil
		
		if composer == nil
		{
			composer = spotlight[kMDItemComposer] as? String
		}
		
		if composer == nil
		{
			composer = self.values(from:id3, key:AVMetadataKey.id3MetadataKeyComposer, space:AVMetadataKeySpace.id3).first
		}
		
		// Album

		var album:String? = nil
		
		if album == nil
		{
			album = spotlight[kMDItemAlbum] as? String
		}

		if album == nil
		{
			album = self.values(from:common, key:AVMetadataKey.commonKeyAlbumName, space:AVMetadataKeySpace.common).first
		}

		if album == nil
		{
			album = self.values(from:id3, key:AVMetadataKey.id3MetadataKeyAlbumTitle, space:AVMetadataKeySpace.id3).first
		}

		if album == nil
		{
			album = self.values(from:id3, key:AVMetadataKey.id3MetadataKeyOriginalAlbumTitle, space:AVMetadataKeySpace.id3).first
		}

		// Copyright
		
		var copyright:String? = nil
		
		if copyright == nil
		{
			copyright = spotlight[kMDItemCopyright] as? String
		}
		
		if copyright == nil
		{
			copyright = self.values(from:id3, key:AVMetadataKey.id3MetadataKeyCopyright, space:AVMetadataKeySpace.id3).first
		}
		
		// URLs
		
		var urls:[String] = [] //? = nil
		
		urls += spotlight[kMDItemWhereFroms] as? [String] ?? []
		urls += self.values(from:id3, key:AVMetadataKey.id3MetadataKeyOfficialAudioFileWebpage, space:AVMetadataKeySpace.id3)
		urls += self.values(from:id3, key:AVMetadataKey.id3MetadataKeyOfficialArtistWebpage, space:AVMetadataKeySpace.id3)
		urls += self.values(from:id3, key:AVMetadataKey.id3MetadataKeyOfficialPublisherWebpage, space:AVMetadataKeySpace.id3)

		if urls.isEmpty
		{
			urls += URL.extract(from:comment ?? "")?.absoluteString
		}
		
		if urls.isEmpty
		{
			urls += URL.extract(from:copyright ?? "")?.absoluteString
		}

		// Genre
		
		var genre:String? = nil
		
		if genre == nil
		{
			genre = spotlight[kMDItemMusicalGenre] as? String
		}

		if genre == nil
		{
			genre = self.values(from:id3, key:AVMetadataKey.id3MetadataKeyContentType, space:AVMetadataKeySpace.id3).first
		}

		// BPM
		
		var bpm:String? = nil
		
		if bpm == nil
		{
			bpm = spotlight[kMDItemTempo] as? String
		}
		
		if bpm == nil
		{
			bpm = self.values(from:id3, key:AVMetadataKey.id3MetadataKeyBeatsPerMinute, space:AVMetadataKeySpace.id3).first
		}
		
		// Key signature
		
		var keySignature:String? = nil
		
		if keySignature == nil
		{
			keySignature = spotlight[kMDItemKeySignature] as? String
		}
		
		// Time signature
		
		var timeSignature:String? = nil
		
		if timeSignature == nil
		{
			timeSignature = spotlight[kMDItemTimeSignature] as? String
		}
		
		if timeSignature == nil
		{
			let tmp = (comment ?? "").lowercased().replacingOccurrences(of:" ", with:"")
			let matches = tmp.regexMatches(for:"meter:[234567]/[468]")
			if let match = matches.first
			{
				timeSignature = match.replacingOccurrences(of:"meter:", with:"")
			}
		}

		// Bitrate
		
		var bitrate:Int? = nil
		
		if bitrate == nil
		{
			bitrate = spotlight[kMDItemAudioBitRate] as? Int
		}
		
		// Samplerate
		
		var samplerate:Int? = nil
		
		if samplerate == nil
		{
			samplerate = spotlight[kMDItemAudioSampleRate] as? Int
		}
		
		// Channels
		
		var channels:Int? = nil
		
		if channels == nil
		{
			channels = spotlight[kMDItemAudioChannelCount] as? Int
		}

		// File size
		
		var size:Int? = nil
		
		if size == nil
		{
			size = spotlight[kMDItemFSSize] as? Int
		}
	
		// Build metadata dictionary
		
		var metadata:[CFString:Any] = [:]
		metadata[kMDItemDurationSeconds] = duration
		metadata[kMDItemTitle] = title
		metadata[kMDItemComment] = comment
		metadata[kMDItemAuthors] = authors
		metadata[kMDItemComposer] = composer
		metadata[kMDItemAlbum] = album
		metadata[kMDItemWhereFroms] = urls
		metadata[kMDItemCopyright] = copyright
		metadata[kMDItemMusicalGenre] = genre
		metadata[kMDItemTempo] = bpm
		metadata[kMDItemKeySignature] = keySignature
		metadata[kMDItemTimeSignature] = timeSignature
		metadata[kMDItemAudioChannelCount] = channels
		metadata[kMDItemAudioBitRate] = bitrate
		metadata[kMDItemAudioSampleRate] = samplerate
		metadata[kMDItemFSSize] = size
		return metadata
	}


	/// Returns the duration of an audio file
	
	var audioDuration:Double
	{
		let asset = AVURLAsset(url:self)
		guard let track = asset.tracks(withMediaType:AVMediaType.audio).first else { return 0.0 }
		return CMTimeGetSeconds(CMTimeRangeGetEnd(track.timeRange))
	}
	
	var duration:Double
	{
		let asset = AVURLAsset(url:self)
		return CMTimeGetSeconds(asset.duration)
	}
	
	
//----------------------------------------------------------------------------------------------------------------------


	/// Returns metadata for an audio file
	
	var videoMetadata:[CFString:Any]
	{
		// First gather all metadata we can find
		
		let keys:[CFString] =
		[
			kMDItemDurationSeconds,
			kMDItemFSSize,
			kMDItemKind,
			kMDItemCodecs,
			kMDItemContentCreationDate
		]
		
		let spotlight = self.spotlightMetadata(for:keys)
		let asset = AVURLAsset(url:self)
		let videoTrack = asset.tracks(withMediaType:.video).first
		
		// Extract info
		
		var duration:Double? = nil
		var width:Int? = nil
		var height:Int? = nil
		var fps:Double? = nil
		var kind:String? = nil
		var videoCodec:AVFoundation.AVVideoCodecType? = nil
		var audioCodec:AudioFormatID? = nil
		var codecs:[String]? = nil
		var size:Int? = nil
		
		if duration == nil
		{
			duration = CMTimeGetSeconds(asset.duration)
		}
		
		if duration == nil
		{
			duration = spotlight[kMDItemDurationSeconds] as? Double
		}

		if let videoTrack = videoTrack
		{
			let size = videoTrack.naturalSize
			width = Int(size.width)
			height = Int(size.height)
			fps = Double(videoTrack.nominalFrameRate)
		}
		
		if kind == nil
		{
			kind = spotlight[kMDItemKind] as? String
		}
	
		if videoCodec == nil
		{
			if let formatDescriptions = videoTrack?.formatDescriptions as? [CMFormatDescription],
			   let formatDescription = formatDescriptions.first,
			   let name = CMFormatDescriptionGetExtension(formatDescription, extensionKey:kCMFormatDescriptionExtension_FormatName) as? String
			{
				let code = name.replacingOccurrences(of:"\'", with:"")	// IMPORTANT: we get "'avc1'" so we need to strip the single quotes!
				videoCodec = AVFoundation.AVVideoCodecType(rawValue:code)
			}
		}
		
		if audioCodec == nil
		{
			if let audioTrack = asset.tracks(withMediaType:.audio).first,
			   let formatDescriptions = audioTrack.formatDescriptions as? [CMFormatDescription],
			   let formatDescription = formatDescriptions.first
			{
				audioCodec = CMFormatDescriptionGetMediaSubType(formatDescription)
			}
		}
		
		if codecs == nil
		{
			codecs = spotlight[kMDItemCodecs] as? [String]
		}

		if codecs == nil
		{
			var formatNameVideo = ""
			var formatNameAudio = ""
			
			if let formatDescriptions = videoTrack?.formatDescriptions as? [CMFormatDescription],
			   let formatDescription = formatDescriptions.first,
			   let name = CMFormatDescriptionGetExtension(formatDescription,extensionKey:kCMFormatDescriptionExtension_FormatName) as? String
			{
				formatNameVideo = name
			}

			if let audioTrack = asset.tracks(withMediaType:.audio).first,
			   let formatDescriptions = audioTrack.formatDescriptions as? [CMFormatDescription],
			   let formatDescription = formatDescriptions.first,
			   let name = CMFormatDescriptionGetExtension(formatDescription,extensionKey:kCMFormatDescriptionExtension_FormatName) as? String
			{
				formatNameAudio = name
//				let code = CMFormatDescriptionGetMediaSubType(formatDescription)
//
//				switch code
//				{
//					case kAudioFormatMPEG4AAC: formatNameAudio = "AAC"
//					case kAudioFormatLinearPCM: formatNameAudio = "Linear PCM"
//					case kAudioFormatAppleLossless: formatNameAudio = "Apple Lossless"
//					case kAudioFormatAC3: formatNameAudio = "AC-3"
//					case kAudioFormatMPEGLayer1: formatNameAudio = "MPEG-1"
//					case kAudioFormatMPEGLayer2: formatNameAudio = "MPEG-2"
//					case kAudioFormatMPEGLayer3: formatNameAudio = "MPEG-3"
//					default: break
//				}
			}

			codecs = [formatNameVideo,formatNameAudio]
		}

		if size == nil
		{
			size = spotlight[kMDItemFSSize] as? Int
		}
	
		// Build metadata dictionary
		
		var metadata:[CFString:Any] = [:]
		metadata[kMDItemPixelWidth] = width
		metadata[kMDItemPixelHeight] = height
		metadata[kMDItemDurationSeconds] = duration
		metadata[kMDItemFSSize] = size
		metadata[kMDItemKind] = kind
		metadata[kMDItemCodecs] = codecs
		metadata[kMDItemFSSize] = size
		metadata["fps" as CFString] = fps
		metadata["videoCodec" as CFString] = videoCodec
		metadata["audioCodec" as CFString] = audioCodec
		metadata[kMDItemContentCreationDate] = spotlight[kMDItemContentCreationDate] as? Date
		return metadata
	}
}
	
	
//----------------------------------------------------------------------------------------------------------------------


// MARK: -

public extension URL
{
	/// Helper function to load metadata via Spotlight
	
	func spotlightMetadata(for keys:[CFString]) -> [CFString:Any]
	{
		var metadata:[CFString:Any] = [:]

		#if os(macOS)

		if #available(macOS 13, *)
		{
			#warning("FIXME: Remove this when bug in Ventura is fixed!")
			// Skip this due to a bug in early Ventura betas - blocks for 10s and then fails
		}
		else
		{
			//log.error {"\(Self.self).\(#function) MDItemCreateWithURL"}
			guard let item = MDItemCreateWithURL(nil,self as CFURL) else { return metadata }
			//log.error {"\(Self.self).\(#function) MDItemCopyAttributes"}
			guard let attributes = MDItemCopyAttributes(item,keys as CFArray) as? [CFString:Any] else { return metadata }
			//log.error {"\(Self.self).\(#function) attributes.count = \(attributes.count)"}

			for (key,value) in attributes
			{
				metadata[key] = value
			}
		}

		#endif
		
		return metadata
	}
	
	/// Helper function to extract values from an array of AVMetadataItems
	
	func values(from items:[AVMetadataItem], key:AVMetadataKey, space:AVMetadataKeySpace) -> [String]
	{
		return AVMetadataItem.metadataItems(from:items, withKey:key, keySpace:space).compactMap
		{
			$0.stringValue
		}
	}
	
	static func extract(from string:String) -> URL?
	{
		// Regular expression pattern to match URLs
		
		let pattern = #"https?://[-\w.]+(:\d+)?(/([\w/_.]*)?)?"#
    
		do
		{
			let regex = try NSRegularExpression(pattern:pattern, options:[])
			let nsString = string as NSString
			let range = NSRange(location:0, length:nsString.length)
			
			if let match = regex.firstMatch(in:string, options:[], range:range)
			{
				let matchedString = nsString.substring(with:match.range)
				
				if let url = URL(string:matchedString)
				{
					return url
				}
			}
		}
		catch
		{
			print("Error creating regular expression: \(error.localizedDescription)")
		}
		
		return nil
	}

}


//----------------------------------------------------------------------------------------------------------------------
