//**********************************************************************************************************************
//
//  AVAudioPlayer+Play.swift
//	Adds simple one-liner audio playback
//  Copyright ©2017 Peter Baumgartner. All rights reserved.
//
//**********************************************************************************************************************


import AVFoundation


//----------------------------------------------------------------------------------------------------------------------

    
public extension AVAudioPlayer
{
	/// One-liner method to asynchronously play a named audio file
	/// - parameter name: The name of the audio file
	/// - parameter bundle: The bundle containing the audio file

	public static func playAudio(named name:String, in bundle:Bundle = Bundle.main)
	{
		if let url = bundle.url(forResource:name,withExtension:nil)
		{
//			try? AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback)
//			try? AVAudioSession.sharedInstance().setActive(true)

			let audioPlayer = try? AVAudioPlayer(contentsOf:url)
			audioPlayer?.prepareToPlay()
			audioPlayer?.play()
		}
	}
}


//----------------------------------------------------------------------------------------------------------------------
