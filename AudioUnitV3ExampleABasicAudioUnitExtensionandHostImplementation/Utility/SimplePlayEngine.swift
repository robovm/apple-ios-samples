/*
	Copyright (C) 2015 Apple Inc. All Rights Reserved.
	See LICENSE.txt for this sample’s licensing information
	
	Abstract:
	Illustrates use of AVAudioUnitComponentManager, AVAudioEngine, AVAudioUnit and AUAudioUnit to play an audio file through a selected Audio Unit effect.
*/

import AVFoundation

/**
	This class implements a small engine to play an audio file in a loop using 
	`AVAudioEngine`. An audio unit effect can be selected from those located by
	`AVAudioUnitComponentManager`. The engine supports choosing from the audio unit's
	presets.
*/
class SimplePlayEngine {
    // MARK: Properties
    
	/// The currently selected `AUAudioUnit` effect, if any.
	var audioUnit: AUAudioUnit?
    
	/// The audio unit's presets.
	var presetList = [AUAudioUnitPreset]()

	/// Synchronizes starting/stopping the engine and scheduling file segments.
	private let stateChangeQueue = dispatch_queue_create("SimplePlayEngine.stateChangeQueue", DISPATCH_QUEUE_SERIAL)
	
    /// Playback engine.
	private let engine = AVAudioEngine()
	
    /// Engine's player node.
	private let player = AVAudioPlayerNode()
	
    /// Engine's effect node.
	private var effect: AVAudioUnit?

	/// File to play.
	private var file: AVAudioFile?
    
	/// Whether we are playing.
	private var isPlaying = false

	/// Callback to tell UI when new components are found.
	private let componentsFoundCallback: (Void -> Void)?

    /// Serializes all access to `availableEffects`.
	private let availableEffectsAccessQueue = dispatch_queue_create("SimplePlayEngine.availableEffectsAccessQueue", DISPATCH_QUEUE_SERIAL)
    
	/// List of available audio unit effect components.
	private var _availableEffects = [AVAudioUnitComponent]()
    
    /**
        `self._availableEffects` is accessed from multiple thread contexts. Use
        a dispatch queue for synchronization.
    */
    var availableEffects: [AVAudioUnitComponent] {
        get {
            var result: [AVAudioUnitComponent]!
            
            dispatch_sync(availableEffectsAccessQueue) {
                result = self._availableEffects
            }
            
            return result
        }

        set {
            dispatch_sync(availableEffectsAccessQueue) {
                self._availableEffects = newValue
            }
        }
    }

    // MARK: Initialization
    
	init(componentsFoundCallback: (Void -> Void)? = nil) {
		self.componentsFoundCallback = componentsFoundCallback

        engine.attachNode(player)

        guard let fileURL = NSBundle.mainBundle().URLForResource("drumLoop", withExtension: "caf") else {
            fatalError("\"drumLoop.caf\" file not found.")
        }

		setPlayerFile(fileURL)

		if componentsFoundCallback != nil {
			// Only bother to look up components if the client provided a callback.
			updateEffectList()
			
			// Sign up for a notification when the list of available components changes.
			NSNotificationCenter.defaultCenter().addObserverForName(kAudioComponentRegistrationsChangedNotification as String, object: nil, queue: nil) { [weak self] _ in
				self?.updateEffectList()
			}
		}

        #if os(iOS)
        do {
            try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback)
        }
        catch {
            fatalError("Can't set Audio Session category.")
        }
		#endif
		
