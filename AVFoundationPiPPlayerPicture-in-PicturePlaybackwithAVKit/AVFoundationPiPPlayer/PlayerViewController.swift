/*
	Copyright (C) 2015 Apple Inc. All Rights Reserved.
	See LICENSE.txt for this sample’s licensing information
	
	Abstract:
	PlayerViewController is a subclass of UIViewController which manages the UIView used for playback and also sets up AVPictureInPictureController for video playback in picture in picture.
*/

import AVFoundation
import UIKit
import AVKit

/*
	KVO context used to differentiate KVO callbacks for this class versus other
	classes in its class hierarchy.
*/
private var playerViewControllerKVOContext = 0

/*
    Manages the view used for playback and sets up the `AVPictureInPictureController`
    for video playback in picture in picture.
*/
class PlayerViewController: UIViewController, AVPictureInPictureControllerDelegate {
	// MARK: - Properties
	
	lazy var player = AVPlayer()
	
    var pictureInPictureController: AVPictureInPictureController!
	
	var playerView: PlayerView {
		return self.view as! PlayerView
	}
	
	var playerLayer: AVPlayerLayer? {
		return playerView.playerLayer
	}
	
	var playerItem: AVPlayerItem? = nil {
		didSet {
			/* 
				If needed, configure player item here before associating it with a player
				(example: adding outputs, setting text style rules, selecting media options)
			*/
			player.replaceCurrentItemWithPlayerItem(playerItem)
			
			if playerItem == nil {
				cleanUpPlayerPeriodicTimeObserver()
			}
			else {
				setupPlayerPeriodicTimeObserver()
			}
		}
	}
	
	var timeObserverToken: AnyObject?
	
	// Attempt to load and test these asset keys before playing
	static let assetKeysRequiredToPlay = [
		"playable",
		"hasProtectedContent"
	]
	
	var currentTime: Double {
		get {
			return CMTimeGetSeconds(player.currentTime())
		}
		
		set {
			let newTime = CMTimeMakeWithSeconds(newValue, 1)
			player.seekToTime(newTime, toleranceBefore: kCMTimeZero, toleranceAfter: kCMTimeZero)
		}
	}
	
	var duration: Double {
		guard let currentItem = player.currentItem else { return 0.0 }
		
		return CMTimeGetSeconds(currentItem.duration)
	}
	
	// MARK: - IBOutlets
	
	@IBOutlet weak var timeSlider: UISlider!
	@IBOutlet weak var playPauseButton: UIBarButtonItem!
	@IBOutlet weak var pictureInPictureButton: UIBarButtonItem!
	@IBOutlet weak var toolbar: UIToolbar!
	
	// MARK: - IBActions
	
	@IBAction func playPauseButtonWasPressed(sender: UIButton) {
		if player.rate != 1.0 {
			// Not playing foward, so play.
			
			if currentTime == duration {
				// At end, so got back to beginning.
				currentTime = 0.0
			}
			
			player.play()
		}
		else {
			// Playing, so pause.
			player.pause()
		}
	}
	
	@IBAction func togglePictureInPictureMode(sender: UIButton) {
		/*
			Toggle picture in picture mode.
		
			If active, stop picture in picture and return to inline playback.
		
			If not active, initiate picture in picture.
		
			Both these calls will trigger delegate callbacks which should be used
			to set up UI appropriate to the state of the application.
		*/
		if pictureInPictureController.pictureInPictureActive {
			pictureInPictureController.stopPictureInPicture()
		}
		else {
			pictureInPictureController.startPictureInPicture()
		}
	}
	
	@IBAction func timeSliderDidChange(sender: UISlider) {
		currentTime = Double(sender.value)
	}
	
	// MARK: - View Handling
	
	override func viewWillAppear(animated: Bool) {
		super.viewWillAppear(animated)
		
		/*
            Update the UI when these player properties change.
		
            Use the context parameter to distinguish KVO for our particular observers
			and not those destined for a subclass that also happens
			to be observing these properties.
		*/
		addObserver(self, forKeyPath: "player.currentItem.duration", options: [.New, .Initial], context: &playerViewControllerKVOContext)
		addObserver(self, forKeyPath: "player.rate", options: [.New, .Initial], context: &playerViewControllerKVOContext)
		addObserver(self, forKeyPath: "player.currentItem.status", options: [.New, .Initial], context: &playerViewControllerKVOContext)
		
		playerView.playerLayer.player = player
		
		setupPlayback()
		
		timeSlider.translatesAutoresizingMaskIntoConstraints = true
		timeSlider.autoresizingMask = .FlexibleWidth
		
		// Set the UIImage provided by AVPictureInPictureController as the image of the pictureInPictureButton
		let backingButton = pictureInPictureButton.customView as! UIButton
		backingButton.setImage(AVPictureInPictureController.pictureInPictureButtonStartImageCompatibleWithTraitCollection(nil), forState: UIControlState.Normal)
	}
	
