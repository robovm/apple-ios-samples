/*
 Copyright (C) 2015 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 AudioEngine is the main controller class that creates the following objects:
                 AVAudioEngine               *_engine;
                 AVAudioUnitSampler          *_sampler;
                 AVAudioUnitDistortion       *_distortion;
                 AVAudioUnitReverb           *_reverb;
                 AVAudioPlayerNode           *_player;
  
                 AVAudioSequencer            *_sequencer;
                 AVAudioPCMBuffer            *_playerLoopBuffer;
  
             It connects all the nodes, loads the buffers as well as controls the AVAudioEngine object itself.
 */

#import "AudioEngine.h"

@import AVFoundation;

#pragma mark AudioEngine class extensions

@interface AudioEngine() {
    // AVAudioEngine and AVAudioNodes
    AVAudioEngine           *_engine;
    AVAudioUnitSampler      *_sampler;
    AVAudioUnitDistortion   *_distortion;
    AVAudioUnitReverb       *_reverb;
    AVAudioPlayerNode       *_player;
    
    // the sequencer
    AVAudioSequencer        *_sequencer;
    double                  _sequencerTrackLengthSeconds;
    
    // buffer for the player
    AVAudioPCMBuffer        *_playerLoopBuffer;
    
    // for the node tap
    NSURL                   *_mixerOutputFileURL;
    BOOL                    _isRecording;
    BOOL                    _isRecordingSelected;
    
    // mananging session and configuration changes
    BOOL                    _isSessionInterrupted;
    BOOL                    _isConfigChangePending;
}

- (void)handleInterruption:(NSNotification *)notification;
- (void)handleRouteChange:(NSNotification *)notification;

@end

#pragma mark AudioEngine implementation

@implementation AudioEngine

- (instancetype)init
{
    if (self = [super init]) {
        NSError *error;
        BOOL success = NO;
        
        // AVAudioSession setup
        [self initAVAudioSession];
        
        _isSessionInterrupted = NO;
        _isConfigChangePending = NO;
        
        // create the various nodes
        
        /*  AVAudioPlayerNode supports scheduling the playback of AVAudioBuffer instances,
         or segments of audio files opened via AVAudioFile. Buffers and segments may be
         scheduled at specific points in time, or to play immediately following preceding segments. */
        
        _player = [[AVAudioPlayerNode alloc] init];
        
        /* The AVAudioUnitSampler class encapsulates Apple's Sampler Audio Unit. The sampler audio unit can be configured by loading different types of instruments such as an “.aupreset” file, a DLS or SF2 sound bank, an EXS24 instrument, a single audio file or with an array of audio files. The output is a single stereo bus. */
        
        NSURL *bankURL = [NSURL fileURLWithPath:[[NSBundle bundleForClass:[self class]] pathForResource:@"gs_instruments" ofType:@"dls"]];
        _sampler = [[AVAudioUnitSampler alloc] init];
        [_sampler loadSoundBankInstrumentAtURL:bankURL program:0 bankMSB:0x79 bankLSB:0 error:&error];
        
        /* An AVAudioUnitEffect that implements a multi-stage distortion effect */

        _distortion = [[AVAudioUnitDistortion alloc] init];
        
        /*  A reverb simulates the acoustic characteristics of a particular environment.
         Use the different presets to simulate a particular space and blend it in with
         the original signal using the wetDryMix parameter. */
        
        _reverb = [[AVAudioUnitReverb alloc] init];
        
        // load drumloop into a buffer for the playernode
        NSURL *drumLoopURL = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"drumLoop" ofType:@"caf"]];
        AVAudioFile *drumLoopFile = [[AVAudioFile alloc] initForReading:drumLoopURL error:&error];
        _playerLoopBuffer = [[AVAudioPCMBuffer alloc] initWithPCMFormat:[drumLoopFile processingFormat] frameCapacity:(AVAudioFrameCount)[drumLoopFile length]];
        success = [drumLoopFile readIntoBuffer:_playerLoopBuffer error:&error];
        NSAssert(success, @"couldn't read drumLoopFile into buffer, %@", [error localizedDescription]);
        
        _mixerOutputFileURL = nil;
        _isRecording = NO;
        _isRecordingSelected = NO;
        
        // create engine and attach nodes
        [self createEngineAndAttachNodes];
        
        // make engine connections
        [self makeEngineConnections];
        
        //create the audio sequencer
        [self createAndSetupSequencer];
        
        // settings for effects units
        _reverb.wetDryMix = 100;
        [_reverb loadFactoryPreset:AVAudioUnitReverbPresetMediumHall];
        
        [_distortion loadFactoryPreset:AVAudioUnitDistortionPresetDrumsBitBrush];
        _distortion.wetDryMix = 100;
        self.samplerEffectVolume = 0.0;
        
        // sign up for notifications from the engine if there's a hardware config change
        [[NSNotificationCenter defaultCenter] addObserverForName:AVAudioEngineConfigurationChangeNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *note) {
            
            // if we've received this notification, something has changed and the engine has been stopped
            // re-wire all the connections and start the engine
            
            _isConfigChangePending = YES;
            
            if (!_isSessionInterrupted) {
                NSLog(@"Received a %@ notification!", AVAudioEngineConfigurationChangeNotification);
                NSLog(@"Re-wiring connections and starting once again");
                [self makeEngineConnections];
                [self startEngine];
            }
            else {
                NSLog(@"Session is interrupted, deferring changes");
            }
            
            // post notification
            if ([self.delegate respondsToSelector:@selector(engineConfigurationHasChanged)]) {
                [self.delegate engineConfigurationHasChanged];
            }
        }];
        
        // start the engine
        [self startEngine];
    }
    return self;
}

