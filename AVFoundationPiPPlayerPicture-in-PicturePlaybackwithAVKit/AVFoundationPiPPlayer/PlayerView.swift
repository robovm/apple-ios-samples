/*
	Copyright (C) 2015 Apple Inc. All Rights Reserved.
	See LICENSE.txt for this sample’s licensing information
	
	Abstract:
	Player view  is a subclass of UIView used for playback.
*/

import UIKit
import AVFoundation

class PlayerView: UIView {
	// MARK: Properties
	
	var player: AVPlayer? {
		get {
			return playerLayer.player
		}
		
		set {
			playerLayer.player = newValue
		}
	}
	
	var playerLayer: AVPlayerLayer {
		return layer as! AVPlayerLayer
	}
	
	override class func layerClass() -> AnyClass {
		return AVPlayerLayer.self
	}
}
