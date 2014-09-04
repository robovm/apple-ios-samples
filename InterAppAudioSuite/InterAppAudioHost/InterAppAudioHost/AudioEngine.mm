/*
     File: AudioEngine.mm
 Abstract: 
  Version: 1.1.2
 
 Disclaimer: IMPORTANT:  This Apple software is supplied to you by Apple
 Inc. ("Apple") in consideration of your agreement to the following
 terms, and your use, installation, modification or redistribution of
 this Apple software constitutes acceptance of these terms.  If you do
 not agree with these terms, please do not use, install, modify or
 redistribute this Apple software.
 
 In consideration of your agreement to abide by the following terms, and
 subject to these terms, Apple grants you a personal, non-exclusive
 license, under Apple's copyrights in this original Apple software (the
 "Apple Software"), to use, reproduce, modify and redistribute the Apple
 Software, with or without modifications, in source and/or binary forms;
 provided that if you redistribute the Apple Software in its entirety and
 without modifications, you must retain this notice and the following
 text and disclaimers in all such redistributions of the Apple Software.
 Neither the name, trademarks, service marks or logos of Apple Inc. may
 be used to endorse or promote products derived from the Apple Software
 without specific prior written permission from Apple.  Except as
 expressly stated in this notice, no other rights or licenses, express or
 implied, are granted by Apple herein, including but not limited to any
 patent rights that may be infringed by your derivative works or by other
 works in which the Apple Software may be incorporated.
 
 The Apple Software is provided by Apple on an "AS IS" basis.  APPLE
 MAKES NO WARRANTIES, EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION
 THE IMPLIED WARRANTIES OF NON-INFRINGEMENT, MERCHANTABILITY AND FITNESS
 FOR A PARTICULAR PURPOSE, REGARDING THE APPLE SOFTWARE OR ITS USE AND
 OPERATION ALONE OR IN COMBINATION WITH YOUR PRODUCTS.
 
 IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL
 OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 INTERRUPTION) ARISING IN ANY WAY OUT OF THE USE, REPRODUCTION,
 MODIFICATION AND/OR DISTRIBUTION OF THE APPLE SOFTWARE, HOWEVER CAUSED
 AND WHETHER UNDER THEORY OF CONTRACT, TORT (INCLUDING NEGLIGENCE),
 STRICT LIABILITY OR OTHERWISE, EVEN IF APPLE HAS BEEN ADVISED OF THE
 POSSIBILITY OF SUCH DAMAGE.
 
 Copyright (C) 2014 Apple Inc. All Rights Reserved.
 
 */

#import "AudioEngine.h"

//Prefered sample rate
#define kSampleRate 44100.0f

@implementation RemoteAU
- (void) dealloc {
    [_image release];
	[_name release];
	[super dealloc];
}
@end

#pragma mark Callback methods
OSStatus hostStateCallback(void 	*inHostUserData,
                           Boolean	*outIsPlaying,
                           Boolean	*outIsRecording,
                           Boolean	*outTransportStateChanged,
                           Float64	*outCurrentSampleInTimeLine,
                           Boolean	*outIsCycling,
                           Float64	*outCycleStartBeat,
                           Float64	*outCycleEndBeat) {
    AudioEngine *SELF = (AudioEngine *)inHostUserData;
    OSStatus result = noErr;
    *outIsPlaying = [SELF isPlaying];
	
    *outIsRecording = [SELF isRecording];
    *outCurrentSampleInTimeLine = [SELF getAmountPlayed];
    return result;
}

static void InterAppConnectedChanged(void *				 inRefCon,
                                     AudioUnit			 inUnit,
                                     AudioUnitPropertyID inID,
                                     AudioUnitScope		 inScope,
                                     AudioUnitElement	 inElement) {
    AudioEngine *SELF = (AudioEngine *)inRefCon;
    dispatch_async(dispatch_get_main_queue(), ^{
        [SELF stopRecording];
        [SELF checkStartStopGraph];
        [SELF destroyRemoteAU:inUnit];
        [SELF notifyObservers];
    });
}

#pragma mark - AudioEngine implementation
@implementation AudioEngine

