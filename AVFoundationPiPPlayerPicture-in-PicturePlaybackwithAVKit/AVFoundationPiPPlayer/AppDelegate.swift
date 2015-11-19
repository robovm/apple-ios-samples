/*
	Copyright (C) 2015 Apple Inc. All Rights Reserved.
	See LICENSE.txt for this sample’s licensing information
	
	Abstract:
	Main entry point to the application which sets up AVAudioSession for picture in picture.
*/

import UIKit
import AVFoundation

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
	// MARK: Properties
	
	var window: UIWindow?
	
	func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
		/* 
			Setup audio session for picture in picture playback.
			Application has to be configured correctly to be able to initiate picture in picture.
			This configuration involves:
			
			1. Setting UIBackgroundMode to audio under the project settings.
		
			2. Setting audio session category to AVAudioSessionCategoryPlayback or AVAudioSessionCategoryPlayAndRecord (as appropriate)
		
			If an application is not configured correctly, AVPictureInPictureController.pictureInPicturePossible
			returns false.
		*/
		let audioSession = AVAudioSession.sharedInstance()

		do {
			try audioSession.setCategory(AVAudioSessionCategoryPlayback)
		}
		catch {
			print("Audio session setCategory failed")
		}

		return true
	}
}