        /*
            Sign up for a notification when an audio unit crashes. Note that we
            handle this on the main queue for thread-safety.
        */
		NSNotificationCenter.defaultCenter().addObserverForName(String(kAudioComponentInstanceInvalidationNotification), object: nil, queue: nil) { [weak self] notification in
            guard let strongSelf = self else { return }
			/*
				If the crashed audio unit was that of our effect, remove it from
                the signal chain. Note: we should notify the UI at this point.
			*/
			if let crashedAU = notification.object as? AUAudioUnit where strongSelf.audioUnit === crashedAU {
                strongSelf.selectEffectWithComponentDescription(nil)
			}
		}
	}
	
	/**
        This is called from init and when we get a notification that the list of
        available components has changed.
    */
	private func updateEffectList() {
		dispatch_async(dispatch_get_global_queue(QOS_CLASS_DEFAULT, 0)) {
			/*
				Locating components can be a little slow, especially the first time.
				Do this work on a separate dispatch thread.
				
				Make a component description matching any effect.
			*/
			var anyEffectDescription = AudioComponentDescription()
            anyEffectDescription.componentType = kAudioUnitType_Effect
            anyEffectDescription.componentSubType = 0
            anyEffectDescription.componentManufacturer = 0
            anyEffectDescription.componentFlags = 0
            anyEffectDescription.componentFlagsMask = 0
            
			self.availableEffects = AVAudioUnitComponentManager.sharedAudioUnitComponentManager().componentsMatchingDescription(anyEffectDescription)
			
			// Let the UI know that we have an updated list of effects.
			dispatch_async(dispatch_get_main_queue()) {
				self.componentsFoundCallback!()
			}
		}
	}
	
	private func setPlayerFile(fileURL: NSURL) {
		do {
			let file = try AVAudioFile(forReading: fileURL)
            
            self.file = file
            
            engine.connect(player, to: engine.mainMixerNode, format: file.processingFormat)
		}
		catch {
			fatalError("Could not create AVAudioFile instance. error: \(error).")
		}
	}
	
	private func setSessionActive(active: Bool) {
		#if os(iOS)
        do {
            try AVAudioSession.sharedInstance().setActive(active)
        }
        catch {
            fatalError("Could not set Audio Session active \(active). error: \(error).")
        }
		#endif
	}

	func togglePlay() -> Bool {
		dispatch_sync(stateChangeQueue) {
			if self.isPlaying {
				self.player.stop()
				self.engine.stop()
				self.isPlaying = false

				self.setSessionActive(false)
			}
			else {
				self.setSessionActive(true)
				
				// Schedule buffers on the player.
				self.scheduleLoop()
				self.scheduleLoop()
				
				// Start the engine.
				do {
					try self.engine.start()
				}
				catch {
					fatalError("Could not start engine. error: \(error).")
				}
				
				// Start the player.
				self.player.play()
				self.isPlaying = true
			}
		}

        return isPlaying
	}

	private func scheduleLoop() {
        guard let file = file else {
            fatalError("`file` must not be nil in \(__FUNCTION__).")
        }
        
		player.scheduleFile(file, atTime: nil) {
			dispatch_async(self.stateChangeQueue) {
				if self.isPlaying {
					self.scheduleLoop()
				}
			}
		}
	}
	
	func selectPresetIndex(presetIndex: Int) {
        guard audioUnit != nil else { return }

        audioUnit!.currentPreset = presetList[presetIndex]
	}
	
	func selectEffectComponent(component: AVAudioUnitComponent?, completionHandler: Void -> Void) {
		selectEffectWithComponentDescription(component?.audioComponentDescription, completionHandler: completionHandler)
	}
	
	/*
		Asynchronously begin changing the engine's installed effect, and call the
        supplied completion handler when the operation is complete.
	*/
    func selectEffectWithComponentDescription(componentDescription: AudioComponentDescription?, completionHandler: (Void -> Void) = {}) {
		// Internal function to resume playing and call the completion handler.
		func done() {
			if isPlaying {
				player.play()
			}
			
			completionHandler()
		}
		
		/*
			Pause the player before re-wiring it. (It is not simple to keep it 
            playing across an effect insertion or deletion.)
		*/
		if isPlaying {
			player.pause()
		}

		// Destroy any pre-existing effect.
		if effect != nil {
			// We have player -> effect -> mixer. Break both connections.
			engine.disconnectNodeInput(effect!)
			engine.disconnectNodeInput(engine.mainMixerNode)

			// Connect player -> mixer.
			engine.connect(player, to: engine.mainMixerNode, format: file!.processingFormat)

			// We're done with the effect; release all references.
			engine.detachNode(effect!)

			effect = nil
			audioUnit = nil
			presetList = [AUAudioUnitPreset]()
		}

		// Insert the new effect, if any.
		if let componentDescription = componentDescription {
			AVAudioUnit.instantiateWithComponentDescription(componentDescription, options: []) { avAudioUnit, error in
                guard let avAudioUnitEffect = avAudioUnit else { return }
                
                self.effect = avAudioUnitEffect
				self.engine.attachNode(avAudioUnitEffect)
				
				// Disconnect player -> mixer.
				self.engine.disconnectNodeInput(self.engine.mainMixerNode)
				
				// Connect player -> effect -> mixer.
				self.engine.connect(self.player, to: avAudioUnitEffect, format: self.file!.processingFormat)
				self.engine.connect(avAudioUnitEffect, to: self.engine.mainMixerNode, format: self.file!.processingFormat)
				
				self.audioUnit = avAudioUnitEffect.AUAudioUnit
                self.presetList = avAudioUnitEffect.AUAudioUnit.factoryPresets ?? []
				
				done()
			}
		}
		else {
			done()
		}
	}
}