#pragma mark AVAudioSequencer Setup

- (void)createAndSetupSequencer
{
    BOOL success = NO;
    NSError *error;
    /* A collection of MIDI events organized into AVMusicTracks, plus a player to play back the events.
     NOTE: The sequencer must be created after the engine is initialized and an instrument node is attached and connected
     */
    _sequencer = [[AVAudioSequencer alloc] initWithAudioEngine:_engine];
    
    // load sequencer loop
    NSURL *midiFileURL = [NSURL fileURLWithPath:[[NSBundle bundleForClass:[self class]] pathForResource:@"bluesyRiff" ofType:@"mid"]];
    NSAssert(midiFileURL, @"couldn't find midi file");
    success = [_sequencer loadFromURL:midiFileURL options:AVMusicSequenceLoadSMF_PreserveTracks error:&error];
    NSAssert(success, @"couldn't load midi file, %@", error.localizedDescription);
    
    // enable looping on all the sequencer tracks
    _sequencerTrackLengthSeconds = 0;
    [_sequencer.tracks enumerateObjectsUsingBlock:^(AVMusicTrack * __nonnull track, NSUInteger idx, BOOL * __nonnull stop) {
        track.loopingEnabled = true;
        track.numberOfLoops = AVMusicTrackLoopCountForever;
        const float trackLengthInSeconds = track.lengthInSeconds;
        if (_sequencerTrackLengthSeconds < trackLengthInSeconds) {
            _sequencerTrackLengthSeconds = trackLengthInSeconds;
        }
    }];
    
    [_sequencer prepareToPlay];

}

#pragma mark AVAudioEngine Setup

- (void)createEngineAndAttachNodes
{
    /*  An AVAudioEngine contains a group of connected AVAudioNodes ("nodes"), each of which performs
     an audio signal generation, processing, or input/output task.
     
     Nodes are created separately and attached to the engine.
     
     The engine supports dynamic connection, disconnection and removal of nodes while running,
     with only minor limitations:
     - all dynamic reconnections must occur upstream of a mixer
     - while removals of effects will normally result in the automatic connection of the adjacent
     nodes, removal of a node which has differing input vs. output channel counts, or which
     is a mixer, is likely to result in a broken graph. */
    
    _engine = [[AVAudioEngine alloc] init];
    
    /*  To support the instantiation of arbitrary AVAudioNode subclasses, instances are created
     externally to the engine, but are not usable until they are attached to the engine via
     the attachNode method. */
    
    [_engine attachNode:_sampler];
    [_engine attachNode:_distortion];
    [_engine attachNode:_reverb];
    [_engine attachNode:_player];
}

