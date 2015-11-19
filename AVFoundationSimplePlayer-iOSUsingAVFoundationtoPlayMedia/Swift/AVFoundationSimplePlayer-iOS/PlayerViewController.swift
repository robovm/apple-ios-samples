/*
	Copyright (C) 2015 Apple Inc. All Rights Reserved.
	See LICENSE.txt for this sample’s licensing information
	
	Abstract:
	View controller containing a player view and basic playback controls.
*/

import Foundation
import AVFoundation
import UIKit

/*
	KVO context used to differentiate KVO callbacks for this class versus other
	classes in its class hierarchy.
*/
private var playerViewControllerKVOContext = 0

class PlayerViewController: UIViewController {
    // MARK: Properties
    
    // Attempt load and test these asset keys before playing.
    static let assetKeysRequiredToPlay = [
        "playable",
        "hasProtectedContent"
    ]

	let player = AVPlayer()

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

	var rate: Float {
		get {
            return player.rate
        }

        set {
            player.rate = newValue
        }
	}

    var asset: AVURLAsset? {
        didSet {
            guard let newAsset = asset else { return }

            asynchronouslyLoadURLAsset(newAsset)
        }
    }
    
	private var playerLayer: AVPlayerLayer? {
        return playerView.playerLayer
    }

    /*
        A token obtained from calling `player`'s `addPeriodicTimeObserverForInterval(_:queue:usingBlock:)`
        method.
    */
	private var timeObserverToken: AnyObject?

	private var playerItem: AVPlayerItem? = nil {
        didSet {
            /*
                If needed, configure player item here before associating it with a player.
                (example: adding outputs, setting text style rules, selecting media options)
            */
            player.replaceCurrentItemWithPlayerItem(self.playerItem)
        }
	}

    // MARK: - IBOutlets
    
    @IBOutlet weak var timeSlider: UISlider!
    @IBOutlet weak var startTimeLabel: UILabel!
    @IBOutlet weak var durationLabel: UILabel!
    @IBOutlet weak var rewindButton: UIButton!
    @IBOutlet weak var playPauseButton: UIButton!
    @IBOutlet weak var fastForwardButton: UIButton!
    @IBOutlet weak var playerView: PlayerView!
    
    // MARK: - View Controller
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        /*
            Update the UI when these player properties change.
        
            Use the context parameter to distinguish KVO for our particular observers 
            and not those destined for a subclass that also happens to be observing 
            these properties.
        */
        addObserver(self, forKeyPath: "player.currentItem.duration", options: [.New, .Initial], context: &playerViewControllerKVOContext)
        addObserver(self, forKeyPath: "player.rate", options: [.New, .Initial], context: &playerViewControllerKVOContext)
        addObserver(self, forKeyPath: "player.currentItem.status", options: [.New, .Initial], context: &playerViewControllerKVOContext)
        
        playerView.playerLayer.player = player
        
        let movieURL = NSBundle.mainBundle().URLForResource("ElephantSeals", withExtension: "mov")!
        asset = AVURLAsset(URL: movieURL, options: nil)
        
        // Make sure we don't have a strong reference cycle by only capturing self as weak.
        let interval = CMTimeMake(1, 1)
        timeObserverToken = player.addPeriodicTimeObserverForInterval(interval, queue: dispatch_get_main_queue()) {
            [weak self] time in
            self?.timeSlider.value = Float(CMTimeGetSeconds(time))
        }
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        
        if let timeObserverToken = timeObserverToken {
            player.removeTimeObserver(timeObserverToken)
            self.timeObserverToken = nil
        }
        
        player.pause()
        