#pragma mark Initialization / deallocation
- (id) init {
    self = [super init];
    if (self) {
        //Setup audio session and set it to active
        AVAudioSession *session = [AVAudioSession sharedInstance];
        NSCheck([session setCategory: AVAudioSessionCategoryPlayAndRecord
                         withOptions: AVAudioSessionCategoryOptionMixWithOthers | AVAudioSessionCategoryOptionDefaultToSpeaker
                               error: &err]);
		
        [session setPreferredSampleRate: kSampleRate error: nil];
        NSCheck([[AVAudioSession sharedInstance] setActive: YES error: &err]);
		
        _engineObservers = [[NSMutableDictionary alloc] init];
        _connectedNodes  = [[NSMutableArray alloc] init];
        _remoteEffects   = [[NSMutableArray alloc] init];
		
		state = TransportStateStopped;
		
        busCount    = 2;
        remoteBus   = 1;
        tapFormat = CAStreamBasicDescription([[AVAudioSession sharedInstance] sampleRate], 2, CAStreamBasicDescription::kPCMFormatInt16, YES);
        state = TransportStateStopped;
		
        [self checkStartOrStopEngine];
        [self setupStereoStreamFormat];
        [self createGraph];
    }
    return self;
}

- (void) dealloc {
    if (_engineObservers) {
        NSArray *values = [_engineObservers allValues];
        // values in foreach loop
        for (NSString *value in values) {
            Block_release(value);
        }
    }
    
    if (recorder) {
        recorder->Stop();
        recorder->Close();
        delete recorder;
    }
    
    [_engineObservers release];
    [_connectedNodes release];
	
    [super dealloc];
}

#pragma mark CAUIKeyboardEngine protocol methods
- (AudioUnit) getAudioUnitInstrument {
    return instrument;
}

#pragma mark Audio Unit interrogation methods
- (NSUInteger) getNumberOfConnectedNodes {
    return [_connectedNodes count];
}

- (RemoteAU*) getNodeAt:(int) index {
	return (RemoteAU *) [_connectedNodes objectAtIndex:index];
}

- (BOOL) isRemoteEffectConnected {
	return effect != NULL ? YES : NO;
}

- (BOOL) isRemoteInstrumentConnected {
	return instrument != NULL ? YES : NO;
}

- (void) gotoRemoteEffect {
    [self gotoAudioUnitUrl:effect];
}

- (void) gotoRemoteInstrument {
    [self gotoAudioUnitUrl:instrument];
}

- (void) gotoAudioUnitUrl:(AudioUnit) remoteAU {
    CFURLRef instrumentUrl;
    UInt32 dataSize = sizeof(instrumentUrl);
    OSStatus result = AudioUnitGetProperty(remoteAU, kAudioUnitProperty_PeerURL, kAudioUnitScope_Global, 0, &instrumentUrl, &dataSize);
    if (result == noErr) {
        [[UIApplication sharedApplication] openURL:(NSURL*)instrumentUrl];
    }
}

#pragma mark Audio Unit manipulation methods
- (void) disconnectInstrument {
    if ([self isRemoteInstrumentConnected])
        [self destroyNode:kAudioUnitType_RemoteInstrument];
}

- (void) disconnectEffect {
	// Your application should only disconnect the effect, but in the interest of simplicity, this example does not include that code
    [self disconnectInstrument];
}

- (void) destroyRemoteAU:(AudioUnit) remoteAU {
    if (instrument == remoteAU) {
        [self destroyNode:kAudioUnitType_RemoteInstrument];
    }
}

