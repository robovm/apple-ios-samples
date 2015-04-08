/*
    Copyright (C) 2015 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    AudioEngine is the main controller class that creates the following objects:
                    AVAudioEngine       *_engine;
                    AVAudioPlayerNode   *_marimbaPlayer;
                    AVAudioPlayerNode   *_drumPlayer;
                    AVAudioUnitDelay    *_delay;
                    AVAudioUnitReverb   *_reverb;
                    AVAudioPCMBuffer    *_marimbaLoopBuffer;
                    AVAudioPCMBuffer    *_drumLoopBuffer;
                    
                 It connects all the nodes, loads the buffers as well as controls the AVAudioEngine object itself.
*/

#import "AudioEngine.h"

@import AVFoundation;
@import Accelerate;

#pragma mark AudioEngine class extensions

@interface AudioEngine() {
    AVAudioEngine       *_engine;
    AVAudioPlayerNode   *_marimbaPlayer;
    AVAudioPlayerNode   *_drumPlayer;
    AVAudioUnitDelay    *_delay;
    AVAudioUnitReverb   *_reverb;
    AVAudioPCMBuffer    *_marimbaLoopBuffer;
    AVAudioPCMBuffer    *_drumLoopBuffer;
    
    // for the node tap
    NSURL               *_mixerOutputFileURL;
    AVAudioPlayerNode   *_mixerOutputFilePlayer;
    BOOL                _mixerOutputFilePlayerIsPaused;
    BOOL                _isRecording;
}

- (void)handleInterruption:(NSNotification *)notification;
- (void)handleRouteChange:(NSNotification *)notification;

@end

#pragma mark AudioEngine implementation

@implementation AudioEngine

- (instancetype)init
{
    if (self = [super init]) {
        // create the various nodes
        
        /*  AVAudioPlayerNode supports scheduling the playback of AVAudioBuffer instances,
            or segments of audio files opened via AVAudioFile. Buffers and segments may be
            scheduled at specific points in time, or to play immediately following preceding segments. */
        
        _marimbaPlayer = [[AVAudioPlayerNode alloc] init];
        _drumPlayer = [[AVAudioPlayerNode alloc] init];
        
        /*  A delay unit delays the input signal by the specified time interval
            and then blends it with the input signal. The amount of high frequency
            roll-off can also be controlled in order to simulate the effect of
            a tape delay. */
        
        _delay = [[AVAudioUnitDelay alloc] init];
        
        /*  A reverb simulates the acoustic characteristics of a particular environment.
            Use the different presets to simulate a particular space and blend it in with
            the original signal using the wetDryMix parameter. */
        
        _reverb = [[AVAudioUnitReverb alloc] init];
        
        
        _mixerOutputFilePlayer = [[AVAudioPlayerNode alloc] init];
        
        _mixerOutputFileURL = nil;
        _mixerOutputFilePlayerIsPaused = NO;
        _isRecording = NO;
        
        // create an instance of the engine and attach the nodes
        [self createEngineAndAttachNodes];
        
        NSError *error;
        
        // load marimba loop
        NSURL *marimbaLoopURL = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"marimbaLoop" ofType:@"caf"]];
        AVAudioFile *marimbaLoopFile = [[AVAudioFile alloc] initForReading:marimbaLoopURL error:&error];
        _marimbaLoopBuffer = [[AVAudioPCMBuffer alloc] initWithPCMFormat:[marimbaLoopFile processingFormat] frameCapacity:(AVAudioFrameCount)[marimbaLoopFile length]];
        NSAssert([marimbaLoopFile readIntoBuffer:_marimbaLoopBuffer error:&error], @"couldn't read marimbaLoopFile into buffer, %@", [error localizedDescription]);
        
        // load drum loop
        NSURL *drumLoopURL = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"drumLoop" ofType:@"caf"]];
        AVAudioFile *drumLoopFile = [[AVAudioFile alloc] initForReading:drumLoopURL error:&error];
        _drumLoopBuffer = [[AVAudioPCMBuffer alloc] initWithPCMFormat:[drumLoopFile processingFormat] frameCapacity:(AVAudioFrameCount)[drumLoopFile length]];
        NSAssert([drumLoopFile readIntoBuffer:_drumLoopBuffer error:&error], @"couldn't read drumLoopFile into buffer, %@", [error localizedDescription]);
        
        // sign up for notifications from the engine if there's a hardware config change
        [[NSNotificationCenter defaultCenter] addObserverForName:AVAudioEngineConfigurationChangeNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *note) {
            
            // if we've received this notification, something has changed and the engine has been stopped
            // re-wire all the connections and start the engine
            NSLog(@"Received a %@ notification!", AVAudioEngineConfigurationChangeNotification);
            NSLog(@"Re-wiring connections and starting once again");
            [self makeEngineConnections];
            [self startEngine];
            
            // post notification
            if ([self.delegate respondsToSelector:@selector(engineConfigurationHasChanged)]) {
                [self.delegate engineConfigurationHasChanged];
            }
        }];
        
        // AVAudioSession setup
        [self initAVAudioSession];
        
        // make engine connections
        [self makeEngineConnections];
        
        // settings for effects units
        [_reverb loadFactoryPreset:AVAudioUnitReverbPresetMediumHall3];
        _delay.delayTime = 0.5;
        _delay.wetDryMix = 0.0;
        
        // start the engine
        [self startEngine];
    }
    return self;
}

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
    
    [_engine attachNode:_marimbaPlayer];
    [_engine attachNode:_drumPlayer];
    [_engine attachNode:_delay];
    [_engine attachNode:_reverb];
    [_engine attachNode:_mixerOutputFilePlayer];
}