- (void)makeEngineConnections
{
    /*  The engine will construct a singleton main mixer and connect it to the outputNode on demand,
		when this property is first accessed. You can then connect additional nodes to the mixer.
		
		By default, the mixer's output format (sample rate and channel count) will track the format 
		of the output node. You may however make the connection explicitly with a different format. */
    
    // get the engine's optional singleton main mixer node
    AVAudioMixerNode *mainMixer = [_engine mainMixerNode];
    
    /*  Nodes have input and output buses (AVAudioNodeBus). Use connect:to:fromBus:toBus:format: to
     establish connections betweeen nodes. Connections are always one-to-one, never one-to-many or
     many-to-one.
     
     Note that any pre-existing connection(s) involving the source's output bus or the
     destination's input bus will be broken.
     
     @method connect:to:fromBus:toBus:format:
     @param node1 the source node
     @param node2 the destination node
     @param bus1 the output bus on the source node
     @param bus2 the input bus on the destination node
     @param format if non-null, the format of the source node's output bus is set to this
     format. In all cases, the format of the destination node's input bus is set to
     match that of the source node's output bus. */
    
    AVAudioFormat *stereoFormat = [[AVAudioFormat alloc] initStandardFormatWithSampleRate:44100 channels:2];
    
    // establish a connection between nodes
    
    // connect the player to the reverb
    [_engine connect:_player to:_reverb format:stereoFormat];
    
    // connect the reverb effect to mixer input bus 0
    [_engine connect:_reverb to:mainMixer fromBus:0 toBus:0 format:stereoFormat];
    
    // connect the distortion effect to mixer input bus 2
    [_engine connect:_distortion to:mainMixer fromBus:0 toBus:2 format:stereoFormat];
    
    // fan out the sampler to mixer input 1 and distortion effect
    NSArray<AVAudioConnectionPoint *> *destinationNodes = [NSArray arrayWithObjects:[[AVAudioConnectionPoint alloc] initWithNode:_engine.mainMixerNode bus:1], [[AVAudioConnectionPoint alloc] initWithNode:_distortion bus:0], nil];
    [_engine connect:_sampler toConnectionPoints:destinationNodes fromBus:0 format:stereoFormat];
}

- (void)startEngine
{
    // start the engine
    
    /*  startAndReturnError: calls prepare if it has not already been called since stop.
	
		Starts the audio hardware via the AVAudioInputNode and/or AVAudioOutputNode instances in
		the engine. Audio begins flowing through the engine.
	
        This method will return YES for success.
     
		Reasons for potential failure include:
		
		1. There is problem in the structure of the graph. Input can't be routed to output or to a
			recording tap through converter type nodes.
		2. An AVAudioSession error.
		3. The driver failed to start the hardware. */
    
    if (!_engine.isRunning) {
        NSError *error;
        BOOL success;
        success = [_engine startAndReturnError:&error];
        NSAssert(success, @"couldn't start engine, %@", [error localizedDescription]);
    }
}

#pragma mark AVAudioSequencer Methods

- (void)toggleSequencer {
    if (!self.sequencerIsPlaying) {
        [self startEngine];
        NSError *error;
        BOOL success = NO;
        [_sequencer setCurrentPositionInSeconds:0];
        success = [_sequencer startAndReturnError:&error];
        NSAssert(success, @"couldn't start sequencer", [error localizedDescription]);
    } else
        [_sequencer stop];
}

- (BOOL)sequencerIsPlaying
{
    return _sequencer.isPlaying;
}

- (float)sequencerCurrentPosition
{
    return fmodf(_sequencer.currentPositionInSeconds, _sequencerTrackLengthSeconds) / _sequencerTrackLengthSeconds;
}

- (void)setSequencerCurrentPosition:(float)sequencerCurrentPosition
{
    _sequencer.currentPositionInSeconds = sequencerCurrentPosition * _sequencerTrackLengthSeconds;
}

- (float)sequencerPlaybackRate
{
    return _sequencer.rate;
}

- (void)setSequencerPlaybackRate:(float)sequencerPlaybackRate
{
    _sequencer.rate = sequencerPlaybackRate;
}

#pragma mark AudioMixinDestination Methods

- (void)setSamplerDirectVolume:(float)samplerDirectVolume
{
    // get all output connection points from sampler bus 0
    NSArray<AVAudioConnectionPoint *> *connectionPoints = [_engine outputConnectionPointsForNode:_sampler outputBus:0];
    [connectionPoints enumerateObjectsUsingBlock:^(AVAudioConnectionPoint * __nonnull conn, NSUInteger idx, BOOL * __nonnull stop) {
        // if the destination node represents the main mixer, then this is the direct path
        if (conn.node == _engine.mainMixerNode) {
            *stop = true;
            // get the corresponding mixing destination object and set the mixer input bus volume
            AVAudioMixingDestination *mixingDestination = [_sampler destinationForMixer:conn.node bus:conn.bus];
            if (mixingDestination) {
                mixingDestination.volume = samplerDirectVolume;
            }
        }
    }];
}