- (BOOL) addRemoteAU:(RemoteAU *) rau {
	AudioComponentDescription desc = rau->_desc;
	BOOL isRemoteConnected = NO;
	
	for (RemoteAU *au : _connectedNodes) {
		AudioComponentDescription localDesc = au->_desc;
		if (desc.componentSubType == localDesc.componentSubType && desc.componentType == localDesc.componentType && desc.componentManufacturer == localDesc.componentManufacturer) {
			isRemoteConnected = YES;
			break;
		}
	}
	
	if (!isRemoteConnected) {
        AudioUnit *currentUnit = NULL;
        if ((desc.componentType == kAudioUnitType_RemoteInstrument)
            || (desc.componentType == kAudioUnitType_RemoteGenerator)) {
			// Check to see if a remote instrument if so toss the existing graph
            if ([self isRemoteInstrumentConnected])
                [self destroyNode:kAudioUnitType_RemoteInstrument];

            if (!_engineStarted)										// Check if session is active
                [self checkStartOrStopEngine];

            if (graphStarted)											// Check if graph is running and or is created, if so, stop it
                [self checkStartStopGraph];

            if ([self checkGraphInitialized ])							// Check if graph has been inititialized if so, uninitialize it.
				Check(AUGraphUninitialize(hostGraph));
            
            Check (AUGraphAddNode (hostGraph, &desc, &instrumentNode));	// Add remote instrument

            //Connect the nodes
            Check (AUGraphConnectNodeInput (hostGraph, instrumentNode, 0, mixerNode, remoteBus));
            //Grab audio units from the graph
            Check (AUGraphNodeInfo(hostGraph, instrumentNode, 0, &instrument));
            currentUnit = &instrument;
        } else if (desc.componentType == kAudioUnitType_RemoteEffect) {
            if ([self isRemoteInstrumentConnected]) {
                if (!_engineStarted)									// Check if session is active
                    [self checkStartOrStopEngine];
                
				if ([self isGraphStarted])							    // Check if graph is running and or is created, if so, stop it
                    [self checkStartStopGraph];
				
                if ([self checkGraphInitialized ])						// Check if graph has been inititialized if so, uninitialize it.
                    Check(AUGraphUninitialize(hostGraph));
				
                Check (AUGraphAddNode (hostGraph, &desc, &effectNode)); // Add remote instrument

                //Disconnect previous chain
                Check(AUGraphDisconnectNodeInput(hostGraph, mixerNode, remoteBus));
				
                //Connect the effect node to the mixer on the remoteBus
                Check(AUGraphConnectNodeInput (hostGraph, effectNode, 0, mixerNode, remoteBus));
				
                //Connect the remote instrument node to the effect node on bus 0
                Check(AUGraphConnectNodeInput (hostGraph, instrumentNode, 0, effectNode, 0));
				
                //Grab audio units from the graph
                Check(AUGraphNodeInfo(hostGraph, effectNode, 0, &effect));
                currentUnit = &effect;
            }
        }

        if (currentUnit) {
            Check (AudioUnitSetProperty (*currentUnit,					// Set stereo format
                                         kAudioUnitProperty_StreamFormat,
                                         kAudioUnitScope_Output,
                                         playerBus,
                                         &stereoStreamFormat,
                                         sizeof (stereoStreamFormat)));
            UInt32 maxFrames = 4096;
            Check(AudioUnitSetProperty(*currentUnit,
                                       kAudioUnitProperty_MaximumFramesPerSlice,
                                       kAudioUnitScope_Global, playerBus,
                                       &maxFrames,
                                       sizeof(maxFrames)));
			
            [self addAudioUnitPropertyListeners:*currentUnit];			// Add property listeners to audio unit
            Check(AUGraphInitialize (hostGraph));						// Initialize the graph

            [self checkStartStopGraph];									//Start the graph
        }
        
        [_connectedNodes addObject:rau];
        return true;
	}

    return false;
}

- (void) deleteConnectedNode:(AudioComponentDescription) audioComponentDescription {
	
    for (RemoteAU *rau in _connectedNodes) {
        if (rau->_desc.componentManufacturer == audioComponentDescription.componentManufacturer &&
            rau->_desc.componentSubType == audioComponentDescription.componentSubType &&
            rau->_desc.componentType == audioComponentDescription.componentType) {
            [_connectedNodes removeObject:rau];
			
            return;
        }
    }
}

- (void) destroyNode:(OSType) node {
    if ((node == kAudioUnitType_RemoteInstrument)
        || (node == kAudioUnitType_RemoteGenerator)){
        if (state == TransportStatePaused ||
            state == TransportStatePlaying)
            [self stopPlaying];
        if (state == TransportStateRecording )
            [self stopRecording];
        if (graphStarted)
            [self checkStartStopGraph];				// Stop the graph
        Check(DisposeAUGraph(hostGraph));	        // Nuke the current graph

        [self createGraph];							// Rebuild graph

        Check(AUGraphInitialize (hostGraph));       // Initialize the graph
		
        if (!_engineStarted)				
            [self checkStartOrStopEngine];			// Restart the graph

        instrument = NULL;
        effect = NULL;
        [_connectedNodes removeAllObjects];
    }
    [self notifyObservers];
}