- (void)makeEngineConnections
{
    /*  The engine will construct a singleton main mixer and connect it to the outputNode on demand,
		when this property is first accessed. You can then connect additional nodes to the mixer.
		
		By default, the mixer's output format (sample rate and channel count) will track the format 
		of the output node. You may however make the connection explicitly with a different format. */
    
    // get the engine's optional singleton main mixer node
    AVAudioMixerNode *mainMixer = [_engine mainMixerNode];
    
    // establish a connection between nodes
    
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
    
    // marimba player -> delay -> main mixer
    [_engine connect: _marimbaPlayer to:_delay format:_marimbaLoopBuffer.format];
    [_engine connect:_delay to:mainMixer format:_marimbaLoopBuffer.format];
    
    // drum player -> reverb -> main mixer
    [_engine connect:_drumPlayer to:_reverb format:_drumLoopBuffer.format];
    [_engine connect:_reverb to:mainMixer format:_drumLoopBuffer.format];
    
    // node tap player
    [_engine connect:_mixerOutputFilePlayer to:mainMixer format:[mainMixer outputFormatForBus:0]];
}

- (void)startEngine
{
    // start the engine
    
    /*  startAndReturnError: calls prepare if it has not already been called since stop.
	
		Starts the audio hardware via the AVAudioInputNode and/or AVAudioOutputNode instances in
		the engine. Audio begins flowing through the engine.
	
        This method will return YES for sucess.
     
		Reasons for potential failure include:
		
		1. There is problem in the structure of the graph. Input can't be routed to output or to a
			recording tap through converter type nodes.
		2. An AVAudioSession error.
		3. The driver failed to start the hardware. */
    
    NSError *error;
    NSAssert([_engine startAndReturnError:&error], @"couldn't start engine, %@", [error localizedDescription]);
}

- (void)toggleMarimba {
    if (!self.marimbaPlayerIsPlaying) {
        [_marimbaPlayer scheduleBuffer:_marimbaLoopBuffer atTime:nil options:AVAudioPlayerNodeBufferLoops completionHandler:nil];
        [_marimbaPlayer play];
    } else
        [_marimbaPlayer stop];
}

- (void)toggleDrums {
    if (!self.drumPlayerIsPlaying) {
        [_drumPlayer scheduleBuffer:_drumLoopBuffer atTime:nil options:AVAudioPlayerNodeBufferLoops completionHandler:nil];
        [_drumPlayer play];
    } else
        [_drumPlayer stop];
}

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
    
    if (!_engine.isRunning) [self startEngine];
    [mainMixer installTapOnBus:0 bufferSize:4096 format:[mainMixer outputFormatForBus:0] block:^(AVAudioPCMBuffer *buffer, AVAudioTime *when) {
        NSError *error;
        
        // as AVAudioPCMBuffer's are delivered this will write sequentially. The buffer's frameLength signifies how much of the buffer is to be written
        // IMPORTANT: The buffer format MUST match the file's processing format which is why outputFormatForBus: was used when creating the AVAudioFile object above
        NSAssert([mixerOutputFile writeFromBuffer:buffer error:&error], @"error writing buffer data to file, %@", [error localizedDescription]);
    }];
    _isRecording = true;
}

- (void)stopRecordingMixerOutput
{
    // stop recording really means remove the tap on the main mixer that was created in startRecordingMixerOutput
    if (_isRecording) {
        [[_engine mainMixerNode] removeTapOnBus:0];
        _isRecording = NO;
    }
}

