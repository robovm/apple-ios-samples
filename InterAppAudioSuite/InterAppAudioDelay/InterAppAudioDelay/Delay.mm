/*
     File: Delay.mm
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

#import "Delay.h"

void AudioUnitPropertyChangeDispatcher(void *inRefCon, AudioUnit inUnit, AudioUnitPropertyID inID, AudioUnitScope inScope, AudioUnitElement inElement) {
	Delay *SELF = (Delay *)inRefCon;
    [SELF audioUnitPropertyChangedListener:inRefCon unit:inUnit propID:inID scope:inScope element:inElement];
}

NSString *kTransportStateChangedNotification = @"kTransportStateChangedNotification";

#define Check(expr) do { OSStatus err = (expr); if (err) { NSLog(@"error %d from %s", (int)err, #expr); abort(); } } while (0)
#define NSCheck(expr) do { NSError *err = nil; if (!(expr)) { NSLog(@"error from %s: %@", #expr, err);  abort(); } } while (0)
#define kSampleRate 44100.0

@implementation Delay

#pragma mark Initialization/dealloc
- (id) init {
    self = [super init];
    if (self) {
        self.connected	= NO;
        self.playing	= NO;
        self.recording	= NO;
		
		UIApplicationState appstate = [UIApplication sharedApplication].applicationState;
        inForeground = (appstate != UIApplicationStateBackground);
        
        [[NSNotificationCenter defaultCenter] addObserver: self
                                                 selector: @selector(appHasGoneInBackground)
                                                     name: UIApplicationDidEnterBackgroundNotification
                                                   object: nil];
		
        [[NSNotificationCenter defaultCenter] addObserver: self
                                                 selector: @selector(appHasGoneForeground)
                                                     name: UIApplicationWillEnterForegroundNotification
                                                   object: nil];
		
		// This notification will typically not be posted in normal circumstances because our app supports
		// being a background app.  However, in the unlikely event that our app needs to be terminated, we
		// need to cleanup the graph
		[[NSNotificationCenter defaultCenter] addObserver: self
												 selector: @selector(cleanup)
													 name: UIApplicationWillTerminateNotification
												   object: nil];

        [self setupStereoStreamFormat];
        [self createAndPublish];
		
		//If media services get reset republish output node
		[[NSNotificationCenter defaultCenter] addObserverForName:AVAudioSessionMediaServicesWereResetNotification object: nil queue: nil usingBlock: ^(NSNotification *note) {
			
			//Throw away entire engine and rebuild like starting the app from scratch
			[self cleanup];
			[self createAndPublish];
		}];
    }
    return self;
}

- (void) dealloc {
    if (callBackInfo)
        free(callBackInfo);
    
    [super dealloc];
}

-(void) cleanup {	// throw away engine state
	[self stopGraph];
	[self setAudioSessionInActive];
	
	AUGraphClose(delayGraph);
	DisposeAUGraph(delayGraph);	// this will also cleanup any listeners that have been registered. If you are using AURemoteIO instead of AUGraph, you should make sure you cleanup that instead
	
	delayGraph = nil;
}


#pragma mark Properties
@synthesize audioUnitIcon = _audioUnitIcon;

#pragma mark CAUITransportEngine Protocol- Required properties
@synthesize playing   = _playing;
@synthesize recording = _recording;
@synthesize connected = _connected;
@synthesize playTime  = _playTime;

#pragma mark CAUITransportEngine Protocol- Required methods
- (BOOL) canPlay    { return [self isHostConnected]; }
- (BOOL) canRewind  { return [self isHostConnected]; }
- (BOOL) canRecord  { return outputUnit != nil && ![self isHostPlaying]; }

- (BOOL) isHostPlaying  { return self.playing; }
- (BOOL) isHostRecording    { return self.recording; }
- (BOOL) isHostConnected {
    if (outputUnit) {
        UInt32 connect;
        UInt32 dataSize = sizeof(UInt32);
        Check(AudioUnitGetProperty(outputUnit, kAudioUnitProperty_IsInterAppConnected, kAudioUnitScope_Global, 0, &connect, &dataSize));
        if ((BOOL)connect != self.connected) {
            self.connected = connect;
            //Transition is from not connected to connected
            if (self.connected) {
                [self checkStartStopGraph];
                //Get the appropriate callback info
                [self getHostCallBackInfo];
                [self getAudioUnitIcon];
            }
            //Transition is from connected to not connected;
            else 
                [self checkStartStopGraph];
        }
    }
    return self.connected;
}

- (void) togglePlay {
    [self sendStateToRemoteHost:kAudioUnitRemoteControlEvent_TogglePlayPause];
    [[NSNotificationCenter defaultCenter] postNotificationName:kTransportStateChangedNotification object:self];
}

- (void) toggleRecord {
    [self sendStateToRemoteHost:kAudioUnitRemoteControlEvent_ToggleRecord];
    [[NSNotificationCenter defaultCenter] postNotificationName:kTransportStateChangedNotification object:self];
}

- (void) rewind {
    [self sendStateToRemoteHost:kAudioUnitRemoteControlEvent_Rewind];
    [[NSNotificationCenter defaultCenter] postNotificationName:kTransportStateChangedNotification object:self];
}

//Fetch the host's icon via AudioOutputUnitGetHostIcon, draw that in the view
- (UIImage *) getAudioUnitIcon {
    if (outputUnit)
        self.audioUnitIcon = [scaleImageToSize(AudioOutputUnitGetHostIcon(outputUnit, 114), CGSizeMake(41, 41))retain] ;
    
    return self.audioUnitIcon;
}

- (NSString*) getPlayTimeString {
    [self updateStatefromTransportCallBack];
    return formattedTimeStringForFrameCount(self.playTime, [[AVAudioSession sharedInstance] sampleRate], NO);
}

- (void) gotoHost {
    if (outputUnit) {
        CFURLRef instrumentUrl;
        UInt32 dataSize = sizeof(instrumentUrl);
        OSStatus result = AudioUnitGetProperty(outputUnit, 102 /* kAudioUnitProperty_PeerURL */, kAudioUnitScope_Global, 0, &instrumentUrl, &dataSize);
        if (result == noErr)
            [[UIApplication sharedApplication] openURL:(NSURL*)instrumentUrl];
    }
}