	override func viewDidDisappear(animated: Bool) {
		super.viewDidDisappear(animated)
		
		player.pause()
		
		cleanUpPlayerPeriodicTimeObserver()
		
		removeObserver(self, forKeyPath: "player.currentItem.duration", context: &playerViewControllerKVOContext)
		removeObserver(self, forKeyPath: "player.rate", context: &playerViewControllerKVOContext)
		removeObserver(self, forKeyPath: "player.currentItem.status", context: &playerViewControllerKVOContext)
	}
	
	private func setupPlayback() {
		
		let movieURL = NSBundle.mainBundle().URLForResource("samplemovie", withExtension: "mov")!
		let asset = AVURLAsset(URL: movieURL, options: nil)
		/*
			Create a new `AVPlayerItem` and make it our player's current item.
		
			Using `AVAsset` now runs the risk of blocking the current thread (the
			main UI thread) whilst I/O happens to populate the properties. It's prudent
			to defer our work until the properties we need have been loaded.
		
			These properties can be passed in at initialization to `AVPlayerItem`,
			which are then loaded automatically by `AVPlayer`.
		*/
		self.playerItem = AVPlayerItem(asset: asset, automaticallyLoadedAssetKeys: PlayerViewController.assetKeysRequiredToPlay)
	}
	
	private func setupPlayerPeriodicTimeObserver() {
		// Only add the time observer if one hasn't been created yet.
		guard timeObserverToken == nil else { return }
		
		let time = CMTimeMake(1, 1)
		
		// Use a weak self variable to avoid a retain cycle in the block.
		timeObserverToken = player.addPeriodicTimeObserverForInterval(time, queue:dispatch_get_main_queue()) {
			[weak self] time in
			self?.timeSlider.value = Float(CMTimeGetSeconds(time))
		}
	}
	
	private func cleanUpPlayerPeriodicTimeObserver() {
		if let timeObserverToken = timeObserverToken {
			player.removeTimeObserver(timeObserverToken)
			self.timeObserverToken = nil
		}
	}
	
	private func setupPictureInPicturePlayback() {
		/*
			Check to make sure Picture in Picture is supported for the current
			setup (application configuration, hardware, etc.).
		*/
		if AVPictureInPictureController.isPictureInPictureSupported() {
			/*
				Create `AVPictureInPictureController` with our `playerLayer`.
				Set self as delegate to receive callbacks for picture in picture events.
				Add observer to be notified when pictureInPicturePossible changes value,
				so that we can enable `pictureInPictureButton`.
			*/
			pictureInPictureController = AVPictureInPictureController(playerLayer: playerView.playerLayer)
			pictureInPictureController.delegate = self
			
			addObserver(self, forKeyPath: "pictureInPictureController.pictureInPicturePossible", options: [.New, .Initial], context: &playerViewControllerKVOContext)
		}
		else {
			pictureInPictureButton.enabled = false
		}
	}
	
	// MARK: - AVPictureInPictureControllerDelegate
	
	func pictureInPictureControllerDidStartPictureInPicture(pictureInPictureController: AVPictureInPictureController) {
		/* 
			If your application contains a video library or other interesting views,
			this delegate callback can be used to dismiss player view controller
			and to present the user with a selection of videos to play next.
		*/
		toolbar.hidden = true
	}
	
	func pictureInPictureControllerWillStopPictureInPicture(pictureInPictureController: AVPictureInPictureController) {
		/* 
			Picture in picture mode will stop soon, show the toolbar.
		*/
		toolbar.hidden = false
	}
	
	func pictureInPictureControllerFailedToStartPictureInPicture(pictureInPictureController: AVPictureInPictureController, withError error: NSError) {
		/*
			Picture in picture failed to start with an error, restore UI to continue
			inline playback. Show the toolbar.
		*/
		toolbar.hidden = false
		handleError(error)
	}
	
	// MARK: - KVO
	
	// Update our UI when `player` or `player.currentItem` changes
    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
		// Only respond to KVO changes that are specific to this view controller class.
		guard context == &playerViewControllerKVOContext else {
           super.observeValueForKeyPath(keyPath, ofObject: object, change: change, context: context)
           return
		}
		