- (void) startPlaying {
    if (!filePlayer.fileAU || state == TransportStatePlaying) return;
    if (canPlay) {
        [self resetFilePlayer];
        if (!_engineStarted)
            [self checkStartOrStopEngine];
        
        filePlayer.graph = hostGraph;
        filePlayer.fileAU = filePlayerUnit;
        
        Check(AudioFileOpenURL((CFURLRef)fileURL, kAudioFileReadPermission, 0, &filePlayer.inputFile));
        UInt32 propSize = sizeof(filePlayer.inputFormat);
        
 		Check(AudioFileGetProperty(filePlayer.inputFile, kAudioFilePropertyDataFormat, &propSize, &filePlayer.inputFormat));
        Check(AudioUnitSetProperty(filePlayer.fileAU,
                                   kAudioUnitProperty_ScheduledFileIDs,
                                   kAudioUnitScope_Global,
                                   0, &filePlayer.inputFile,
                                   sizeof(filePlayer.inputFile)));
        
        memset(&mScheduledRegion.mTimeStamp, 0, sizeof(mScheduledRegion.mTimeStamp));
		mScheduledRegion.mTimeStamp.mFlags = kAudioTimeStampSampleTimeValid;
		
		mScheduledRegion.mTimeStamp.mSampleTime = 0;
		mScheduledRegion.mCompletionProc = Nil;
		mScheduledRegion.mCompletionProcUserData = self;
		mScheduledRegion.mAudioFile = filePlayer.inputFile;
		mScheduledRegion.mLoopCount = 0;	// 1 = loop, 0 = don't loop
		mScheduledRegion.mStartFrame = 0;
		mScheduledRegion.mFramesToPlay = (UInt32)durationOfFile;
        
        if (mTranslatedLastTimeRendered > 0 && mTranslatedLastTimeRendered < durationOfFile) {
			mScheduledRegion.mStartFrame = mTranslatedLastTimeRendered + mInitialRegionOffset;
			mScheduledRegion.mFramesToPlay = (UInt32)(durationOfFile) - (UInt32)(mScheduledRegion.mStartFrame);
			
			mInitialRegionOffset = mScheduledRegion.mStartFrame;
		} else
			mInitialRegionOffset = 0;
        
		Check(AudioUnitSetProperty( filePlayer.fileAU,
                                   kAudioUnitProperty_ScheduledFileRegion,
                                   kAudioUnitScope_Global,
                                   0,
                                   &mScheduledRegion,
                                   sizeof(mScheduledRegion)));
        
        AudioTimeStamp startTime;
        memset(&startTime, 0, sizeof(startTime));
        startTime.mFlags = kAudioTimeStampSampleTimeValid;
        startTime.mSampleTime = -1;
        
        Check(AudioUnitSetProperty(filePlayer.fileAU,
                                   kAudioUnitProperty_ScheduleStartTimeStamp,
                                   kAudioUnitScope_Global,
                                   0,
                                   &startTime,
                                   sizeof(startTime)));
        
        state = TransportStatePlaying;
        
        // prime AU
        UInt32 primeValue = 0;
        Check(AudioUnitSetProperty(filePlayer.fileAU, kAudioUnitProperty_ScheduledFilePrime, kAudioUnitScope_Global, 0, &primeValue, sizeof(primeValue)));
        
        // Start the graph if its not allready started
        if (![self isGraphStarted])
            [self checkStartStopGraph];
        
        [self performSelectorOnMainThread:@selector(notifyObservers) withObject:nil waitUntilDone: NO];
    }
}

- (void) stopPlaying {
	if (!filePlayer.fileAU || state != TransportStatePlaying) return;
	
	// [1] sync. playhead with last sample played
	[self synchronizeFilePlayerState:NO];
    
	// [2] clear schedule
	[self resetFilePlayer];
	
	state = TransportStatePaused;
	// update the UI
    
	[self performSelectorOnMainThread:@selector(notifyObservers) withObject:nil waitUntilDone: NO];
}

- (void) startRecording {
    if (!fileURL)
        fileURL = [createTemporaryRecordNSUrl() retain];	// Create temporary file
    
    if (!_engineStarted)
        [self checkStartOrStopEngine];
    if (![self isGraphStarted])
        [self checkStartStopGraph];
	
    canPlay = [[NSFileManager defaultManager] isReadableFileAtPath: fileURL.path];
	canRewind = NO;
	
    if (canPlay && instrument) {
        if (recorder) {
            recorder->Stop();
            recorder->Close();
            delete recorder;
        }
        
        if (effect)
            recorder = new CAAudioUnitOutputCapturer(effect, (CFURLRef)fileURL, kAudioFileCAFType, tapFormat, 0);
        else if (instrument)
            recorder = new CAAudioUnitOutputCapturer(instrument, (CFURLRef)fileURL, kAudioFileCAFType, tapFormat, 0);
        
        recorder->Start();
        state = TransportStateRecording;
        mTranslatedLastTimeRendered = 0;
        canPlay = NO;
    }
}

- (void) stopRecording {
    if (state == TransportStateRecording) {
        if (recorder) {
            recorder->Stop();
            recorder->Close();
        }
		
        canPlay = YES;
        mTranslatedLastTimeRendered = 0;
		
        if (fileURL && [[NSFileManager defaultManager] isReadableFileAtPath: fileURL.path] && canPlay) {         //Calculate duration
            Check(AudioFileOpenURL((CFURLRef)fileURL, kAudioFileReadPermission, 0, &filePlayer.inputFile));
            UInt32 propSize = sizeof(filePlayer.inputFormat);
            Check(AudioFileGetProperty(filePlayer.inputFile, kAudioFilePropertyDataFormat, &propSize, &filePlayer.inputFormat));
            UInt64 nPackets;
            propSize = sizeof(nPackets);
            Check(AudioFileGetProperty(filePlayer.inputFile,
                                       kAudioFilePropertyAudioDataPacketCount,
                                       &propSize, &nPackets));
            durationOfFile = nPackets * filePlayer.inputFormat.mFramesPerPacket;
        }
        state = TransportStateStopped;
        [self notifyObservers];
        canRewind = YES;
    }
}