- (BOOL) isPlaying { return self.playing; }
- (BOOL) isRecording { return self.recording; }

- (void) getHostCallBackInfo {
    if (self.connected) {
        if (callBackInfo)
            free(callBackInfo);
        UInt32 dataSize = sizeof(HostCallbackInfo);
        callBackInfo = (HostCallbackInfo*) malloc(dataSize);
        OSStatus result = AudioUnitGetProperty(outputUnit, kAudioUnitProperty_HostCallbacks, kAudioUnitScope_Global, 0, callBackInfo, &dataSize);
        if (result != noErr) {
            free(callBackInfo);
            callBackInfo = NULL;
        }
    }
}

- (void) sendStateToRemoteHost:(AudioUnitRemoteControlEvent) state {
    if (outputUnit) {
        UInt32 controlEvent = state;
        UInt32 dataSize = sizeof(controlEvent);
        Check(AudioUnitSetProperty(outputUnit, kAudioOutputUnitProperty_RemoteControlToHost, kAudioUnitScope_Global, 0, &controlEvent, dataSize));
    }
}

#pragma mark Application State Handling methods
- (void) appHasGoneInBackground {
    inForeground = NO;
    [self checkStartStopGraph];
}

- (void) appHasGoneForeground {
    inForeground = YES;
    [self isHostConnected];
    [self checkStartStopGraph];
    [self updateStatefromTransportCallBack];
}

- (void) updateStatefromTransportCallBack {
    if ([self isHostConnected] && inForeground) {
        if (!callBackInfo)
            [self getHostCallBackInfo];
        if (callBackInfo) {
            Boolean isPlaying   = self.playing;
            Boolean isRecording = self.recording;
            Float64 outCurrentSampleInTimeLine = 0;
            void * hostUserData = callBackInfo->hostUserData;
            OSStatus result =  callBackInfo->transportStateProc2(hostUserData,
																 &isPlaying,
																 &isRecording, NULL,
																 &outCurrentSampleInTimeLine,
																 NULL, NULL, NULL);
            if (result == noErr) {
                self.playing   = isPlaying;
                self.recording = isRecording;
                self.playTime  = outCurrentSampleInTimeLine;
            }
        }
    }
}