        removeObserver(self, forKeyPath: "player.currentItem.duration", context: &playerViewControllerKVOContext)
        removeObserver(self, forKeyPath: "player.rate", context: &playerViewControllerKVOContext)
        removeObserver(self, forKeyPath: "player.currentItem.status", context: &playerViewControllerKVOContext)
    }
    
    // MARK: - Asset Loading

    func asynchronouslyLoadURLAsset(newAsset: AVURLAsset) {
        /*
            Using AVAsset now runs the risk of blocking the current thread (the 
            main UI thread) whilst I/O happens to populate the properties. It's
            prudent to defer our work until the properties we need have been loaded.
        */
        newAsset.loadValuesAsynchronouslyForKeys(PlayerViewController.assetKeysRequiredToPlay) {
            /*
                The asset invokes its completion handler on an arbitrary queue. 
                To avoid multiple threads using our internal state at the same time 
                we'll elect to use the main thread at all times, let's dispatch
                our handler to the main queue.
            */
            dispatch_async(dispatch_get_main_queue()) {
                /*
                    `self.asset` has already changed! No point continuing because
                    another `newAsset` will come along in a moment.
                */
                guard newAsset == self.asset else { return }

                /*
                    Test whether the values of each of the keys we need have been
                    successfully loaded.
                */
                for key in PlayerViewController.assetKeysRequiredToPlay {
                    var error: NSError?
                    
                    if newAsset.statusOfValueForKey(key, error: &error) == .Failed {
                        let stringFormat = NSLocalizedString("error.asset_key_%@_failed.description", comment: "Can't use this AVAsset because one of it's keys failed to load")

                        let message = String.localizedStringWithFormat(stringFormat, key)
                        
                        self.handleErrorWithMessage(message, error: error)
                        
                        return
                    }
                }
                
                // We can't play this asset.
                if !newAsset.playable || newAsset.hasProtectedContent {
                    let message = NSLocalizedString("error.asset_not_playable.description", comment: "Can't use this AVAsset because it isn't playable or has protected content")
                    
                    self.handleErrorWithMessage(message)
                    
                    return
                }
                
                /*
                    We can play this asset. Create a new `AVPlayerItem` and make
                    it our player's current item.
                */
                self.playerItem = AVPlayerItem(asset: newAsset)
            }
        }
    }

    // MARK: - IBActions

	@IBAction func playPauseButtonWasPressed(sender: UIButton) {
		if player.rate != 1.0 {
            // Not playing forward, so play.
 			if currentTime == duration {
                // At end, so got back to begining.
				currentTime = 0.0
			}

			player.play()
		}
        else {
            // Playing, so pause.
			player.pause()
		}
	}
	
	@IBAction func rewindButtonWasPressed(sender: UIButton) {
        // Rewind no faster than -2.0.
        rate = max(player.rate - 2.0, -2.0)
	}
	
	@IBAction func fastForwardButtonWasPressed(sender: UIButton) {
        // Fast forward no faster than 2.0.
        rate = min(player.rate + 2.0, 2.0)
	}

    @IBAction func timeSliderDidChange(sender: UISlider) {
        currentTime = Double(sender.value)
    }
    
    // MARK: - KVO Observation

    // Update our UI when player or `player.currentItem` changes.
    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String: AnyObject]?, context: UnsafeMutablePointer<Void>) {
        // Make sure the this KVO callback was intended for this view controller.
        guard context == &playerViewControllerKVOContext else {
            super.observeValueForKeyPath(keyPath, ofObject: object, change: change, context: context)
            return
        }

        if keyPath == "player.currentItem.duration" {
            // Update timeSlider and enable/disable controls when duration > 0.0

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

            timeSlider.value = hasValidDuration ? Float(CMTimeGetSeconds(player.currentTime())) : 0.0
            
            rewindButton.enabled = hasValidDuration
            
            playPauseButton.enabled = hasValidDuration
            
            fastForwardButton.enabled = hasValidDuration
            
            timeSlider.enabled = hasValidDuration
            
            startTimeLabel.enabled = hasValidDuration
            
            durationLabel.enabled = hasValidDuration
            
            // FIXME: Should use NSDateFormatter?
            let wholeMinutes = Int(trunc(newDurationSeconds / 60))

            durationLabel.text = String(format:"%d:%02d", wholeMinutes, Int(trunc(newDurationSeconds)) - wholeMinutes * 60)
        }
        else if keyPath == "player.rate" {
            // Update `playPauseButton` image.

            let newRate = (change?[NSKeyValueChangeNewKey] as! NSNumber).doubleValue
            
            let buttonImageName = newRate == 1.0 ? "PauseButton" : "PlayButton"
            
            let buttonImage = UIImage(named: buttonImageName)

            playPauseButton.setImage(buttonImage, forState: .Normal)
        }
        else if keyPath == "player.currentItem.status" {
            // Display an error if status becomes `.Failed`.

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
                handleErrorWithMessage(player.currentItem?.error?.localizedDescription, error:player.currentItem?.error)
            }
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

	func handleErrorWithMessage(message: String?, error: NSError? = nil) {
        NSLog("Error occured with message: \(message), error: \(error).")
    
        let alertTitle = NSLocalizedString("alert.error.title", comment: "Alert title for errors")
        let defaultAlertMessage = NSLocalizedString("error.default.description", comment: "Default error message when no NSError provided")

        let alert = UIAlertController(title: alertTitle, message: message == nil ? defaultAlertMessage : message, preferredStyle: UIAlertControllerStyle.Alert)

        let alertActionTitle = NSLocalizedString("alert.error.actions.OK", comment: "OK on error alert")

        let alertAction = UIAlertAction(title: alertActionTitle, style: .Default, handler: nil)
        
        alert.addAction(alertAction)

        presentViewController(alert, animated: true, completion: nil)
	}
}