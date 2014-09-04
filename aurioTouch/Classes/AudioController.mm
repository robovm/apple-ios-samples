/*
 
     File: AudioController.mm
 Abstract: n/a
  Version: 2.0
 
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

#import "AudioController.h"

// Framework includes
#import <AVFoundation/AVAudioSession.h>

// Utility file includes
#import "CAXException.h"
#import "CAStreamBasicDescription.h"

typedef enum aurioTouchDisplayMode {
	aurioTouchDisplayModeOscilloscopeWaveform,
	aurioTouchDisplayModeOscilloscopeFFT,
	aurioTouchDisplayModeSpectrum
} aurioTouchDisplayMode;


struct CallbackData {
    AudioUnit               rioUnit;
    BufferManager*          bufferManager;
    DCRejectionFilter*      dcRejectionFilter;
    BOOL*                   muteAudio;
    BOOL*                   audioChainIsBeingReconstructed;
    
    CallbackData(): rioUnit(NULL), bufferManager(NULL), muteAudio(NULL), audioChainIsBeingReconstructed(NULL) {}
} cd;

// Render callback function
static OSStatus	performRender (void                         *inRefCon,
                               AudioUnitRenderActionFlags 	*ioActionFlags,
                               const AudioTimeStamp 		*inTimeStamp,
                               UInt32 						inBusNumber,
                               UInt32 						inNumberFrames,
                               AudioBufferList              *ioData)
{
    OSStatus err = noErr;
    if (*cd.audioChainIsBeingReconstructed == NO)
    {
        // we are calling AudioUnitRender on the input bus of AURemoteIO
        // this will store the audio data captured by the microphone in ioData
        err = AudioUnitRender(cd.rioUnit, ioActionFlags, inTimeStamp, 1, inNumberFrames, ioData);
        
        // filter out the DC component of the signal
        cd.dcRejectionFilter->ProcessInplace((Float32*) ioData->mBuffers[0].mData, inNumberFrames);
        
        // based on the current display mode, copy the required data to the buffer manager
        if (cd.bufferManager->GetDisplayMode() == aurioTouchDisplayModeOscilloscopeWaveform)
        {
            cd.bufferManager->CopyAudioDataToDrawBuffer((Float32*)ioData->mBuffers[0].mData, inNumberFrames);
        }
        
        else if ((cd.bufferManager->GetDisplayMode() == aurioTouchDisplayModeSpectrum) || (cd.bufferManager->GetDisplayMode() == aurioTouchDisplayModeOscilloscopeFFT))
        {
            if (cd.bufferManager->NeedsNewFFTData())
                cd.bufferManager->CopyAudioDataToFFTInputBuffer((Float32*)ioData->mBuffers[0].mData, inNumberFrames);
        }
        
        // mute audio if needed
        if (*cd.muteAudio)
        {
            for (UInt32 i=0; i<ioData->mNumberBuffers; ++i)
                memset(ioData->mBuffers[i].mData, 0, ioData->mBuffers[i].mDataByteSize);
        }
    }
    
    return err;
}


@interface AudioController()

- (void)setupAudioSession;
- (void)setupIOUnit;
- (void)createButtonPressedSound;
- (void)setupAudioChain;

@end

@implementation AudioController

@synthesize muteAudio = _muteAudio;

- (id)init
{
    if (self = [super init]) {
        _bufferManager = NULL;
        _dcRejectionFilter = NULL;
        _muteAudio = YES;
        [self setupAudioChain];
    }
    return self;
}


- (void)handleInterruption:(NSNotification *)notification
{
    try {
        UInt8 theInterruptionType = [[notification.userInfo valueForKey:AVAudioSessionInterruptionTypeKey] intValue];
        NSLog(@"Session interrupted > --- %s ---\n", theInterruptionType == AVAudioSessionInterruptionTypeBegan ? "Begin Interruption" : "End Interruption");
        
        if (theInterruptionType == AVAudioSessionInterruptionTypeBegan) {
            [self stopIOUnit];
        }
        
        if (theInterruptionType == AVAudioSessionInterruptionTypeEnded) {
            // make sure to activate the session
            NSError *error = nil;
            [[AVAudioSession sharedInstance] setActive:YES error:&error];
            if (nil != error) NSLog(@"AVAudioSession set active failed with error: %@", error);
            
            [self startIOUnit];
        }
    } catch (CAXException e) {
        char buf[256];
        fprintf(stderr, "Error: %s (%s)\n", e.mOperation, e.FormatError(buf));
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

- (void)handleMediaServerReset:(NSNotification *)notification
{
    NSLog(@"Media server has reset");
    _audioChainIsBeingReconstructed = YES;
    
    usleep(25000); //wait here for some time to ensure that we don't delete these objects while they are being accessed elsewhere
    
    // rebuild the audio chain
    delete _bufferManager;      _bufferManager = NULL;
    delete _dcRejectionFilter;  _dcRejectionFilter = NULL;
    [_audioPlayer release]; _audioPlayer = nil;
    
    [self setupAudioChain];
    [self startIOUnit];
    
    _audioChainIsBeingReconstructed = NO;
}

- (void)setupAudioSession
{
    try {
        // Configure the audio session
        AVAudioSession *sessionInstance = [AVAudioSession sharedInstance];
        
        // we are going to play and record so we pick that category
        NSError *error = nil;
        [sessionInstance setCategory:AVAudioSessionCategoryPlayAndRecord error:&error];
        XThrowIfError((OSStatus)error.code, "couldn't set session's audio category");
        
        // set the buffer duration to 5 ms
        NSTimeInterval bufferDuration = .005;
        [sessionInstance setPreferredIOBufferDuration:bufferDuration error:&error];
        XThrowIfError((OSStatus)error.code, "couldn't set session's I/O buffer duration");
        
        // set the session's sample rate
        [sessionInstance setPreferredSampleRate:44100 error:&error];
        XThrowIfError((OSStatus)error.code, "couldn't set session's preferred sample rate");
        
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
        
        // if media services are reset, we need to rebuild our audio chain
        [[NSNotificationCenter defaultCenter]	addObserver:	self
                                                 selector:	@selector(handleMediaServerReset:)
                                                     name:	AVAudioSessionMediaServicesWereResetNotification
                                                   object:	sessionInstance];
        
        // activate the audio session
        [[AVAudioSession sharedInstance] setActive:YES error:&error];
        XThrowIfError((OSStatus)error.code, "couldn't set session active");
    }
    
    catch (CAXException &e) {
        NSLog(@"Error returned from setupAudioSession: %d: %s", (int)e.mError, e.mOperation);
    }
    catch (...) {
        NSLog(@"Unknown error returned from setupAudioSession");
    }
    
    return;
}


- (void)setupIOUnit
{
    try {
        // Create a new instance of AURemoteIO
        
        AudioComponentDescription desc;
        desc.componentType = kAudioUnitType_Output;
        desc.componentSubType = kAudioUnitSubType_RemoteIO;
        desc.componentManufacturer = kAudioUnitManufacturer_Apple;
        desc.componentFlags = 0;
        desc.componentFlagsMask = 0;
        
        AudioComponent comp = AudioComponentFindNext(NULL, &desc);
        XThrowIfError(AudioComponentInstanceNew(comp, &_rioUnit), "couldn't create a new instance of AURemoteIO");
        
        //  Enable input and output on AURemoteIO
        //  Input is enabled on the input scope of the input element
        //  Output is enabled on the output scope of the output element
        
        UInt32 one = 1;
        XThrowIfError(AudioUnitSetProperty(_rioUnit, kAudioOutputUnitProperty_EnableIO, kAudioUnitScope_Input, 1, &one, sizeof(one)), "could not enable input on AURemoteIO");
        XThrowIfError(AudioUnitSetProperty(_rioUnit, kAudioOutputUnitProperty_EnableIO, kAudioUnitScope_Output, 0, &one, sizeof(one)), "could not enable output on AURemoteIO");
        
        // Explicitly set the input and output client formats
        // sample rate = 44100, num channels = 1, format = 32 bit floating point
        
        CAStreamBasicDescription ioFormat = CAStreamBasicDescription(44100, 1, CAStreamBasicDescription::kPCMFormatFloat32, false);
        XThrowIfError(AudioUnitSetProperty(_rioUnit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Output, 1, &ioFormat, sizeof(ioFormat)), "couldn't set the input client format on AURemoteIO");
        XThrowIfError(AudioUnitSetProperty(_rioUnit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Input, 0, &ioFormat, sizeof(ioFormat)), "couldn't set the output client format on AURemoteIO");
        
        // Set the MaximumFramesPerSlice property. This property is used to describe to an audio unit the maximum number
        // of samples it will be asked to produce on any single given call to AudioUnitRender
        UInt32 maxFramesPerSlice = 4096;
        XThrowIfError(AudioUnitSetProperty(_rioUnit, kAudioUnitProperty_MaximumFramesPerSlice, kAudioUnitScope_Global, 0, &maxFramesPerSlice, sizeof(UInt32)), "couldn't set max frames per slice on AURemoteIO");
        
        // Get the property value back from AURemoteIO. We are going to use this value to allocate buffers accordingly
        UInt32 propSize = sizeof(UInt32);
        XThrowIfError(AudioUnitGetProperty(_rioUnit, kAudioUnitProperty_MaximumFramesPerSlice, kAudioUnitScope_Global, 0, &maxFramesPerSlice, &propSize), "couldn't get max frames per slice on AURemoteIO");
        
        _bufferManager = new BufferManager(maxFramesPerSlice);
        _dcRejectionFilter = new DCRejectionFilter;
        
        // We need references to certain data in the render callback
        // This simple struct is used to hold that information
        
        cd.rioUnit = _rioUnit;
        cd.bufferManager = _bufferManager;
        cd.dcRejectionFilter = _dcRejectionFilter;
        cd.muteAudio = &_muteAudio;
        cd.audioChainIsBeingReconstructed = &_audioChainIsBeingReconstructed;
        
        // Set the render callback on AURemoteIO
        AURenderCallbackStruct renderCallback;
        renderCallback.inputProc = performRender;
        renderCallback.inputProcRefCon = NULL;
        XThrowIfError(AudioUnitSetProperty(_rioUnit, kAudioUnitProperty_SetRenderCallback, kAudioUnitScope_Input, 0, &renderCallback, sizeof(renderCallback)), "couldn't set render callback on AURemoteIO");
        
        // Initialize the AURemoteIO instance
        XThrowIfError(AudioUnitInitialize(_rioUnit), "couldn't initialize AURemoteIO instance");
    }
    
    catch (CAXException &e) {
        NSLog(@"Error returned from setupIOUnit: %d: %s", (int)e.mError, e.mOperation);
    }
    catch (...) {
        NSLog(@"Unknown error returned from setupIOUnit");
    }
    
    return;
}

- (void)createButtonPressedSound
{
    NSError *error;
    
    CFURLRef url = CFURLCreateWithFileSystemPath(kCFAllocatorDefault, CFStringRef([[NSBundle mainBundle] pathForResource:@"button_press" ofType:@"caf"]), kCFURLPOSIXPathStyle, false);
    _audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:(NSURL*)url error:&error];
    
    XThrowIfError((OSStatus)error.code, "couldn't create AVAudioPlayer");
    
    CFRelease(url);
}

- (void)playButtonPressedSound
{
    [_audioPlayer play];
}

- (void)setupAudioChain
{
    [self setupAudioSession];
    [self setupIOUnit];
    [self createButtonPressedSound];
}

- (OSStatus)startIOUnit
{
    OSStatus err = AudioOutputUnitStart(_rioUnit);
    if (err) NSLog(@"couldn't start AURemoteIO: %d", (int)err);
    return err;
}

- (OSStatus)stopIOUnit
{
    OSStatus err = AudioOutputUnitStop(_rioUnit);
    if (err) NSLog(@"couldn't stop AURemoteIO: %d", (int)err);
    return err;
}

- (double)sessionSampleRate
{
    return [[AVAudioSession sharedInstance] sampleRate];
}

- (BufferManager*)getBufferManagerInstance
{
    return _bufferManager;
}

- (BOOL)audioChainIsBeingReconstructed
{
    return _audioChainIsBeingReconstructed;
}

- (void)dealloc
{
    delete _bufferManager;      _bufferManager = NULL;
    delete _dcRejectionFilter;  _dcRejectionFilter = NULL;
    [_audioPlayer release];     _audioPlayer = nil;
    
    [super dealloc];
}

@end