#pragma mark Publishing methods
- (void) createAndPublish {
    [self createGraph];
    [self addAudioUnitPropertyListener];
    [self publishOutputAudioUnit];
    [self checkStartStopGraph];
}

- (void) addAudioUnitPropertyListener {
    Check(AudioUnitAddPropertyListener(outputUnit,
                                       kAudioUnitProperty_IsInterAppConnected,
                                       AudioUnitPropertyChangeDispatcher,
                                       self));
    Check(AudioUnitAddPropertyListener(outputUnit,
                                       kAudioOutputUnitProperty_HostTransportState,
                                       AudioUnitPropertyChangeDispatcher,
                                       self));
}

- (void) publishOutputAudioUnit {
	AudioComponentDescription desc = { kAudioUnitType_RemoteEffect, 'iasd', 'appl', 0, 0 };
	AudioOutputUnitPublish(&desc, CFSTR("IAA Delay Demo"), 0, outputUnit);
}

- (BOOL) isGraphStarted {
    if (delayGraph) {
        Check(AUGraphIsRunning (delayGraph, &graphStarted));
        return graphStarted;
    } else 
        graphStarted = NO;
    return graphStarted;
}

- (void) postUpdateStateNotification {
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:kTransportStateChangedNotification object:self];
    });
}

- (void) audioUnitPropertyChangedListener:(void *) inObject unit:(AudioUnit) inUnit propID:(AudioUnitPropertyID) inID scope:(AudioUnitScope) inScope element:(AudioUnitElement) inElement {
    if (inID == kAudioUnitProperty_IsInterAppConnected) {
        [self isHostConnected];
        [self postUpdateStateNotification];
    } else if (inID == kAudioOutputUnitProperty_HostTransportState) {
        [self updateStatefromTransportCallBack];
        [self postUpdateStateNotification];
    }
}

#pragma mark Graph management
- (void) createGraph {
    // Create a new audio processing graph.
    Check(NewAUGraph (&delayGraph));
    
    // Specify the audio unit component descriptions for the initial units to be
    // added to the graph.
    // I/O unit
    AudioComponentDescription iOUnitDescription;
    iOUnitDescription.componentManufacturer = kAudioUnitManufacturer_Apple;
    iOUnitDescription.componentFlags = 0;
    iOUnitDescription.componentFlagsMask = 0;
    iOUnitDescription.componentType = kAudioUnitType_Output;
    iOUnitDescription.componentSubType = kAudioUnitSubType_RemoteIO;
    
    //Delay audio unit
    AudioComponentDescription delayUnitDescription;
    delayUnitDescription.componentManufacturer = kAudioUnitManufacturer_Apple;
    delayUnitDescription.componentFlags = 0;
    delayUnitDescription.componentFlagsMask = 0;
    delayUnitDescription.componentType = kAudioUnitType_Effect;
    delayUnitDescription.componentSubType = kAudioUnitSubType_Delay;
    
    // Add the nodes to the audio processing graph
    //Add I/O node
    Check(AUGraphAddNode(delayGraph, &iOUnitDescription, &outNode));
    //Add delay node
    Check(AUGraphAddNode(delayGraph, &delayUnitDescription, &delayNode));
    
    //Open the graph
    Check(AUGraphOpen(delayGraph));
    
    //Grab the output audioUnit from the graph
    Check(AUGraphNodeInfo(delayGraph, outNode, 0, &outputUnit));
    //Grab the output mixerUnit from the graph
    Check(AUGraphNodeInfo(delayGraph, delayNode, 0, &delayUnit));
    
    // Enable IO for recording
    UInt32 flag = 1;
    Check(AudioUnitSetProperty(outputUnit,
                               kAudioOutputUnitProperty_EnableIO,
                               kAudioUnitScope_Input,
                               1, // Remote IO bus 1 is used to get audio input
                               &flag,
                               sizeof(flag)));
    
    // Enable IO for playback
    Check(AudioUnitSetProperty(outputUnit,
                               kAudioOutputUnitProperty_EnableIO,
                               kAudioUnitScope_Output,
                               0,// Remote IO bus 0 is used for the output side,
                               &flag,
                               sizeof(flag)));
    
	// Set stereo format
    Check(AudioUnitSetProperty(delayUnit,
                               kAudioUnitProperty_StreamFormat,
                               kAudioUnitScope_Output,
                               0,
                               &stereoStreamFormat,
                               sizeof(stereoStreamFormat)));

    //Set stereo format
    Check(AudioUnitSetProperty(outputUnit,
                               kAudioUnitProperty_StreamFormat,
                               kAudioUnitScope_Output,
                               1,
                               &stereoStreamFormat,
                               sizeof(stereoStreamFormat)));
    
    UInt32 maxFrames = 4096;
    Check(AudioUnitSetProperty(outputUnit,
                               kAudioUnitProperty_MaximumFramesPerSlice,
                               kAudioUnitScope_Global,
                               0,
                               &maxFrames,
                               sizeof(maxFrames)));
								
    // Connect the nodes of the audio processing graph
    //delayNode to output. Remote IO bus 0 is used for the output side,
	Check(AUGraphConnectNodeInput (delayGraph, delayNode, 0, outNode, 0));
    //delayNode to output. Remote IO bus 1 is used to get audio input
	Check(AUGraphConnectNodeInput (delayGraph, outNode, 1, delayNode, 0));
}