- (BOOL) canRewind	 { return canRewind; }
- (BOOL) canPlay	 { return canPlay; }
- (BOOL) canRecord   { return instrument != NULL; }

- (BOOL) isPlaying	 { return (state == TransportStatePlaying); }
- (BOOL) isPaused	 { return (state == TransportStatePaused); }
- (BOOL) isRecording { return (state == TransportStateRecording); }

- (void) rewind {
	BOOL wasPlaying = state == TransportStatePlaying ? YES : NO;
	[self seekPlayheadTo: 0];
	if (wasPlaying)
		[self togglePlay];
}

- (void) togglePlay {
    if (state == TransportStateRecording)
        [self stopRecording];
    if (state == TransportStatePlaying)
        [self stopPlaying];
    else
    	[self startPlaying];
    
    [self notifyObservers];
}

- (void) toggleRecord {
    if (state == TransportStatePlaying || state == TransportStatePaused)
        [self stopPlaying];
    
    if (state == TransportStateRecording)
        [self stopRecording];
    else if (state == TransportStateStopped || state == TransportStatePaused)
        [self startRecording];
    
    [self notifyObservers];
}


- (void) seekPlayheadTo:(CGFloat) position {
    // [1] Stop playing
    [self stopPlaying];
    
    // [2] calculate position to play from
	mInitialRegionOffset = 0;
	mTranslatedLastTimeRendered = durationOfFile * position;
}

- (void) synchronizeFilePlayerState:(BOOL) fromTimer {
	if ([self isPlaying] && filePlayerUnit) {
		mTranslatedLastTimeRendered = 0;
		AudioTimeStamp currentTimeStamp;
		UInt32 dataSize = sizeof(currentTimeStamp);
		OSStatus result = AudioUnitGetProperty(filePlayerUnit, kAudioUnitProperty_CurrentPlayTime, kAudioUnitScope_Global, 0, &currentTimeStamp, &dataSize);
		
		if (result == noErr)
			mTranslatedLastTimeRendered = SInt64(currentTimeStamp.mSampleTime);
        
		SInt64 lastFrame = mScheduledRegion.mStartFrame + mScheduledRegion.mFramesToPlay;
        
		if (mTranslatedLastTimeRendered + mInitialRegionOffset >= lastFrame) {
			mTranslatedLastTimeRendered = lastFrame;
			[self performSelectorOnMainThread:@selector(stopPlaying) withObject:nil waitUntilDone: NO];
            
			if (!_engineStarted)
				[self checkStartOrStopEngine];		// restart the graph
		}	
	}
}

- (SInt64) getAmountPlayed {
	[self synchronizeFilePlayerState:NO];
	SInt64 amount =  mTranslatedLastTimeRendered + mInitialRegionOffset;
	if (amount > durationOfFile)
		return durationOfFile;
	if (amount < 0)
		return 0;
    return amount;
}

#pragma mark -
#pragma mark get duration string

// If the audio engine can play use the sample rate and
// duration of the file in samples to calculate the duration
// string. Else return 00:00.
- (NSString*) getDurationString {
    if (canPlay)
        return formattedTimeStringForFrameCount( durationOfFile, kSampleRate, NO);
    return @"0:00";
}

- (NSString*) getPlayTimeString {
	[self synchronizeFilePlayerState:NO];
	SInt64 playTime = mTranslatedLastTimeRendered + mInitialRegionOffset;
	playTime = playTime > durationOfFile ? durationOfFile : playTime;
	return formattedTimeStringForFrameCount( playTime, [[AVAudioSession sharedInstance] sampleRate], NO);
}

#pragma mark -
#pragma mark calculate progress playing recorded file

// If the audio engine can play and the transport state
// is playing or paused, calculate progress by dividing
// the amountPlayed in samples by the duration of the file
// in samples.
- (float) getPlayProgress {
    if (canPlay && (state == TransportStatePlaying || state == TransportStatePaused)) {
        [self synchronizeFilePlayerState:NO];
        return ((float)mTranslatedLastTimeRendered + mInitialRegionOffset)/durationOfFile;
    } else if (durationOfFile > 0 && mTranslatedLastTimeRendered > 0)
        return (float)(mTranslatedLastTimeRendered + mInitialRegionOffset)/durationOfFile;
    
    return 0;
}

#pragma mark - Add/Notify observers of engine state change