		if keyPath == "player.currentItem.duration" {
			// Update `timeSlider` and enable/disable controls when `duration` > 0.0
			
			/* 
				Handle `NSNull` value for `NSKeyValueChangeNewKey`, i.e. when
				`player.currentItem` is nil.
			*/
			let newDuration: CMTime
			if let newDurationAsValue = change?[NSKeyValueChangeNewKey] as? NSValue {
				newDuration = newDurationAsValue.CMTimeValue
			}
			else {
				newDuration = kCMTimeZero
			}
			let hasValidDuration = newDuration.isNumeric && newDuration.value != 0
			let newDurationSeconds = hasValidDuration ? CMTimeGetSeconds(newDuration) : 0.0
			
			timeSlider.maximumValue = Float(newDurationSeconds)
			
			let currentTime = CMTimeGetSeconds(player.currentTime())
			timeSlider.value = hasValidDuration ? Float(currentTime) : 0.0
			
			playPauseButton.enabled = hasValidDuration
			timeSlider.enabled = hasValidDuration
		}
		else if keyPath == "player.rate" {
			// Update playPauseButton type.
			let newRate = (change?[NSKeyValueChangeNewKey] as! NSNumber).doubleValue

			let style: UIBarButtonSystemItem = newRate == 0.0 ? .Play : .Pause
			let newPlayPauseButton = UIBarButtonItem(barButtonSystemItem: style, target: self, action: "playPauseButtonWasPressed:")
			
			// Replace the current button with the updated button in the toolbar.
			var items = toolbar.items!
			
			if let playPauseItemIndex = items.indexOf(playPauseButton) {
				items[playPauseItemIndex] = newPlayPauseButton
				
				playPauseButton = newPlayPauseButton
				
				toolbar.setItems(items, animated: false)
			}
		}
		else if keyPath == "player.currentItem.status" {
			// Display an error if status becomes Failed
			
			/* 
				Handle `NSNull` value for `NSKeyValueChangeNewKey`, i.e. when 
				`player.currentItem` is nil.
			*/
			let newStatus: AVPlayerItemStatus
			if let newStatusAsNumber = change?[NSKeyValueChangeNewKey] as? NSNumber {
				newStatus = AVPlayerItemStatus(rawValue: newStatusAsNumber.integerValue)!
			}
			else {
				newStatus = .Unknown
			}
			
			if newStatus == .Failed {
				handleError(player.currentItem?.error)
			}
			else if newStatus == .ReadyToPlay {
				
				if let asset = player.currentItem?.asset {
					
					/* 
						First test whether the values of `assetKeysRequiredToPlay` we need
						have been successfully loaded.
					*/
					for key in PlayerViewController.assetKeysRequiredToPlay {
						var error: NSError?
						if asset.statusOfValueForKey(key, error: &error) == .Failed {
							self.handleError(error!)
							return
						}
					}
					
					if !asset.playable || asset.hasProtectedContent {
						// We can't play this asset.
						self.handleError(nil)
						return
					}
					
					/*
						The player item is ready to play,
						setup picture in picture.
					*/
					if pictureInPictureController == nil {
						setupPictureInPicturePlayback()
					}
				}
			}
		}
		else if keyPath == "pictureInPictureController.pictureInPicturePossible" {
			/* 
				Enable the `pictureInPictureButton` only if `pictureInPicturePossible`
				is true. If this returns false, it might mean that the application
				was not configured as shown in the AppDelegate.
			*/
			let newValue = change?[NSKeyValueChangeNewKey] as! NSNumber
			let isPictureInPicturePossible: Bool = newValue.boolValue

			pictureInPictureButton.enabled = isPictureInPicturePossible
		}

	}
	
	// Trigger KVO for anyone observing our properties affected by player and player.currentItem
	override class func keyPathsForValuesAffectingValueForKey(key: String) -> Set<String> {
		let affectedKeyPathsMappingByKey: [String: Set<String>] = [
			"duration":     ["player.currentItem.duration"],
			"currentTime":  ["player.currentItem.currentTime"],
			"rate":         ["player.rate"]
		]
		
		return affectedKeyPathsMappingByKey[key] ?? super.keyPathsForValuesAffectingValueForKey(key)
	}
	
	// MARK: - Error Handling
	
	func handleError(error: NSError?) {
		let alertController = UIAlertController(title: "Error", message: error?.localizedDescription, preferredStyle: .Alert)
		
		let alertAction = UIAlertAction(title: "OK", style: .Default, handler: nil)
		
		alertController.addAction(alertAction)
		
		presentViewController(alertController, animated: true, completion: nil)
	}
}