- (void) startGraph {
    if (!graphStarted) {
        if (delayGraph) {
            Check(AUGraphStart(delayGraph));
            graphStarted = YES;
        }
    }
}

- (void) stopGraph {
    if (graphStarted) {
        if (delayGraph) {
            Check(AUGraphStop(delayGraph));
            graphStarted = NO;
        }
    }
}

- (void) setupStereoStreamFormat {
    stereoStreamFormat.mChannelsPerFrame = 2; // stereo
    stereoStreamFormat.mSampleRate       = [[AVAudioSession sharedInstance] sampleRate];
    stereoStreamFormat.mFormatID 		 = kAudioFormatLinearPCM;
    stereoStreamFormat.mFormatFlags 	 = kAudioFormatFlagsNativeFloatPacked | kAudioFormatFlagIsNonInterleaved;
    stereoStreamFormat.mBytesPerFrame 	 = stereoStreamFormat.mBytesPerPacket = sizeof(Float32);
    stereoStreamFormat.mBitsPerChannel 	 = 32;
    stereoStreamFormat.mFramesPerPacket  = 1;
}

- (void) setAudioSessionActive {
    AVAudioSession *session = [AVAudioSession sharedInstance];
    NSCheck([session setPreferredSampleRate: kSampleRate error:&err]);
    NSCheck([session setCategory: AVAudioSessionCategoryPlayback withOptions: AVAudioSessionCategoryOptionMixWithOthers error:&err]);
    NSCheck([session setActive: YES error:&err]);
}

- (void) setAudioSessionInActive {
    AVAudioSession *session = [AVAudioSession sharedInstance];
    NSCheck([session setActive: NO error:&err]);
}

- (void) checkStartStopGraph {
    if (self.connected) {
        if (![self isGraphStarted]) {
            [self setAudioSessionActive];
            //Initialize the graph if it hasn't been already
            if (delayGraph) {
                Boolean initialized = YES;
                Check(AUGraphIsInitialized(delayGraph, &initialized));
                if (!initialized)
                    Check (AUGraphInitialize (delayGraph));
            }
            [self startGraph];
        }
    } else if (!inForeground) {
        if ([self isGraphStarted]) {
            [self stopGraph];
            [self setAudioSessionInActive];
        }
    }
}

#pragma mark Parameter methods
- (float) wetDryMix {
    return [self valueForParam:kDelayParam_WetDryMix];
}