- (void) addEngineObserver:(dispatch_block_t) inObserver key:(NSString*) inKey {
    [_engineObservers setObject:Block_copy(inObserver) forKey:[inKey retain]];
}

- (void) notifyObservers {
    if (_engineObservers) {
        NSArray *callbacks = [_engineObservers allValues];
        for (dispatch_block_t observer in callbacks) {
            observer();
        }
    }
}

- (void) addAudioUnitPropertyListeners:(AudioUnit) remoteAU {
    if (remoteAU) {
        __block AudioEngine *blockSelf = self;
        AudioUnitRemoteControlEventListener block = ^(AudioUnitRemoteControlEvent event) {
            
            dispatch_async(dispatch_get_main_queue(), ^{
                switch (event) {
                    case kAudioUnitRemoteControlEvent_TogglePlayPause:
                        [blockSelf togglePlay];
                        break;
                    case kAudioUnitRemoteControlEvent_ToggleRecord:
                        [blockSelf toggleRecord];
                        break;
                    case kAudioUnitRemoteControlEvent_Rewind:
                        [blockSelf rewind];
                        break;
                    default:
                        break;
                }
                [blockSelf notifyObservers];
            });
        };

        Check(AudioUnitSetProperty(remoteAU,
                                   kAudioUnitProperty_RemoteControlEventListener,
                                   kAudioUnitScope_Global,
                                   0,
                                   &block,
                                   sizeof(block)));
        
        static HostCallbackInfo callBackInfo;
        callBackInfo.hostUserData = self;
        callBackInfo.transportStateProc2 = hostStateCallback;
        
        UInt32 dataSize = sizeof(callBackInfo);
        Check(AudioUnitSetProperty(remoteAU,
                                   kAudioUnitProperty_HostCallbacks,
                                   kAudioUnitScope_Global,
                                   0,
                                   &callBackInfo,
                                   dataSize));
        
        Check(AudioUnitAddPropertyListener(remoteAU,
                                           kAudioUnitProperty_IsInterAppConnected,
                                           InterAppConnectedChanged,
                                           self));
    }
}

- (void) removeAudioUnitPropertyListeners:(AudioUnit) remoteAU {
    if (remoteAU) {
        AudioUnitRemoteControlEventListener block = NULL;
        AudioUnitSetProperty(remoteAU,
                                   kAudioUnitProperty_RemoteControlEventListener,
                                   kAudioUnitScope_Global,
                                   0,
                                   &block,
                                   sizeof(block));
    }
}

#pragma mark - Create audio graph