- (float)samplerDirectVolume
{
    __block float samplerDirectVolume = 0.0;
    NSArray<AVAudioConnectionPoint *> *connectionPoint = [_engine outputConnectionPointsForNode:_sampler outputBus:0];
    [connectionPoint enumerateObjectsUsingBlock:^(AVAudioConnectionPoint * __nonnull conn, NSUInteger idx, BOOL * __nonnull stop) {
        if (conn.node == _engine.mainMixerNode) {
            *stop = true;
            AVAudioMixingDestination *mixingDestination = [_sampler destinationForMixer:conn.node bus:conn.bus];
            if (mixingDestination) {
                samplerDirectVolume = mixingDestination.volume;
            }
        }
    }];
    return samplerDirectVolume;
}

- (void)setSamplerEffectVolume:(float)samplerEffectVolume
{
    // get all output connection points from sampler bus 0
    NSArray<AVAudioConnectionPoint *> *connectionPoints = [_engine outputConnectionPointsForNode:_distortion outputBus:0];
    [connectionPoints enumerateObjectsUsingBlock:^(AVAudioConnectionPoint * __nonnull conn, NSUInteger idx, BOOL * __nonnull stop) {
        // if the destination node represents the distortion effect, then this is the effect path
        if (conn.node == _engine.mainMixerNode) {
            *stop = true;
            // get the corresponding mixing destination object and set the mixer input bus volume
            AVAudioMixingDestination *mixingDestination = [_sampler destinationForMixer:conn.node bus:conn.bus];
            if (mixingDestination) {
                mixingDestination.volume = samplerEffectVolume;
            }
        }
    }];
}

- (float)samplerEffectVolume
{
    __block float distortionVolume = 0.0;
    NSArray<AVAudioConnectionPoint *> *connectionPoint = [_engine outputConnectionPointsForNode:_distortion outputBus:0];
    [connectionPoint enumerateObjectsUsingBlock:^(AVAudioConnectionPoint * __nonnull conn, NSUInteger idx, BOOL * __nonnull stop) {
        if (conn.node == _engine.mainMixerNode) {
            *stop = true;
            AVAudioMixingDestination *mixingDestination = [_sampler destinationForMixer:conn.node bus:conn.bus];
            if (mixingDestination) {
                distortionVolume = mixingDestination.volume;
            }
        }
    }];
    return distortionVolume;
}

#pragma mark Mixer Methods

- (void)setOutputVolume:(float)outputVolume
{
    _engine.mainMixerNode.outputVolume = outputVolume;
}

- (float)outputVolume
{
    return _engine.mainMixerNode.outputVolume;
}

#pragma mark Effect Methods

- (void)setDistortionWetDryMix:(float)distortionWetDryMix
{
    _distortion.wetDryMix = distortionWetDryMix * 100.0;
}

- (float)distortionWetDryMix
{
    return _distortion.wetDryMix/100.0;
}

- (void)setDistortionPreset:(NSInteger)distortionPreset
{
    if (_distortion) {
        [_distortion loadFactoryPreset:distortionPreset];
    }
}

- (void)setReverbWetDryMix:(float)reverbWetDryMix
{
    _reverb.wetDryMix = reverbWetDryMix * 100.0;
}

- (float)reverbWetDryMix
{
    return _reverb.wetDryMix/100.0;
}

- (void)setReverbPreset:(NSInteger)reverbPreset
{
    if (_reverb) {
        [_reverb loadFactoryPreset:reverbPreset];
    }
}

#pragma mark player Methods

- (BOOL)playerIsPlaying
{
    return _player.isPlaying;
}

- (void)setPlayerVolume:(float)playerVolume
{
    _player.volume = playerVolume;
}

- (void)setPlayerPan:(float)playerPan
{
    _player.pan = playerPan;
}

- (float)playerVolume
{
    return _player.volume;
}

- (float)playerPan
{
    return _player.pan;
}

- (void)togglePlayer
{
    if (!self.playerIsPlaying)
    {
        [self startEngine];
        [self schedulePlayerContent];
        [_player play];
    }
    else
    {
        [_player stop];
    }
}

- (void)toggleBuffer:(BOOL)recordBuffer
{
    _isRecordingSelected = recordBuffer;
    
    if (self.playerIsPlaying)
    {
        [_player stop];
        [self startEngine]; //start the engine if it's not already started
        [self schedulePlayerContent];
        [_player play];
    }
    else
    {
        [self schedulePlayerContent];
    }
}