- (NSTimeInterval) delayTime {
    return [self valueForParam:kDelayParam_DelayTime];
}

- (float) feedback {
    return [self valueForParam:kDelayParam_Feedback];
}

- (float) lowPassCutoff {
    return [self valueForParam:kDelayParam_LopassCutoff];
}

- (void) setWetDryMix:(float) wetDryMix {
    [self setValue:wetDryMix forParam:kDelayParam_WetDryMix];
}

- (void) setDelayTime:(NSTimeInterval) delayTime {
    [self setValue:delayTime forParam:kDelayParam_DelayTime];
}

- (void) setFeedback:(float) feedback {
    [self setValue:feedback forParam:kDelayParam_Feedback];
}

- (void) setLowPassCutoff:(float) lowPassCutoff {
    [self setValue:lowPassCutoff forParam:kDelayParam_LopassCutoff];
}

- (BOOL) setValue:(float )value forParam:(AudioUnitParameterID) paramID {
    if (delayUnit) {
        Check(AudioUnitSetParameter(delayUnit, paramID, kAudioUnitScope_Global, 0, value, 0));
        return YES;
    }
    return NO;
}

- (float) valueForParam:(AudioUnitParameterID) paramID {
    float returnVal = 0.0;
    if (delayUnit) {
        Check(AudioUnitGetParameter(delayUnit, paramID, kAudioUnitScope_Global, 0, &returnVal));
    }
    return returnVal;
}

- (int) getWetDryTag {
    return kDelayParam_WetDryMix;
}

- (int) getDelayTag {
    return kDelayParam_DelayTime;
}

- (int) getFeedbackTag {
    return kDelayParam_Feedback;
}

- (int) getLowPassCutoffTag {
    return kDelayParam_LopassCutoff;
}

- (float) getMaxValueForParam:(AudioUnitParameterID) paramID {
    float returnVal = 0.0;
    AudioUnitParameterInfo *info = [self getInfoForParam:paramID];
    if (info) {
        returnVal = info->maxValue;
        free(info);
    }
    return returnVal;
}

- (float) getMinValueForParam:(AudioUnitParameterID) paramID {
    float returnVal = 0.0;
    AudioUnitParameterInfo *info = [self getInfoForParam:paramID];
    if (info) {
        returnVal = info->minValue;
        free(info);
    }
    return returnVal;
}

- (AudioUnitParameterInfo*) getInfoForParam:(AudioUnitParameterID) paramID {
    AudioUnitParameterInfo *info = NULL;
    if (delayUnit) {
        UInt32 propertySize = sizeof(AudioUnitParameterInfo);
        info = (AudioUnitParameterInfo*) malloc(propertySize);//Review, this means the user of this function needs to free
        Check(AudioUnitGetProperty(delayUnit, kAudioUnitProperty_ParameterInfo, 0, paramID, info, &propertySize));
    }
    return info;
}

#pragma mark Utility functions
void displayAlertDialog(NSString *title, NSString *message)
{
    UIAlertView *alert =
    [[UIAlertView alloc] initWithTitle: title
                               message: message
                              delegate: nil
                     cancelButtonTitle: @"OK"
                     otherButtonTitles: nil];
    [alert show];
    [alert release];
    return;
}

NSString *formattedTimeStringForFrameCount(UInt64 inFrameCount, Float64 inSampleRate, BOOL inShowMilliseconds) {
	UInt32 hours = 0;
	UInt32 minutes = 0;
	UInt32 seconds = 0;
	UInt32 milliseconds = 0;
    
	// calculate pieces
	if ((inFrameCount != 0) && (inSampleRate != 0)) {
		Float64 absoluteSeconds = (Float64)inFrameCount / inSampleRate;
		UInt64 absoluteIntSeconds = (UInt64) absoluteSeconds;
		
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

UIImage *scaleImageToSize(UIImage *image, CGSize newSize) {
    UIGraphicsBeginImageContextWithOptions(newSize, NO, 0.0);
    [image drawInRect:CGRectMake(0, 0, newSize.width, newSize.height)];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return newImage;
}

@end
