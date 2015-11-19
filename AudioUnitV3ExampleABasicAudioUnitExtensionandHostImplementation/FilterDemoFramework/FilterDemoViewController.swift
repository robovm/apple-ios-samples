/*
	Copyright (C) 2015 Apple Inc. All Rights Reserved.
	See LICENSE.txt for this sample’s licensing information
	
	Abstract:
	View controller for the FilterDemo audio unit. This is the app extension's principal class, responsible for creating both the audio unit and its view. Manages the interactions between a FilterView and the audio unit's parameters.
*/

import UIKit
import CoreAudioKit

public class FilterDemoViewController: AUViewController, AUAudioUnitFactory, FilterViewDelegate {
    // MARK: Properties

    @IBOutlet weak var filterView: FilterView!
	@IBOutlet weak var frequencyLabel: UILabel!
	@IBOutlet weak var resonanceLabel: UILabel!
	
    /*
		When this view controller is instantiated within the FilterDemoApp, its 
        audio unit is created independently, and passed to the view controller here.
	*/
    public var audioUnit: AUv3FilterDemo? {
        didSet {
			/*
				We may be on a dispatch worker queue processing an XPC request at 
                this time, and quite possibly the main queue is busy creating the 
                view. To be thread-safe, dispatch onto the main queue.
				
				It's also possible that we are already on the main queue, so to
                protect against deadlock in that case, dispatch asynchronously.
			*/
			dispatch_async(dispatch_get_main_queue()) {
				if self.isViewLoaded() {
					self.connectViewWithAU()
				}
			}
        }
    }
	
    var cutoffParameter: AUParameter?
	var resonanceParameter: AUParameter?
	var parameterObserverToken: AUParameterObserverToken?
    
	/*
		This implements the required `NSExtensionRequestHandling` protocol method.
		Note that this may become unnecessary in the future, if `AUViewController`
        implements the override.
	*/
	public override func beginRequestWithExtensionContext(context: NSExtensionContext) { }
	
	/*
		This implements the required `AUAudioUnitFactory` protocol method.
		When this view controller is instantiated in an extension process, it 
        creates its audio unit.
	*/
	public func createAudioUnitWithComponentDescription(componentDescription: AudioComponentDescription) throws -> AUAudioUnit {
        audioUnit = try AUv3FilterDemo(componentDescription: componentDescription, options: [])

        return audioUnit!
	}
	
	func updateFilterViewFrequencyAndMagnitudes() {
		guard let audioUnit = audioUnit else { return }

		// Get an array of frequencies from the view.
		let frequencies = filterView.frequencyDataForDrawing()
		
		// Get the corresponding magnitudes from the AU.
		let magnitudes = audioUnit.magnitudesForFrequencies(frequencies).map { $0.doubleValue }
		
        filterView.setMagnitudes(magnitudes)
	}

	public override func viewDidLoad() {
		super.viewDidLoad()
		
		// Respond to changes in the filterView (frequency and/or response changes).
        filterView.delegate = self
		
        guard audioUnit != nil else { return }

        connectViewWithAU()
	}
    
    // MARK: FilterViewDelegate
    
    func filterView(filterView: FilterView, didChangeResonance resonance: Float) {
        resonanceParameter?.setValue(resonance, originator: parameterObserverToken!)
        
        var theResonance = resonance
        
        resonanceLabel.text = resonanceParameter!.stringFromValue(&theResonance)
        
        updateFilterViewFrequencyAndMagnitudes()
    }
    
    func filterView(filterView: FilterView, didChangeFrequency frequency: Float) {
        cutoffParameter?.setValue(frequency, originator: parameterObserverToken!)
        
        var theFrequency = frequency
        
        frequencyLabel.text = cutoffParameter!.stringFromValue(&theFrequency)
        
        updateFilterViewFrequencyAndMagnitudes()
    }
    
    func filterViewDataDidChange(filterView: FilterView) {
        updateFilterViewFrequencyAndMagnitudes()
    }
	
	/*
		We can't assume anything about whether the view or the AU is created first.
		This gets called when either is being created and the other has already 
        been created.
	*/
	func connectViewWithAU() {
		guard let paramTree = audioUnit?.parameterTree else { return }

		cutoffParameter = paramTree.valueForKey("cutoff") as? AUParameter
		resonanceParameter = paramTree.valueForKey("resonance") as? AUParameter
		
		parameterObserverToken = paramTree.tokenByAddingParameterObserver { address, value in
			dispatch_async(dispatch_get_main_queue()) {
				if address == self.cutoffParameter!.address {
					self.filterView.frequency = value
					self.frequencyLabel.text = self.cutoffParameter!.stringFromValue(nil)
				}
				else if address == self.resonanceParameter!.address {
					self.filterView.resonance = value
					self.resonanceLabel.text = self.resonanceParameter!.stringFromValue(nil)
				}
				
				self.updateFilterViewFrequencyAndMagnitudes()
			}
		}
		
		filterView.frequency = cutoffParameter!.value
		filterView.resonance = resonanceParameter!.value
	}
}
