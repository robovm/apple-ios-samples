/*
	Copyright (C) 2015 Apple Inc. All Rights Reserved.
	See LICENSE.txt for this sample’s licensing information
	
	Abstract:
	View controller managing selection of an audio unit and presets, opening/closing an audio unit's view, and starting/stopping audio playback.
*/

import UIKit
import AVFoundation
import CoreAudioKit

class ViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    // MARK: Properties
    
	@IBOutlet var playButton: UIButton!
	@IBOutlet var audioUnitTableView: UITableView!
	@IBOutlet var presetTableView: UITableView!
	@IBOutlet var viewContainer: UIView!
    @IBOutlet var noViewLabel: UILabel!

    var childViewController: UIViewController?
    
    var audioUnitView: UIView? {
        return childViewController?.view
    }

	var playEngine: SimplePlayEngine!
    
    // MARK: View Life Cycle

	override func viewDidLoad() {
		super.viewDidLoad()

		playEngine = SimplePlayEngine {
			self.audioUnitTableView.reloadData()
		}
	}

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		if tableView === audioUnitTableView {
			return playEngine.availableEffects.count + 1
		}
		
        if tableView === presetTableView {
			return playEngine.presetList.count
		}

        return 0
	}

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("cell", forIndexPath: indexPath)
        
        if tableView === audioUnitTableView {
            if indexPath.row > 0 {
                let component = playEngine.availableEffects[indexPath.row - 1]
                
                cell.textLabel!.text = "\(component.name) (\(component.manufacturerName))"
            }
            else {
                cell.textLabel!.text = "(No effect)"
            }
            
            return cell
        }
        
        if tableView === presetTableView {
            cell.textLabel!.text = playEngine.presetList[indexPath.row].name
            
            return cell
        }
        
        fatalError("This index path doesn't make sense for this table view.")
	}
    
	func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
		let row = indexPath.row

		if tableView === audioUnitTableView {
            // We only want update the table view once the component is selected.
            let completionHandler = presetTableView.reloadData
            
            let component: AVAudioUnitComponent?
            
			if row > 0 {
				component = playEngine.availableEffects[row - 1]
			}
            else {
                component = nil
            }

            playEngine.selectEffectComponent(component, completionHandler: completionHandler)
            
            removeChildController()
            noViewLabel.hidden = false
		}
		else if tableView == presetTableView {
			playEngine.selectPresetIndex(row)
		}
	}
    
    // MARK: - IBActions

	@IBAction func togglePlay(sender: AnyObject?) {
		let isPlaying = playEngine.togglePlay()

        let titleText = isPlaying ? "Stop" : "Play"
        
		playButton.setTitle(titleText, forState: .Normal)
	}

    func removeChildController() -> Bool {
        if let childViewController = childViewController, audioUnitView = audioUnitView {
            childViewController.willMoveToParentViewController(nil)

            audioUnitView.removeFromSuperview()
            
            childViewController.removeFromParentViewController()
            
            self.childViewController = nil
            
            return true
        }
        
        return false
    }

	@IBAction func toggleView(sender: AnyObject?) {
        /* 
            This method is called when the view button is pressed.
        
            If there is no view shown, and the AudioUnit has a UI, the view 
            controller is loaded from the AU and presented as a child view
            controller.
        
            If a pre-existing view is being shown, it is removed.
         */

        let removedChildController = removeChildController()
        
        guard !removedChildController else { return }
        
        /* 
            Request the view controller asynchronously from the audio unit. This 
            only happens if the audio unit is non-nil.
        */
        playEngine.audioUnit?.requestViewControllerWithCompletionHandler { [weak self] viewController in
            guard let strongSelf = self else { return }
            
            // Only update the view if the view controller has one.
            guard let viewController = viewController, view = viewController.view else {
                /*
                    Show placeholder text that tells the user the audio unit has 
                    no view.
                */
                strongSelf.noViewLabel.hidden = false
                return
            }

            strongSelf.addChildViewController(viewController)
            view.frame = strongSelf.viewContainer.bounds
            
            strongSelf.viewContainer.addSubview(view)
            strongSelf.childViewController = viewController
            
            viewController.didMoveToParentViewController(self)
            
            strongSelf.noViewLabel.hidden = true
        }
	}
}
