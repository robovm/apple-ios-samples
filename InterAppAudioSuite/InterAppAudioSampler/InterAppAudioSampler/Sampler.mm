/*
     File: Sampler.mm
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

#import "Sampler.h"
#import <AVFoundation/AVAudioSession.h>
#import <AudioToolbox/AudioToolbox.h>

#define Check(expr) do { OSStatus err = (expr); if (err) { NSLog(@"error %d from %s", (int)err, #expr); abort(); } } while (0)
#define NSCheck(expr) do { NSError *err = nil; if (!(expr)) { NSLog(@"error from %s: %@", #expr, err);  abort(); } } while (0)

extern "C" NSString *kTransportStateChangedNotificiation;
extern "C" UIImage  *scaleImageToSize(UIImage *image, CGSize newSize);

//Use Category to hide private listener method used by c callback
@interface Sampler (Private)
-(void)audioUnitPropertyChangedListener:(void *) inObject unit:(AudioUnit) inUnit propID:(AudioUnitPropertyID) inID scope:(AudioUnitScope) inScope element:(AudioUnitElement) inElement;

-(OSStatus)sendMusicDeviceMIDIEvent:(UInt32) inStatus data1:(UInt32) inData1 data2:(UInt32) inData2 offsetSampleFrame:(UInt32) inOffsetSampleFrame;
@end

//Callback for audio units bouncing from c to objective c
void AudioUnitPropertyChangeDispatcher(void *inRefCon, AudioUnit inUnit, AudioUnitPropertyID inID, AudioUnitScope inScope, AudioUnitElement inElement) {
	Sampler *SELF = (Sampler *)inRefCon;
    [SELF audioUnitPropertyChangedListener:inRefCon unit:inUnit propID:inID scope:inScope element:inElement];
}

@implementation Sampler
{
@private
	NSURL		*bankURL;
	AUGraph		synthGraph;
	AudioUnit	synthUnit;
	AudioUnit	outputUnit;

	UInt32		patchNumber;
	Boolean		graphStarted;
    bool		inForeground;

	HostCallbackInfo *callBackInfo;
}

#pragma mark Initialization/dealloc
- (id) init {
    self = [super init];
    if (self) {
        // Do any additional setup after loading the view, typically from a nib.
        bankURL = [[NSURL alloc] initFileURLWithPath:[[NSBundle mainBundle] pathForResource:@"Vibraphone" ofType:@"aupreset"]];
        if (!bankURL)
			NSLog(@"[%@ %@] could not get bank path", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
        
		self.playing   = NO;
        self.recording = NO;
        UIApplicationState appstate = [UIApplication sharedApplication].applicationState;
		inForeground = (appstate != UIApplicationStateBackground);
    }
    return self;
}

- (void) dealloc {
    if (callBackInfo)
        free(callBackInfo);
    [bankURL release];
	
    [super dealloc];
}

-(void) cleanup {	// throw away engine state
	[self stopGraph];
	[self setAudioSessionInActive];
	
	AUGraphClose(synthGraph);
	DisposeAUGraph(synthGraph);	// this will also cleanup any listeners that have been registered. If you are using AURemoteIO instead of AUGraph, you should make sure you cleanup that instead
	
	synthGraph = nil;
}

#pragma mark Properties
@synthesize audioUnitIcon = _audioUnitIcon;

#pragma mark CAUITransportEngine Protocol- Required properties
@synthesize playing   = _playing;
@synthesize recording = _recording;
@synthesize connected = _connected;
@synthesize playTime  = _playTime;

#pragma mark CAUITransportEngine Protocol- Required methods
- (BOOL) canPlay   { return [self isHostConnected];}
- (BOOL) canRewind { return [self isHostConnected];}
- (BOOL) canRecord { return outputUnit != nil && ![self isHostPlaying]; }

- (BOOL) isHostPlaying   { return self.playing; }
- (BOOL) isHostRecording { return self.recording; }
- (BOOL) isHostConnected {
    if (outputUnit) {
        UInt32 connect;
        UInt32 dataSize = sizeof(UInt32);
        Check(AudioUnitGetProperty(outputUnit, kAudioUnitProperty_IsInterAppConnected, kAudioUnitScope_Global, 0, &connect, &dataSize));
        if (connect != self.connected) {
            self.connected = connect;
            //Transition is from not connected to connected
            if (self.connected) {
                [self checkStartStopGraph];
                //Get the appropriate callback info
                [self getHostCallBackInfo];
                [self getAudioUnitIcon];
            }
            //Transition is from connected to not connected;
            else {
                 //If the graph is started stop it.
                if ([self isGraphStarted])
                    [self stopGraph];
                //Attempt to restart the graph
                [self checkStartStopGraph];
            }
        }
    }
    return self.connected;
}

-(void) gotoHost {
    if (outputUnit) {
        CFURLRef instrumentUrl;
        UInt32 dataSize = sizeof(instrumentUrl);
        OSStatus result = AudioUnitGetProperty(outputUnit, kAudioUnitProperty_PeerURL, kAudioUnitScope_Global, 0, &instrumentUrl, &dataSize);
        if (result == noErr)
            [[UIApplication sharedApplication] openURL:(NSURL*)instrumentUrl];
    }
}

-(void) getHostCallBackInfo {
    if (self.connected) {
        if (callBackInfo)
            free(callBackInfo);
        UInt32 dataSize = sizeof(HostCallbackInfo);
        callBackInfo = (HostCallbackInfo*) malloc(dataSize);
        OSStatus result = AudioUnitGetProperty(outputUnit, kAudioUnitProperty_HostCallbacks, kAudioUnitScope_Global, 0, callBackInfo, &dataSize);
        if (result != noErr) {
            NSLog(@"Error occured fetching kAudioUnitProperty_HostCallbacks : %d", (int)result);
            free(callBackInfo);
            callBackInfo = NULL;
        }
    }
}

-(void) togglePlay {
    [self sendStateToRemoteHost:kAudioUnitRemoteControlEvent_TogglePlayPause];
    [[NSNotificationCenter defaultCenter] postNotificationName:kTransportStateChangedNotificiation object:self];
}

-(void) toggleRecord {
    [self sendStateToRemoteHost:kAudioUnitRemoteControlEvent_ToggleRecord];
    [[NSNotificationCenter defaultCenter] postNotificationName:kTransportStateChangedNotificiation object:self];
}

-(void) rewind {
    [self sendStateToRemoteHost:kAudioUnitRemoteControlEvent_Rewind];
    [[NSNotificationCenter defaultCenter] postNotificationName:kTransportStateChangedNotificiation object:self];
}

-(void) sendStateToRemoteHost:(AudioUnitRemoteControlEvent)state {
    if (outputUnit) {
        UInt32 controlEvent = state;
        UInt32 dataSize = sizeof(controlEvent);
        Check(AudioUnitSetProperty(outputUnit, kAudioOutputUnitProperty_RemoteControlToHost, kAudioUnitScope_Global, 0, &controlEvent, dataSize));
    }
}

//Fetch the host's icon via AudioOutputUnitGetHostIcon, draw that in the view
-(UIImage *) getAudioUnitIcon {
    if (outputUnit)
        self.audioUnitIcon = [scaleImageToSize(AudioOutputUnitGetHostIcon(outputUnit, 114), CGSizeMake(41, 41))retain] ;

	return self.audioUnitIcon;
}

- (NSString*) getPlayTimeString {
    [self updateStatefromTransportCallBack];
    return formattedTimeStringForFrameCount(self.playTime, [[AVAudioSession sharedInstance] sampleRate], NO);
}

#pragma mark CAUIKeyboardEngine Protocol- Required methods
-(AudioUnit) getAudioUnitInstrument {
    return synthUnit;
}

#pragma mark Publishing methods
-(void) connectAndPublishSampler {
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
    
    [self createAndPublish];
	
    //If media services get reset republish output node
    [[NSNotificationCenter defaultCenter] addObserverForName:AVAudioSessionMediaServicesWereResetNotification object: nil queue: nil usingBlock: ^(NSNotification *note) {
		
        //Throw away entire engine and rebuild like starting the app from scratch
		[self cleanup];
		[self createAndPublish];
    }];
}

-(void) createAndPublish {
    synthGraph = [self createAUGraphWithSampler:(CFURLRef)bankURL patchNumber:patchNumber synthUnit:&synthUnit outUnit:&outputUnit];
    [self addAudioUnitPropertyListener];
    [self publishOutputAudioUnit];
    [self checkStartStopGraph];
}

- (void) publishOutputAudioUnit {
	AudioComponentDescription desc = { kAudioUnitType_RemoteInstrument,'iasp','appl',0,0 };
	OSStatus result = AudioOutputUnitPublish(&desc, CFSTR("IAA Sampler Demo"), 0, outputUnit);
    if (result != noErr)
        NSLog(@"AudioOutputUnitPublish instrument result: %d", (int)result);
    
    desc = { kAudioUnitType_RemoteGenerator,'iasp','appl',0,0 };
    result = AudioOutputUnitPublish(&desc, CFSTR("IAA Sampler Demo"), 0, outputUnit);
    if (result != noErr)
        NSLog(@"AudioOutputUnitPublish generator result: %d", (int)result);
    [self setupMidiCallBacks:&outputUnit userData:self];
}

-(void) setupMidiCallBacks:(AudioUnit*)output userData:(void*)inUserData {
    AudioOutputUnitMIDICallbacks callBackStruct;
    callBackStruct.userData = inUserData;
    callBackStruct.MIDIEventProc = MIDIEventProcCallBack;
    callBackStruct.MIDISysExProc = NULL;
    Check(AudioUnitSetProperty (*output,
                                kAudioOutputUnitProperty_MIDICallbacks,
                                kAudioUnitScope_Global,
                                0,
                                &callBackStruct,
                                sizeof(callBackStruct)));
}

void MIDIEventProcCallBack(void *userData, UInt32 inStatus, UInt32 inData1, UInt32 inData2, UInt32 inOffsetSampleFrame){
    Sampler *SELF = (Sampler*)userData;
    [SELF sendMusicDeviceMIDIEvent:inStatus data1:inData1 data2:inData2 offsetSampleFrame:inOffsetSampleFrame];
}

-(void) addAudioUnitPropertyListener {
    Check(AudioUnitAddPropertyListener(outputUnit,
                                       kAudioUnitProperty_IsInterAppConnected,
                                       AudioUnitPropertyChangeDispatcher,
                                       self));
    Check(AudioUnitAddPropertyListener(outputUnit,
                                       kAudioOutputUnitProperty_HostTransportState,
                                       AudioUnitPropertyChangeDispatcher,
                                       self));
}

#pragma mark Graph management
-(void) startGraph{
    if (!graphStarted && synthGraph) {
		Check(AUGraphStart (synthGraph));
		graphStarted = YES;
    }
}

-(void) stopGraph{
    if(graphStarted && synthGraph) {
		Check(AUGraphStop(synthGraph));
		graphStarted = NO;
    }
}

-(void) setAudioSessionActive {
    AVAudioSession *session = [AVAudioSession sharedInstance];
    NSCheck([session setPreferredSampleRate: [[AVAudioSession sharedInstance] sampleRate] error: &err]);
    NSCheck([session setCategory: AVAudioSessionCategoryPlayback withOptions: AVAudioSessionCategoryOptionMixWithOthers error:  &err]);
    NSCheck([session setActive: YES error:  &err]);
}

-(void) setAudioSessionInActive {
    AVAudioSession *session = [AVAudioSession sharedInstance];
    NSCheck([session setActive: NO error:  &err]);
}

- (BOOL) isGraphStarted {
    if (synthGraph) {
        Check(AUGraphIsRunning (synthGraph, &graphStarted));
        return graphStarted;
    } else
        graphStarted = NO;
    
    return graphStarted;
}

-(void) checkStartStopGraph {
    if (self.connected || inForeground ) {
        [self setAudioSessionActive];
        //Initialize the graph if it hasn't been already
        if (synthGraph) {
            Boolean initialized = YES;
            Check(AUGraphIsInitialized(synthGraph, &initialized));
            if (!initialized)
                Check (AUGraphInitialize (synthGraph));
        }
        [self startGraph];
    } else if(!inForeground){
        [self stopGraph];
        [self setAudioSessionInActive];
    }
}

-(AUGraph) createAUGraphWithSampler:(CFURLRef) bankURl patchNumber:(int)inPatchNumber synthUnit:(AudioUnit *)pOutSynthUnit outUnit:(AudioUnit *)pOutOutputUnit{
	AUGraph 	graph = 0;
	AudioUnit 	synth;
	OSStatus 	result = noErr;
	
	//create the nodes of the graph
	AUNode synthNode, outNode;
	
	AudioComponentDescription cd;
	cd.componentManufacturer = kAudioUnitManufacturer_Apple;
	cd.componentFlags = 0;
	cd.componentFlagsMask = 0;
	
	Check(result = NewAUGraph (&graph));
	
	cd.componentType = kAudioUnitType_MusicDevice;
	cd.componentSubType = kAudioUnitSubType_Sampler;
	
	Check(result = AUGraphAddNode (graph, &cd, &synthNode));
	
	cd.componentType = kAudioUnitType_Output;
	cd.componentSubType = kAudioUnitSubType_RemoteIO;
    
	Check(result = AUGraphAddNode (graph, &cd, &outNode));
	
	Check(AUGraphOpen (graph));
	
	Check(AUGraphConnectNodeInput (graph, synthNode, 0, outNode, 0));
	
	// ok we're good to go - get the Synth Unit...
	Check(AUGraphNodeInfo(graph, synthNode, 0, &synth));
	
	Check(AUGraphNodeInfo(graph, outNode, 0, pOutOutputUnit));
	
    UInt32 maxFrames = 4096;
    AudioUnitSetProperty(*pOutOutputUnit, kAudioUnitProperty_MaximumFramesPerSlice, kAudioUnitScope_Global, 0, &maxFrames, sizeof(maxFrames));
    
	// if the user supplies a sound bank, we'll set that before we initialize and start playing
	if (bankURL)
	{
        AUSamplerInstrumentData bpdata;
        bpdata.fileURL = (CFURLRef)bankURL;
        bpdata.instrumentType = kInstrumentType_AUPreset;
        bpdata.bankMSB = 0x79;
        bpdata.bankLSB = 0;
        bpdata.presetID = (UInt8)patchNumber;
		Check(AudioUnitSetProperty (synth,
                                    kAUSamplerProperty_LoadInstrument,
                                    kAudioUnitScope_Global,
                                    0, &bpdata, sizeof(bpdata)));
	}
	
	*pOutSynthUnit = synth;
	return graph;
}

#pragma mark Application State Handling methods
-(void) appHasGoneInBackground {
    inForeground = NO;
    [self checkStartStopGraph];
}

-(void) appHasGoneForeground {
    inForeground = YES;
    [self isHostConnected];
    [self checkStartStopGraph];
    [self updateStatefromTransportCallBack];
}

-(void) updateStatefromTransportCallBack{
    if ([self isHostConnected] && inForeground) {
        if (!callBackInfo)
            [self getHostCallBackInfo];
        if (callBackInfo) {
            Boolean isPlaying  = self.playing;
            Boolean isRecording = self.recording;
            Float64 outCurrentSampleInTimeLine = 0;
            void * hostUserData = callBackInfo->hostUserData;
            OSStatus result =  callBackInfo->transportStateProc2( hostUserData,
																  &isPlaying,
																  &isRecording, NULL,
																  &outCurrentSampleInTimeLine,
																  NULL, NULL, NULL);
            if (result == noErr) {
                self.playing = isPlaying;
                self.recording = isRecording;
                self.playTime = outCurrentSampleInTimeLine;
            } else 
                NSLog(@"Error occured fetching callBackInfo->transportStateProc2 : %d", (int)result);
        }
    }
}

@end

#pragma mark Private methods
@implementation Sampler(Private)
-(void) audioUnitPropertyChangedListener:(void *) inObject unit:(AudioUnit )inUnit propID:(AudioUnitPropertyID) inID scope:( AudioUnitScope )inScope  element:(AudioUnitElement )inElement {
    if (inID == kAudioUnitProperty_IsInterAppConnected) {
        [self isHostConnected];
        [self postUpdateStateNotification];
    } else if (inID == kAudioOutputUnitProperty_HostTransportState) {
        [self updateStatefromTransportCallBack];
        [self postUpdateStateNotification];
    }
}

-(void) postUpdateStateNotification {
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:kTransportStateChangedNotificiation object:self];
    });
}

-(OSStatus) sendMusicDeviceMIDIEvent:(UInt32)inStatus data1:(UInt32)inData1 data2:(UInt32)inData2 offsetSampleFrame:(UInt32)inOffsetSampleFrame {
	return MusicDeviceMIDIEvent(synthUnit, inStatus, inData1, inData2, inOffsetSampleFrame);
}

@end

#pragma mark Utility functions
NSString *formattedTimeStringForFrameCount(UInt64 inFrameCount, Float64 inSampleRate, BOOL inShowMilliseconds) {
	UInt32 hours		= 0;
	UInt32 minutes		= 0;
	UInt32 seconds		= 0;
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
	
	NSString *hoursString	= nil;
	NSString *minutesString	= nil;
	NSString *secondsString	= nil;
	
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