- (void)playRecordedFile
{
    if (_mixerOutputFilePlayerIsPaused) {
        [_mixerOutputFilePlayer play];
    }
    else {
        if (_mixerOutputFileURL) {
            NSError *error;
            AVAudioFile *recordedFile = [[AVAudioFile alloc] initForReading:_mixerOutputFileURL error:&error];
            NSAssert(recordedFile != nil, @"recordedFile is nil, %@", [error localizedDescription]);
            [_mixerOutputFilePlayer scheduleFile:recordedFile atTime:nil completionHandler:^{
                _mixerOutputFilePlayerIsPaused = NO;
                
                // the data in the file has been scheduled but the player isn't actually done playing yet
                // calculate the approximate time remaining for the player to finish playing and then dispatch the notification to the main thread
                AVAudioTime *playerTime = [_mixerOutputFilePlayer playerTimeForNodeTime:_mixerOutputFilePlayer.lastRenderTime];
                double delayInSecs = (recordedFile.length - playerTime.sampleTime) / recordedFile.processingFormat.sampleRate;
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSecs * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    if ([self.delegate respondsToSelector:@selector(mixerOutputFilePlayerHasStopped)])
                        [self.delegate mixerOutputFilePlayerHasStopped];
                    [_mixerOutputFilePlayer stop];
                });
            }];
            [_mixerOutputFilePlayer play];
            _mixerOutputFilePlayerIsPaused = NO;
        }
    }
}

- (void)stopPlayingRecordedFile
{
    [_mixerOutputFilePlayer stop];
    _mixerOutputFilePlayerIsPaused = NO;
}

- (void)pausePlayingRecordedFile
{
    [_mixerOutputFilePlayer pause];
    _mixerOutputFilePlayerIsPaused = YES;
}

- (BOOL)marimbaPlayerIsPlaying
{
    return _marimbaPlayer.isPlaying;
}

- (BOOL)drumPlayerIsPlaying
{
    return _drumPlayer.isPlaying;
}

- (void)setMarimbaPlayerVolume:(float)marimbaPlayerVolume
{
    _marimbaPlayer.volume = marimbaPlayerVolume;
}

- (float)marimbaPlayerVolume
{
    return _marimbaPlayer.volume;
}

- (void)setDrumPlayerVolume:(float)drumPlayerVolume
{
    _drumPlayer.volume = drumPlayerVolume;
}

- (float)drumPlayerVolume
{
    return _drumPlayer.volume;
}

- (void)setOutputVolume:(float)outputVolume
{
    _engine.mainMixerNode.outputVolume = outputVolume;
}

- (float)outputVolume
{
    return _engine.mainMixerNode.outputVolume;
}

- (void)setMarimbaPlayerPan:(float)marimbaPlayerPan
{
    _marimbaPlayer.pan = marimbaPlayerPan;
}

- (float)marimbaPlayerPan
{
    return _marimbaPlayer.pan;
}

- (void)setDrumPlayerPan:(float)drumPlayerPan
{
    _drumPlayer.pan = drumPlayerPan;
}

- (float)drumPlayerPan
{
    return _drumPlayer.pan;
}

- (void)setDelayWetDryMix:(float)delayWetDryMix
{
    _delay.wetDryMix = delayWetDryMix * 100.0;
}

- (float)delayWetDryMix
{
    return _delay.wetDryMix/100.0;
}

- (void)setReverbWetDryMix:(float)reverbWetDryMix
{
    _reverb.wetDryMix = reverbWetDryMix * 100.0;
}

- (float)reverbWetDryMix
{
    return _reverb.wetDryMix/100.0;
}

- (void)setBypassDelay:(BOOL)bypassDelay
{
    _delay.bypass = bypassDelay;
}

- (BOOL)bypassDelay
{
    return _delay.bypass;
}

- (void)setBypassReverb:(BOOL)bypassReverb
{
    _reverb.bypass = bypassReverb;
}

- (BOOL)bypassReverb
{
    return _reverb.bypass;
}

#pragma mark AVAudioSession

- (void)initAVAudioSession
{
    // For complete details regarding the use of AVAudioSession see the AVAudioSession Programming Guide
    // https://developer.apple.com/library/ios/documentation/Audio/Conceptual/AudioSessionProgrammingGuide/Introduction/Introduction.html
    
    // Configure the audio session
    AVAudioSession *sessionInstance = [AVAudioSession sharedInstance];
    NSError *error;
    
    // set the session category
    bool success = [sessionInstance setCategory:AVAudioSessionCategoryPlayAndRecord error:&error];
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
        // the engine will pause itself
    }
    if (theInterruptionType == AVAudioSessionInterruptionTypeEnded) {
        // make sure to activate the session
        NSError *error;
        bool success = [[AVAudioSession sharedInstance] setActive:YES error:&error];
        if (!success) NSLog(@"AVAudioSession set active failed with error: %@", [error localizedDescription]);
        
        // start the engine once again
        [self startEngine];
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
            NSLog(@" New Category: %@", [[AVAudioSession sharedInstance] category]);
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
    
    [self createEngineAndAttachNodes];
    [self makeEngineConnections];
    [self startEngine];
    
    // post notification
    if ([self.delegate respondsToSelector:@selector(engineConfigurationHasChanged)]) {
        [self.delegate engineConfigurationHasChanged];
    }
}

@end