- (void)schedulePlayerContent
{
    //schedule the appropriate content
    if (_isRecordingSelected)
    {
        AVAudioFile *recording = [self createAudioFileForPlayback];
        [_player scheduleFile:recording atTime:nil completionHandler:nil];
    }
    else
    {
        [_player scheduleBuffer:_playerLoopBuffer atTime:nil options:AVAudioPlayerNodeBufferLoops completionHandler:nil];
    }
}

- (AVAudioFile*)createAudioFileForPlayback
{
    NSError *error = nil;
    AVAudioFile *recording =[[AVAudioFile alloc] initForReading:_mixerOutputFileURL error:&error];
    NSAssert(recording, @"couldn't create AVAudioFile, %@", [error localizedDescription]);
    return recording;
}

#pragma mark Recording Methods

- (void)startRecordingMixerOutput
{
    // install a tap on the main mixer output bus and write output buffers to file
    
    /*  The method installTapOnBus:bufferSize:format:block: will create a "tap" to record/monitor/observe the output of the node.
	
        @param bus
            the node output bus to which to attach the tap
        @param bufferSize
            the requested size of the incoming buffers. The implementation may choose another size.
        @param format
            If non-nil, attempts to apply this as the format of the specified output bus. This should
            only be done when attaching to an output bus which is not connected to another node; an
            error will result otherwise.
            The tap and connection formats (if non-nil) on the specified bus should be identical. 
            Otherwise, the latter operation will override any previously set format.
            Note that for AVAudioOutputNode, tap format must be specified as nil.
        @param tapBlock
            a block to be called with audio buffers

		Only one tap may be installed on any bus. Taps may be safely installed and removed while
		the engine is running. */
    
    NSError *error;
    if (!_mixerOutputFileURL) _mixerOutputFileURL = [NSURL URLWithString:[NSTemporaryDirectory() stringByAppendingString:@"mixerOutput.caf"]];
    
    AVAudioMixerNode *mainMixer = [_engine mainMixerNode];
    AVAudioFile *mixerOutputFile = [[AVAudioFile alloc] initForWriting:_mixerOutputFileURL settings:[[mainMixer outputFormatForBus:0] settings] error:&error];
    NSAssert(mixerOutputFile != nil, @"mixerOutputFile is nil, %@", [error localizedDescription]);
    
    [self startEngine];
    [mainMixer installTapOnBus:0 bufferSize:4096 format:[mainMixer outputFormatForBus:0] block:^(AVAudioPCMBuffer *buffer, AVAudioTime *when) {
        NSError *error;
        BOOL success = NO;
        
        // as AVAudioPCMBuffer's are delivered this will write sequentially. The buffer's frameLength signifies how much of the buffer is to be written
        // IMPORTANT: The buffer format MUST match the file's processing format which is why outputFormatForBus: was used when creating the AVAudioFile object above
        success = [mixerOutputFile writeFromBuffer:buffer error:&error];
        NSAssert(success, @"error writing buffer data to file, %@", [error localizedDescription]);
    }];
    _isRecording = YES;
}

- (void)stopRecordingMixerOutput
{
    if (_isRecording) {
        [[_engine mainMixerNode] removeTapOnBus:0];
        _isRecording = NO;
        
        if (self.recordingIsAvailable) {            
            //Post a notificaiton that the record is complete
            //Other nodes/objects can listen to this update accordingly
            [[NSNotificationCenter defaultCenter] postNotificationName:kRecordingCompletedNotification object:nil];
        }
    }
}

- (BOOL)recordingIsAvailable
{
    return (_mixerOutputFileURL != nil);
}

#pragma mark AVAudioSession

- (void)initAVAudioSession
{
    // Configure the audio session
    AVAudioSession *sessionInstance = [AVAudioSession sharedInstance];
    NSError *error;
    
    // set the session category
    bool success = [sessionInstance setCategory:AVAudioSessionCategoryPlayback error:&error];
    if (!success) NSLog(@"Error setting AVAudioSession category! %@\n", [error localizedDescription]);
    
    double hwSampleRate = 44100.0;
    success = [sessionInstance setPreferredSampleRate:hwSampleRate error:&error];
    if (!success) NSLog(@"Error setting preferred sample rate! %@\n", [error localizedDescription]);
    
    NSTimeInterval ioBufferDuration = 0.0029;
    success = [sessionInstance setPreferredIOBufferDuration:ioBufferDuration error:&error];
    if (!success) NSLog(@"Error setting preferred io buffer duration! %@\n", [error localizedDescription]);
    
    // add interruption handler
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleInterruption:)
                                                 name:AVAudioSessionInterruptionNotification
                                               object:sessionInstance];
    
    // we don't do anything special in the route change notification
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleRouteChange:)
                                                 name:AVAudioSessionRouteChangeNotification
                                               object:sessionInstance];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleMediaServicesReset:)
                                                 name:AVAudioSessionMediaServicesWereResetNotification
                                               object:sessionInstance];
    
    // activate the audio session
    success = [sessionInstance setActive:YES error:&error];
    if (!success) NSLog(@"Error setting session active! %@\n", [error localizedDescription]);
}