// 1. Instantiate and open an audio  graph
// 2. Obtain the audio unit nodes for the graph
// 3. Configure the Multichannel Mixer unit
//     * specify the number of input buses
//     * specify the output sample rate
// 4. Initialize the audio processing graph
//     * add fileplayer node
//     * add I/O node
//     * add mixer node
// When the host connects to a remote audio unit, it will be added to this graph
- (void) createGraph {
	// Create a new audio processing graph.
    Check(NewAUGraph (&hostGraph));
    
    // Specify the audio unit component descriptions for the initial units to be
    // added to the graph.
    
    // I/O unit
    AudioComponentDescription iOUnitDescription;
    iOUnitDescription.componentManufacturer		= kAudioUnitManufacturer_Apple;
    iOUnitDescription.componentFlags			= 0;
    iOUnitDescription.componentFlagsMask		= 0;
    iOUnitDescription.componentType				= kAudioUnitType_Output;
    iOUnitDescription.componentSubType			= kAudioUnitSubType_RemoteIO;
    
    // Multichannel mixer unit
    AudioComponentDescription mixerUnitDescription;
    mixerUnitDescription.componentType          = kAudioUnitType_Mixer;
    mixerUnitDescription.componentSubType       = kAudioUnitSubType_MultiChannelMixer;
    mixerUnitDescription.componentManufacturer  = kAudioUnitManufacturer_Apple;
    mixerUnitDescription.componentFlags         = 0;
    mixerUnitDescription.componentFlagsMask     = 0;
    
    //File Player audio unit
    AudioComponentDescription filePlayerDescription;
    filePlayerDescription.componentManufacturer = kAudioUnitManufacturer_Apple;
    filePlayerDescription.componentFlags		= 0;
    filePlayerDescription.componentFlagsMask	= 0;
    filePlayerDescription.componentType			= kAudioUnitType_Generator;
    filePlayerDescription.componentSubType		= kAudioUnitSubType_AudioFilePlayer;
    
    // Add the nodes to the audio processing graph
	Check(AUGraphAddNode (hostGraph, &iOUnitDescription, &outNode));				//Add I/O node 
    Check(AUGraphAddNode (hostGraph, &mixerUnitDescription, &mixerNode));		    //Add mixer node
    Check(AUGraphAddNode (hostGraph, &filePlayerDescription, &filePlayerNode));		//Add file player node

    //Open the graph
    Check(AUGraphOpen (hostGraph));

    //Grab the output audioUnit from the graph
    Check(AUGraphNodeInfo(hostGraph, outNode, 0, &outputUnit));    
    //Grab the output mixerUnit from the graph
    Check(AUGraphNodeInfo(hostGraph, mixerNode, 0, &mixerUnit));
    //Grab the output filePlayerUnit from the graph
    Check(AUGraphNodeInfo(hostGraph, filePlayerNode, 0, &filePlayerUnit));
    
    // Multichannel Mixer unit Setup    
    // Set the bus count on the mixer
    Check(AudioUnitSetProperty (
                          mixerUnit,
                          kAudioUnitProperty_ElementCount,
                          kAudioUnitScope_Input,
                          0,
                          &busCount,
                          sizeof (busCount)));
    
    //Set stereo format for player bus
    Check(AudioUnitSetProperty (
                        mixerUnit,
                        kAudioUnitProperty_StreamFormat,
                        kAudioUnitScope_Input,
                        playerBus,
                        &stereoStreamFormat,
                        sizeof (stereoStreamFormat)));
    
    //Set stereo format for remote bus    
    Check(AudioUnitSetProperty (
                          mixerUnit,
                          kAudioUnitProperty_StreamFormat,
                          kAudioUnitScope_Input,
                          remoteBus,
                          &stereoStreamFormat,
                          sizeof (stereoStreamFormat)));
    
    // Connect the nodes of the audio processing graph
    // mixer to output on bus 0
    Check(AUGraphConnectNodeInput (
                             hostGraph,
                             mixerNode,         // source node
                             0,                 // source node output bus number
                             outNode,           // destination node
                             playerBus          // desintation node input bus number
                             ));
    
    //player to mixer on bus 0
    Check(AUGraphConnectNodeInput (
                            hostGraph,
                            filePlayerNode,      // source node
                            0,                  // source node output bus number
                            mixerNode,          // destination node
                            playerBus           // desintation node input bus number
                            ));    
    //Print the graph
    CAShow (hostGraph);
    
    //Set graph/au on filePlayer struct
    filePlayer.graph = hostGraph;
    filePlayer.fileAU = filePlayerUnit;
}

- (void) setupStereoStreamFormat {
    // The AudioUnitSampleType data type is the recommended type for sample data in audio
    //    units. This obtains the byte size of the type for use in filling in the ASBD.
    stereoStreamFormat.mChannelsPerFrame = 2; // stereo
    stereoStreamFormat.mSampleRate  = [[AVAudioSession sharedInstance] sampleRate];
    stereoStreamFormat.mFormatID    = kAudioFormatLinearPCM;
    stereoStreamFormat.mFormatFlags = kAudioFormatFlagsNativeFloatPacked | kAudioFormatFlagIsNonInterleaved;
    stereoStreamFormat.mBytesPerFrame   = stereoStreamFormat.mBytesPerPacket = sizeof(Float32);
    stereoStreamFormat.mBitsPerChannel  = 32;
    stereoStreamFormat.mFramesPerPacket = 1;
}

- (void) checkStartOrStopEngine {
	NSCheck([[AVAudioSession sharedInstance] setActive: !_engineStarted error: &err]);
	_engineStarted = !_engineStarted;
}

- (BOOL) checkGraphInitialized {
    if (hostGraph) {
        Boolean isInitialized = false;
        Check(AUGraphIsInitialized (hostGraph, &isInitialized));
        return isInitialized;
    }
    return NO;
}

- (BOOL) isGraphStarted {
    if (hostGraph) {
        Check(AUGraphIsRunning (hostGraph, &graphStarted));
        return graphStarted;
    } else 
        graphStarted = NO;

    return graphStarted;
}

- (void) checkStartStopGraph {
    if (hostGraph) {
        if (![self isGraphStarted]) 
            Check(AUGraphStart (hostGraph));
        else 
            [self stopAUGraph];
    }
}

// Stop playback
- (void) stopAUGraph {
    Check(AUGraphIsRunning (hostGraph, &graphStarted));    
    if (graphStarted) {
        Check(AUGraphStop (hostGraph));
        graphStarted = NO;
    }
}

- (void) resetFilePlayer {
    if(!filePlayer.fileAU) return;

    //Reset the audio unit
    Check(AudioUnitReset(filePlayer.fileAU, kAudioUnitScope_Global, 0));
}

