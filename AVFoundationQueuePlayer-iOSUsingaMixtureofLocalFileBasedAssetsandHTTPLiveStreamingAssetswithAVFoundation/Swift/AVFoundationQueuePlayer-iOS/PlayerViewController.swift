/*
	Copyright (C) 2015 Apple Inc. All Rights Reserved.
	See LICENSE.txt for this sample’s licensing information
	
	Abstract:
	View controller containing a player view, collection view showing the AVQueuePlayer content and basic playback controls.
*/

import UIKit
import AVFoundation

/*
    KVO context used to differentiate KVO callbacks for this class versus other
    classes in its class hierarchy.
*/
private var playerViewControllerKVOContext = 0

class PlayerViewController: UIViewController, UICollectionViewDataSource {
    // MARK: Properties
    
    // Attempt load and test these asset keys before playing.
    static let assetKeysRequiredToPlay = [
        "playable",
        "hasProtectedContent"
    ]

    let player = AVQueuePlayer()

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
    
    var playerLayer: AVPlayerLayer? {
        return playerView.playerLayer
    }
    
    /*
        A formatter for individual date components used to provide an appropriate
        value for the `startTimeLabel` and `durationLabel`.
    */
    let timeRemainingFormatter: NSDateComponentsFormatter = {
        let formatter = NSDateComponentsFormatter()
        formatter.zeroFormattingBehavior = .Pad
        formatter.allowedUnits = [.Minute, .Second]
        
        return formatter
    }()
    
    /*
        A token obtained from calling `player`'s `addPeriodicTimeObserverForInterval(_:queue:usingBlock:)`
        method.
    */
    var timeObserverToken: AnyObject?
    
    var assetTitlesAndThumbnails: [NSURL: (title: String, thumbnail: UIImage)] = [:]
    
    var loadedAssets = [String: AVURLAsset]()
    
    // MARK: IBOutlets
    
    @IBOutlet weak var timeSlider: UISlider!
    @IBOutlet weak var startTimeLabel: UILabel!
    @IBOutlet weak var durationLabel: UILabel!
    @IBOutlet weak var rewindButton: UIButton!
    @IBOutlet weak var playPauseButton: UIButton!
    @IBOutlet weak var fastForwardButton: UIButton!
    @IBOutlet weak var clearButton: UIButton!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var queueLabel: UILabel!
    @IBOutlet weak var playerView: PlayerView!

    // MARK: View Controller
	
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
		addObserver(self, forKeyPath: "player.currentItem", options: [.New, .Initial], context: &playerViewControllerKVOContext)

        playerView.playerLayer.player = player

        /*
            Read the list of assets we'll be using from a JSON file.
        */
        let manifestURL = NSBundle.mainBundle().URLForResource("MediaManifest", withExtension: "json")!
        asynchronouslyLoadURLAssetsWithManifestURL(manifestURL)
        
        // Make sure we don't have a strong reference cycle by only capturing self as weak.
        let interval = CMTimeMake(1, 1)
        timeObserverToken = player.addPeriodicTimeObserverForInterval(interval, queue: dispatch_get_main_queue()) { [unowned self] time in
            let timeElapsed = Float(CMTimeGetSeconds(time))
            
            self.timeSlider.value = Float(timeElapsed)
            self.startTimeLabel.text = self.createTimeString(timeElapsed)
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
        removeObserver(self, forKeyPath: "player.currentItem", context: &playerViewControllerKVOContext)
	}
    
    // MARK: Asset Loading
    
    /*
        Prepare an AVAsset for use on a background thread. When the minimum set 
        of properties we require (`assetKeysRequiredToPlay`) are loaded then add
        the asset to the `assetTitlesAndThumbnails` dictionary. We'll use that 
        dictionary to populate the "Add Item" button popover.
    */
    func asynchronouslyLoadURLAsset(asset: AVURLAsset, title: String, thumbnailResourceName: String) {
        /*
            Using AVAsset now runs the risk of blocking the current thread (the
            main UI thread) whilst I/O happens to populate the properties. It's 
            prudent to defer our work until the properties we need have been loaded.
        */
        asset.loadValuesAsynchronouslyForKeys(PlayerViewController.assetKeysRequiredToPlay) {

            /*
                The asset invokes its completion handler on an arbitrary queue.
                To avoid multiple threads using our internal state at the same time
                we'll elect to use the main thread at all times, let's dispatch
                our handler to the main queue.
            */
            dispatch_async(dispatch_get_main_queue()) {
                /*
                    This method is called when the `AVAsset` for our URL has 
                    completed the loading of the values of the specified array 
                    of keys.
                */
                
                /*
                    Test whether the values of each of the keys we need have been
                    successfully loaded.
                */
                for key in PlayerViewController.assetKeysRequiredToPlay {
                    var error: NSError?

                    if asset.statusOfValueForKey(key, error: &error) == .Failed {
                        let stringFormat = NSLocalizedString("error.asset_%@_key_%@_failed.description", comment: "Can't use this AVAsset because one of it's keys failed to load")

                        let message = String.localizedStringWithFormat(stringFormat, title, key)

                        self.handleErrorWithMessage(message, error: error)

                        return
                    }
                }

                // We can't play this asset.
                if !asset.playable || asset.hasProtectedContent {
                    let stringFormat = NSLocalizedString("error.asset_%@_not_playable.description", comment: "Can't use this AVAsset because it isn't playable or has protected content")
                    
                    let message = String.localizedStringWithFormat(stringFormat, title)

                    self.handleErrorWithMessage(message)

                    return
                }

                /*
                    We can play this asset. Create a new AVPlayerItem and make it
                    our player's current item.
                */
                self.loadedAssets[title] = asset

                let name = (thumbnailResourceName as NSString).stringByDeletingPathExtension
                let type = (thumbnailResourceName as NSString).pathExtension
                let path = NSBundle.mainBundle().pathForResource(name, ofType: type)!

                let thumbnail = UIImage(contentsOfFile: path)!
                
                self.assetTitlesAndThumbnails[asset.URL] = (title, thumbnail)
            }
        }
    }