- (void)handleInterruption:(NSNotification *)notification
{
    UInt8 theInterruptionType = [[notification.userInfo valueForKey:AVAudioSessionInterruptionTypeKey] intValue];
    
    NSLog(@"Session interrupted > --- %s ---\n", theInterruptionType == AVAudioSessionInterruptionTypeBegan ? "Begin Interruption" : "End Interruption");
    
    if (theInterruptionType == AVAudioSessionInterruptionTypeBegan) {
        _isSessionInterrupted = YES;
        [_player stop];
        [_sequencer stop];
        [self stopRecordingMixerOutput];
    
        if ([self.delegate respondsToSelector:@selector(engineWasInterrupted)]) {
            [self.delegate engineWasInterrupted];
        }
    }
    if (theInterruptionType == AVAudioSessionInterruptionTypeEnded) {
        // make sure to activate the session
        NSError *error;
        bool success = [[AVAudioSession sharedInstance] setActive:YES error:&error];
        if (!success)
            NSLog(@"AVAudioSession set active failed with error: %@", [error localizedDescription]);
        else {
            _isSessionInterrupted = NO;
            if (_isConfigChangePending) {
                //there is a pending config changed notification
                NSLog(@"Responding to earlier engine config changed notification. Re-wiring connections and starting once again");
                [self makeEngineConnections];
                [self startEngine];
                
                _isConfigChangePending = NO;
            }
            else {
                // start the engine once again
                [self startEngine];
            }
        }
    }
}

- (void)handleRouteChange:(NSNotification *)notification
{
    UInt8 reasonValue = [[notification.userInfo valueForKey:AVAudioSessionRouteChangeReasonKey] intValue];
    AVAudioSessionRouteDescription *routeDescription = [notification.userInfo valueForKey:AVAudioSessionRouteChangePreviousRouteKey];
    
    NSLog(@"Route change:");
    switch (reasonValue) {
        case AVAudioSessionRouteChangeReasonNewDeviceAvailable:
            NSLog(@"     NewDeviceAvailable");
            break;
        case AVAudioSessionRouteChangeReasonOldDeviceUnavailable:
            NSLog(@"     OldDeviceUnavailable");
            break;
        case AVAudioSessionRouteChangeReasonCategoryChange:
            NSLog(@"     CategoryChange");
            NSLog(@"     New Category: %@", [[AVAudioSession sharedInstance] category]);
            break;
        case AVAudioSessionRouteChangeReasonOverride:
            NSLog(@"     Override");
            break;
        case AVAudioSessionRouteChangeReasonWakeFromSleep:
            NSLog(@"     WakeFromSleep");
            break;
        case AVAudioSessionRouteChangeReasonNoSuitableRouteForCategory:
            NSLog(@"     NoSuitableRouteForCategory");
            break;
        default:
            NSLog(@"     ReasonUnknown");
    }
    
    NSLog(@"Previous route:\n");
    NSLog(@"%@", routeDescription);
}

- (void)handleMediaServicesReset:(NSNotification *)notification
{
    // if we've received this notification, the media server has been reset
    // re-wire all the connections and start the engine
    NSLog(@"Media services have been reset!");
    NSLog(@"Re-wiring connections and starting once again");

    _sequencer = nil; //remove this sequencer since it's linked to the old AVAudioEngine
    [self initAVAudioSession];
    [self createEngineAndAttachNodes];
    [self makeEngineConnections];
    [self createAndSetupSequencer]; //recreate the sequencer with the new AVAudioEngine
    [self startEngine];

    // notify the delegate
    if ([self.delegate respondsToSelector:@selector(engineConfigurationHasChanged)]) {
        [self.delegate engineConfigurationHasChanged];
    }
}

@end