#pragma mark - Utility functioms
NSString *formattedTimeStringForFrameCount(UInt64 inFrameCount, Float64 inSampleRate, BOOL inShowMilliseconds) {
	UInt32 hours = 0;
	UInt32 minutes = 0;
	UInt32 seconds = 0;
	UInt32 milliseconds = 0;
    
	// calculate pieces
	if ((inFrameCount != 0) && (inSampleRate != 0)) {
		Float64 absoluteSeconds = (Float64)inFrameCount / inSampleRate;
		UInt64 absoluteIntSeconds = (UInt64)absoluteSeconds;
		
		milliseconds = (UInt32)(round((absoluteSeconds - (Float64)(absoluteIntSeconds)) * 1000.0));
        
		hours = (UInt32)absoluteIntSeconds / 3600;
		absoluteIntSeconds -= (hours * 3600);
		minutes = (UInt32)absoluteIntSeconds / 60;
		absoluteIntSeconds -= (minutes * 60);
		seconds = (UInt32)absoluteIntSeconds;
	}
	
	NSString *retString;
	// construct strings
	
	NSString *hoursString = nil;
	NSString *minutesString;
	NSString *secondsString;
	
	if (hours > 0) {
		hoursString = [NSString stringWithFormat:@"%2d", (unsigned int)hours];
	}
	
	if (minutes == 0) {
		minutesString = @"00";
	} else if (minutes < 10) {
		minutesString = [NSString stringWithFormat:@"0%d", (unsigned int)minutes];
	} else {
		minutesString = [NSString stringWithFormat:@"%d", (unsigned int)minutes];
	}
	
	if (seconds == 0) {
		secondsString = @"00";
	} else if (seconds < 10) {
		secondsString = [NSString stringWithFormat:@"0%d", (unsigned int)seconds];
	} else {
		secondsString = [NSString stringWithFormat:@"%d", (unsigned int)seconds];
	}
	
	if (!inShowMilliseconds) {
		if (hoursString) {
			retString = [NSString stringWithFormat:@"%@:%@:%@", hoursString, minutesString, secondsString];
		} else {
			retString = [NSString stringWithFormat:@"%@:%@", minutesString, secondsString];
		}
	}
	
	if (inShowMilliseconds) {
		NSString *millisecondsString;
		
		if (milliseconds == 0) {
			millisecondsString = @"000";
		} else if (milliseconds < 10) {
			millisecondsString = [NSString stringWithFormat:@"00%d", (unsigned int)milliseconds];
		} else if (milliseconds < 100) {
			millisecondsString = [NSString stringWithFormat:@"0%d", (unsigned int)milliseconds];
		} else {
			millisecondsString = [NSString stringWithFormat:@"%d", (unsigned int)milliseconds];
		}
		
		if (hoursString) {
			retString = [NSString stringWithFormat:@"%@:%@:%@.%@", hoursString, minutesString, secondsString, millisecondsString];
		} else {
			retString = [NSString stringWithFormat:@"%@:%@.%@", minutesString, secondsString, millisecondsString];
		}
	}
	
	return retString;
}

// Get the applications temp directory and create a random
// .caf file name of the format recording-XXXXXX.caf. Returns
// an NSString*.
NSURL *createTemporaryRecordNSUrl() {
    return [NSURL fileURLWithPath: createTemporaryRecordFile()];
}

NSString *applicationTempDirectory() {
    NSString *basePath =  NSTemporaryDirectory();
    NSLog(@"NSTemporaryDirectory: %@", NSTemporaryDirectory());
    return basePath;
}

// Get the applications temp directory and create a random
// .caf file name of the format recording-XXXXXX.caf. Returns
// an NSString*.

NSString* createTemporaryRecordFile() {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *tempFileTemplate = [applicationTempDirectory()
                                  stringByAppendingPathComponent:@"recording-XXXXXX.caf"];
    
    const char *tempFileTemplateCString = [tempFileTemplate fileSystemRepresentation];
    
    char *tempFileNameCString = (char *)malloc(strlen(tempFileTemplateCString) + 1);
    strcpy(tempFileNameCString, tempFileTemplateCString);
    int fileDescriptor = mkstemps(tempFileNameCString, 4);
    
    // no need to keep it open
    close(fileDescriptor);
    
    
    tempFileTemplate = [fileManager
                        stringWithFileSystemRepresentation:tempFileNameCString
                        length:strlen(tempFileNameCString)];
    free(tempFileNameCString);
    return tempFileTemplate ;
}

void displayAlertDialog(NSString *title, NSString *message)
{
    UIAlertView *alert =
    [[UIAlertView alloc] initWithTitle: title
                               message: message
                              delegate: nil
                     cancelButtonTitle:@"OK"
                     otherButtonTitles:nil];
    [alert show];
    [alert release];
    return;
}

@end