    /*
        Read the asset URLs, titles and thumbnail resource names from a JSON manifest
        file - then load each asset.
    */
    func asynchronouslyLoadURLAssetsWithManifestURL(jsonURL: NSURL!) {
        var assetsJSON = [[String: AnyObject]]()

        if let jsonData = NSData(contentsOfURL: jsonURL) {
            do {
                try assetsJSON = NSJSONSerialization.JSONObjectWithData(jsonData, options: []) as! [[String: AnyObject]]
            }
            catch {
                let message = NSLocalizedString("error.json_parse_failed.description", comment: "Failed to parse the assets manifest JSON")

                handleErrorWithMessage(message)
            }
        }
        else {
            let message = NSLocalizedString("error.json_open_failed.description", comment: "Failed to open the assets manifest JSON")
            
            handleErrorWithMessage(message)
        }
    
        for assetJSON in assetsJSON {
            let mediaURL: NSURL

            if let resourceName = assetJSON["mediaResourceName"] as! String? {
                let name = (resourceName as NSString).stringByDeletingPathExtension
                let type = (resourceName as NSString).pathExtension
                mediaURL = NSBundle.mainBundle().URLForResource(name, withExtension: type)!
            }
            else {
                let URLString = assetJSON["mediaURL"] as! String
                mediaURL = NSURL(string: URLString)!
            }
            
            let title = assetJSON["title"] as! String
            let thumbnailResourceName = assetJSON["thumbnailResourceName"] as! String

            let asset = AVURLAsset(URL: mediaURL, options: [:])
            asynchronouslyLoadURLAsset(asset, title: title, thumbnailResourceName: thumbnailResourceName)
        }
    }

    // MARK: - IBActions

	@IBAction func playPauseButtonWasPressed(sender: UIButton) {
		if player.rate != 1.0 {
            // Not playing forward, so play.
			if currentTime == duration {
                // At end, so go back to beginning.
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

    private func presentModalPopoverAlertController(alertController: UIAlertController, sender: UIButton) {
        alertController.modalPresentationStyle = .Popover

        alertController.popoverPresentationController?.sourceView = sender
        alertController.popoverPresentationController?.sourceRect = sender.bounds
        alertController.popoverPresentationController?.permittedArrowDirections = .Any

        presentViewController(alertController, animated: true, completion: nil)
    }
    
    @IBAction func addItemToQueueButtonPressed(sender: UIButton) {
        let alertTitle = NSLocalizedString("popover.title.addItem", comment: "Title of popover that adds items to the queue")
        
        let alertMessage = NSLocalizedString("popover.message.addItem", comment: "Message on popover that adds items to the queue")

        let alertController = UIAlertController(title: alertTitle, message: alertMessage, preferredStyle: .ActionSheet)
        
        // Populate the sheet with the titles of the assets we have loaded.
        for (loadedAssetTitle, loadedAsset) in loadedAssets {
            let alertAction = UIAlertAction(title:loadedAssetTitle, style: .Default) { [unowned self] alertAction in
                let oldItems = self.player.items()
                
                let newPlayerItem = AVPlayerItem(asset: loadedAsset)
                
                self.player.insertItem(newPlayerItem, afterItem: nil)

                self.queueDidChangeWithOldPlayerItems(oldItems, newPlayerItems: self.player.items())
            }

            alertController.addAction(alertAction)
        }

        let cancelActionTitle = NSLocalizedString("popover.title.cancel", comment: "Title of popover cancel action")

        let cancelAction = UIAlertAction(title: cancelActionTitle, style: .Cancel, handler: nil)
        
        alertController.addAction(cancelAction)

        presentModalPopoverAlertController(alertController, sender: sender)
    }

    @IBAction func clearQueueButtonWasPressed(sender: UIButton) {
        let alertTitle = NSLocalizedString("popover.title.clear", comment: "Title of popover that clears the queue")

        let alertMessage = NSLocalizedString("popover.message.clear", comment: "Message on popover that clears the queue")
        
        let alertController = UIAlertController(title: alertTitle, message: alertMessage, preferredStyle: .ActionSheet)

        let clearButtonTitle = NSLocalizedString("button.title.clear", comment: "Title on button to clear the queue")

        let clearQueueAction = UIAlertAction(title: clearButtonTitle, style: .Destructive) { [unowned self] alertAction in
            let oldItems = self.player.items()

            self.player.removeAllItems()
            
            self.queueDidChangeWithOldPlayerItems(oldItems, newPlayerItems: self.player.items())
        }
        
        alertController.addAction(clearQueueAction)
        
        let cancelActionTitle = NSLocalizedString("popover.title.cancel", comment: "Title of popover cancel action")

        let cancelAction = UIAlertAction(title: cancelActionTitle, style: .Cancel, handler: nil)
        
        alertController.addAction(cancelAction)

        presentModalPopoverAlertController(alertController, sender: sender)
    }

    // MARK: KVO Observation

    // Update our UI when player or `player.currentItem` changes.
    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String: AnyObject]?, context: UnsafeMutablePointer<Void>) {
        // Make sure the this KVO callback was intended for this view controller.
        guard context == &playerViewControllerKVOContext else {
            super.observeValueForKeyPath(keyPath, ofObject: object, change: change, context: context)
            return
        }

        if keyPath == "player.currentItem" {
            queueDidChangeWithOldPlayerItems([], newPlayerItems: player.items())
        }
        else if keyPath == "player.currentItem.duration" {
            // Update `timeSlider` and enable / disable controls when `duration` > 0.0.

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
            let currentTime = hasValidDuration ? Float(CMTimeGetSeconds(player.currentTime())) : 0.0
            
            timeSlider.maximumValue = Float(newDurationSeconds)

            timeSlider.value = currentTime
            
            rewindButton.enabled = hasValidDuration
            
            playPauseButton.enabled = hasValidDuration
            
            fastForwardButton.enabled = hasValidDuration
            
            timeSlider.enabled = hasValidDuration
            
            startTimeLabel.enabled = hasValidDuration
            startTimeLabel.text = createTimeString(currentTime)
            
            durationLabel.enabled = hasValidDuration
            durationLabel.text = createTimeString(Float(newDurationSeconds))
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
                handleErrorWithMessage(player.currentItem?.error?.localizedDescription, error: player.currentItem?.error)
            }
        }
	}

