/*
	Copyright (C) 2015 Apple Inc. All Rights Reserved.
	See LICENSE.txt for this sample’s licensing information
	
	Abstract:
	View controller which registers an AUAudioUnit subclass in-process for easy development, connects sliders and text fields to its parameters, and embeds the audio unit's view into a subview. Uses SimplePlayEngine to audition the effect.
*/

import UIKit
import AudioToolbox
import FilterDemoFramework

class ViewController: UIViewController {
    // MARK: Properties

	@IBOutlet var playButton: UIButton!

	@IBOutlet var cutoffSlider: UISlider!
	@IBOutlet var resonanceSlider: UISlider!
	
	@IBOutlet var cutoffTextField: UITextField!
	@IBOutlet var resonanceTextField: UITextField!

    /// Container for our custom view.
    @IBOutlet var auContainerView: UIView!

	/// The audio playback engine.
	var playEngine: SimplePlayEngine!

	/// The audio unit's filter cutoff frequency parameter object.
	var cutoffParameter: AUParameter!

	/// The audio unit's filter resonance parameter object.
	var resonanceParameter: AUParameter!

	/// A token for our registration to observe parameter value changes.
	var parameterObserverToken: AUParameterObserverToken!

	/// Our plug-in's custom view controller. We embed its view into `viewContainer`.
	var filterDemoViewController: FilterDemoViewController!

    // MARK: View Life Cycle
    
	override func viewDidLoad() {
		super.viewDidLoad()
		
		// Set up the plug-in's custom view.
		embedPlugInView()
		
		// Create an audio file playback engine.
		playEngine = SimplePlayEngine()
		
		/*
			Register the AU in-process for development/debugging.
			First, build an AudioComponentDescription matching the one in our 
            .appex's Info.plist.
		*/
        var componentDescription = AudioComponentDescription()
        componentDescription.componentType = kAudioUnitType_Effect
        componentDescription.componentSubType = 0x666c7472 /*'fltr'*/
        componentDescription.componentManufacturer = 0x44656d6f /*'Demo'*/
        componentDescription.componentFlags = 0
        componentDescription.componentFlagsMask = 0
		
		/*
			Register our `AUAudioUnit` subclass, `AUv3FilterDemo`, to make it able 
            to be instantiated via its component description.
			
			Note that this registration is local to this process.
		*/
        AUAudioUnit.registerSubclass(AUv3FilterDemo.self, asComponentDescription: componentDescription, name: "Local FilterDemo", version: UInt32.max)

		// Instantiate and insert our audio unit effect into the chain.
		playEngine.selectEffectWithComponentDescription(componentDescription) {
			// This is an asynchronous callback when complete. Finish audio unit setup.
			self.connectParametersToControls()
		}
	}
	
	/// Called from `viewDidLoad(_:)` to embed the plug-in's view into the app's view.
	func embedPlugInView() {
        /*
			Locate the app extension's bundle, in the app bundle's PlugIns
			subdirectory. Load its MainInterface storyboard, and obtain the
            `FilterDemoViewController` from that.
        */
        let builtInPlugInsURL = NSBundle.mainBundle().builtInPlugInsURL!
        let pluginURL = builtInPlugInsURL.URLByAppendingPathComponent("FilterDemoAppExtension.appex")
		let appExtensionBundle = NSBundle(URL: pluginURL)

        let storyboard = UIStoryboard(name: "MainInterface", bundle: appExtensionBundle)
		filterDemoViewController = storyboard.instantiateInitialViewController() as! FilterDemoViewController
        
        // Present the view controller's view.
        if let view = filterDemoViewController.view {
            addChildViewController(filterDemoViewController)
            view.frame = auContainerView.bounds
            
            auContainerView.addSubview(view)
            filterDemoViewController.didMoveToParentViewController(self)
        }
	}
	
	/**
        Called after instantiating our audio unit, to find the AU's parameters and
        connect them to our controls.
    */
	func connectParametersToControls() {
		// Find our parameters by their identifiers.
        guard let parameterTree = playEngine.audioUnit?.parameterTree else { return }

        let audioUnit = playEngine.audioUnit as! AUv3FilterDemo
        filterDemoViewController.audioUnit = audioUnit
        
        cutoffParameter = parameterTree.valueForKey("cutoff") as? AUParameter
        resonanceParameter = parameterTree.valueForKey("resonance") as? AUParameter
        
        parameterObserverToken = parameterTree.tokenByAddingParameterObserver { [unowned self] address, value in
            /*
                This is called when one of the parameter values changes.
                
                We can only update UI from the main queue.
            */
            dispatch_async(dispatch_get_main_queue()) {
                if address == self.cutoffParameter.address {
                    self.updateCutoff()
                }
                else if address == self.resonanceParameter.address {
                    self.updateResonance()
                }
            }
        }
        
        updateCutoff()
        updateResonance()
	}
    
	// Callbacks to update controls from parameters.
	func updateCutoff() {
		cutoffTextField.text = cutoffParameter.stringFromValue(nil)
		cutoffSlider.value = cutoffParameter.value
	}

	func updateResonance() {
		resonanceTextField.text = resonanceParameter.stringFromValue(nil)
		resonanceSlider.value = resonanceParameter.value
	}

    // MARK: IBActions

	/// Handles Play/Stop button touches.
    @IBAction func togglePlay(sender: AnyObject?) {
		let isPlaying = playEngine.togglePlay()

        let titleText = isPlaying ? "Stop" : "Play"

		playButton.setTitle(titleText, forState: .Normal)
	}
	
	@IBAction func changedCutoff(sender: AnyObject?) {
        guard sender === cutoffSlider else { return }
        
        // Set the parameter's value from the slider's value.
        cutoffParameter.value = cutoffSlider.value
	}

	@IBAction func changedResonance(sender: AnyObject?) {
        guard sender === resonanceSlider else { return }

        // Set the parameter's value from the slider's value.
        resonanceParameter.value = resonanceSlider.value
	}
}