    /*
        Trigger KVO for anyone observing our properties affected by `player` and
        `player.currentItem`.
    */
    override class func keyPathsForValuesAffectingValueForKey(key: String) -> Set<String> {
        let affectedKeyPathsMappingByKey: [String: Set<String>] = [
            "duration":     ["player.currentItem.duration"],
            "currentTime":  ["player.currentItem.currentTime"],
            "rate":         ["player.rate"]
        ]
        
        return affectedKeyPathsMappingByKey[key] ?? super.keyPathsForValuesAffectingValueForKey(key)
	}    
    
    /*
        `player.items` is not KVO observable so we need to call this function
        every time the queue changes.
    */
    private func queueDidChangeWithOldPlayerItems(oldPlayerItems: [AVPlayerItem], newPlayerItems: [AVPlayerItem]) {
        if newPlayerItems.isEmpty {
            queueLabel.text = NSLocalizedString("label.queue.empty", comment: "Queue is empty")
        }
        else {
            let stringFormat = NSLocalizedString("label.queue.%lu items", comment: "Queue of n item(s)")
            
            queueLabel.text = String.localizedStringWithFormat(stringFormat, newPlayerItems.count)
        }

        let isQueueEmpty = newPlayerItems.count == 0
        clearButton.enabled = !isQueueEmpty
    
        collectionView.reloadData()
    }

    // MARK: Error Handling

	func handleErrorWithMessage(message: String?, error: NSError? = nil) {
        NSLog("Error occurred with message: \(message), error: \(error).")
    
        let alertTitle = NSLocalizedString("alert.error.title", comment: "Alert title for errors")
        
        let alertMessage = message ?? NSLocalizedString("error.default.description", comment: "Default error message when no NSError provided")

        let alert = UIAlertController(title: alertTitle, message: alertMessage, preferredStyle: .Alert)

        let alertActionTitle = NSLocalizedString("alert.error.actions.OK", comment: "OK on error alert")
        let alertAction = UIAlertAction(title: alertActionTitle, style: .Default, handler: nil)

        alert.addAction(alertAction)

        presentViewController(alert, animated: true, completion: nil)
	}


    // MARK: UICollectionViewDataSource
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return player.items().count
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("ItemCell", forIndexPath: indexPath) as! QueuedItemCollectionViewCell
        
        let item = player.items()[indexPath.row]
        
        let urlAsset = item.asset as! AVURLAsset

        let titleAndThumbnail = assetTitlesAndThumbnails[urlAsset.URL]!
        
        cell.label.text = titleAndThumbnail.title
        
        cell.backgroundView = UIImageView(image: titleAndThumbnail.thumbnail)
        
        return cell
    }
    
    // MARK: Convenience
    
    func createTimeString(time: Float) -> String {
        let components = NSDateComponents()
        components.second = Int(max(0.0, time))
        
        return timeRemainingFormatter.stringFromDateComponents(components)!
    }
}
