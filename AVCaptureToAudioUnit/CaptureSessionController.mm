/*

    File: CaptureSessionController.mm
Abstract: Class that sets up a AVCaptureSession that outputs to a
 AVCaptureAudioDataOutput. The output audio samples are passed through
 an effect audio unit and are then written to a file.
 Version: 1.0

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

Copyright (C) 2012 Apple Inc. All Rights Reserved.


*/

#import "CaptureSessionController.h"

static OSStatus PushCurrentInputBufferIntoAudioUnit(void                       *inRefCon,
													AudioUnitRenderActionFlags *ioActionFlags,
													const AudioTimeStamp       *inTimeStamp,
													UInt32						inBusNumber,
													UInt32						inNumberFrames,
													AudioBufferList            *ioData);

@implementation CaptureSessionController

#pragma mark ======== Setup and teardown methods =========

- (id)init
{
	self = [super init];
	
	if (self) {
        NSArray  *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *documentsDirectory = [paths objectAtIndex:0];
        NSString *destinationFilePath = [NSString stringWithFormat: @"%@/AudioRecording.aif", documentsDirectory];
        _outputFile = CFURLCreateWithFileSystemPath(kCFAllocatorDefault, (CFStringRef)destinationFilePath, kCFURLPOSIXPathStyle, false);
    
        [self registerForNotifications];
	}
	
	return self;
}

- (BOOL)setupCaptureSession
{    
	// Find the current default audio input device
    AVCaptureDevice *audioDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeAudio];
    
    if (audioDevice && audioDevice.connected) {
        // Get the device name
        NSLog(@"Audio Device Name: %@", audioDevice.localizedName);
    } else {
        NSLog(@"AVCaptureDevice defaultDeviceWithMediaType failed or device not connected!");
        return NO;
    }
	
	// Create the capture session
	captureSession = [[AVCaptureSession alloc] init];
    if (!captureSession) {
        NSLog(@"AVCaptureSession allocation failed!");;
        return NO;
    }
	
	// Create and add a device input for the audio device to the session
    NSError *error = nil;
	captureAudioDeviceInput = [AVCaptureDeviceInput deviceInputWithDevice:audioDevice error:&error];
    if (!captureAudioDeviceInput) {
        NSLog(@"AVCaptureDeviceInput allocation failed! %@", [error localizedDescription]);
		return NO;
	}
    
    if ([captureSession canAddInput: captureAudioDeviceInput]) {
        [captureSession addInput:captureAudioDeviceInput];
    } else {
        NSLog(@"Could not addInput to Capture Session!");
        return NO;
    }
    
    // Create and add a AVCaptureAudioDataOutput object to the session
    captureAudioDataOutput = [AVCaptureAudioDataOutput new];
    
    if (!captureAudioDataOutput) {
        NSLog(@"Could not create AVCaptureAudioDataOutput!");
        return NO;
    }
    
    if ([captureSession canAddOutput:captureAudioDataOutput]) {
        [captureSession addOutput:captureAudioDataOutput];
    } else {
        NSLog(@"Could not addOutput to Capture Session!");
		return NO;
    }
    
    // Create a serial dispatch queue and set it on the AVCaptureAudioDataOutput object
    dispatch_queue_t audioDataOutputQueue = dispatch_queue_create("AudioDataOutputQueue", DISPATCH_QUEUE_SERIAL);
    if (!audioDataOutputQueue){
        NSLog(@"dispatch_queue_create Failed!");
		return NO;
    }
    
    [captureAudioDataOutput setSampleBufferDelegate:self queue:audioDataOutputQueue];
    dispatch_release(audioDataOutputQueue);
	
    // AVFoundation does not currently provide a way to set the output format of the AVCaptureAudioDataOutput object,
    // therefore unlike OS X where you could simply use the delay AU and have AVCaptureAudioDataOutput return samples
    // in a format that the delay AU can ingest by using the audioSettings method, for iOS you need to use the Converter AU
    // along with the delay AU in a Graph. Note that we don't start or stop the graph and we don't use an output unit
    // all we are doing is chaining two AUs together then pulling on the delay when we call render, this delivers data in
    // the current AVCaptureAudioDataOutput format to the converter which then converts the format for the delay which
    // performs the processing we want delivering the data into our output buffer list for recording if we choose
    
	// Create an AUGraph of the converter audio unit and the delay effect audio unit, the resulting effect is added to the audio when it is written to the file

    AUNode delayNode;
    AUNode converterNode;
    
    // create a new AUGraph
	OSStatus err = NewAUGraph(&auGraph);
    if (err) { printf("NewAUGraph Failed! %ld %08X %4.4s\n", (long)err, (unsigned int)err, (char*)&err); return NO; }
    
    // delay effect
    CAComponentDescription delay_EffectAudioUnitDescription(kAudioUnitType_Effect, kAudioUnitSubType_Delay, kAudioUnitManufacturer_Apple);
    
    // converter
    CAComponentDescription converter_desc(kAudioUnitType_FormatConverter, kAudioUnitSubType_AUConverter, kAudioUnitManufacturer_Apple);
    
    // add nodes to graph
    err = AUGraphAddNode(auGraph, &delay_EffectAudioUnitDescription, &delayNode);
    if (err) { printf("AUGraphNewNode 2 result %lu %4.4s\n", (unsigned long)err, (char*)&err); return NO; }
    
    err = AUGraphAddNode(auGraph, &converter_desc, &converterNode);
	if (err) { printf("AUGraphNewNode 3 result %lu %4.4s\n", (unsigned long)err, (char*)&err); return NO; }
    
    // connect a node's output to a node's input
    // au converter -> delay
    
    err = AUGraphConnectNodeInput(auGraph, converterNode, 0, delayNode, 0);
	if (err) { printf("AUGraphConnectNodeInput result %lu %4.4s\n", (unsigned long)err, (char*)&err); return NO; }
	
    // open the graph -- AudioUnits are open but not initialized (no resource allocation occurs here)
	err = AUGraphOpen(auGraph);
	if (err) { printf("AUGraphOpen result %ld %08X %4.4s\n", (long)err, (unsigned int)err, (char*)&err); return NO; }
	
    // grab audio unit instances from the nodes
    err = AUGraphNodeInfo(auGraph, converterNode, NULL, &converterAudioUnit);
    if (err) { printf("AUGraphNodeInfo result %ld %08X %4.4s\n", (long)err, (unsigned int)err, (char*)&err); return NO; }

	err = AUGraphNodeInfo(auGraph, delayNode, NULL, &delayAudioUnit);
    if (err) { printf("AUGraphNodeInfo result %ld %08X %4.4s\n", (long)err, (unsigned int)err, (char*)&err); return NO; }

    // Set a callback on the converter audio unit that will supply the audio buffers received from the capture audio data output
    AURenderCallbackStruct renderCallbackStruct;
    renderCallbackStruct.inputProc = PushCurrentInputBufferIntoAudioUnit;
    renderCallbackStruct.inputProcRefCon = self;
    
    err = AUGraphSetNodeInputCallback(auGraph, converterNode, 0, &renderCallbackStruct);
    if (err) { printf("AUGraphSetNodeInputCallback result %ld %08X %4.4s\n", (long)err, (unsigned int)err, (char*)&err); return NO; }
	
    // add an observer for the interupted property, we simply log the result
    [captureSession addObserver:self forKeyPath:@"interrupted" options:NSKeyValueObservingOptionNew context:nil];
    [captureSession addObserver:self forKeyPath:@"running" options:NSKeyValueObservingOptionNew context:nil];
    
	// Start the capture session - This will cause the audio data output delegate method didOutputSampleBuffer
    // to be called for each new audio buffer recieved from the input device
	[self startCaptureSession];
    
    return YES;
}

// if we need to we call this to dispose of the previous capture session
// and create a new one, add our input and output and go
- (BOOL)resetCaptureSession
{
    if (captureSession) {
        [captureSession removeObserver:self forKeyPath:@"interrupted" context:nil];
        [captureSession removeObserver:self forKeyPath:@"running" context:nil];
    
        [captureSession release]; captureSession = nil;
    }
    
    // Create the capture session
	captureSession = [[AVCaptureSession alloc] init];
    if (!captureSession) {
        NSLog(@"AVCaptureSession allocation failed!");
        return NO;
    }
    
    if ([captureSession canAddInput: captureAudioDeviceInput]) {
        [captureSession addInput:captureAudioDeviceInput];
    } else {
        NSLog(@"Could not addInput to Capture Session!");
        return NO;
    }
    
    if ([captureSession canAddOutput:captureAudioDataOutput]) {
        [captureSession addOutput:captureAudioDataOutput];
    } else {
        NSLog(@"Could not addOutput to Capture Session!");
		return NO;
    }
    
    // add an observer for the interupted property, we simply log the result
    [captureSession addObserver:self forKeyPath:@"interrupted" options:NSKeyValueObservingOptionNew context:nil];
    [captureSession addObserver:self forKeyPath:@"running" options:NSKeyValueObservingOptionNew context:nil];
    
    return YES;
}

// teardown
- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIApplicationWillResignActiveNotification
                                                  object:nil];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIApplicationDidBecomeActiveNotification
                                                  object:nil];
    
	[[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:AVAudioSessionRouteChangeNotification
                                               object:[AVAudioSession sharedInstance]];

    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:AVCaptureSessionRuntimeErrorNotification
                                               object:nil];
    
    [captureSession removeObserver:self forKeyPath:@"interrupted" context:nil];
	[captureSession removeObserver:self forKeyPath:@"running" context:nil];
    
    [captureSession release];
	[captureAudioDeviceInput release];
    [captureAudioDataOutput setSampleBufferDelegate:nil queue:NULL];
	[captureAudioDataOutput release];
	
	if (_outputFile) { CFRelease(_outputFile); _outputFile = NULL; }
	
	if (extAudioFile)
        ExtAudioFileDispose(extAudioFile);
    
	if (auGraph) {
		if (didSetUpAudioUnits)
			AUGraphUninitialize(auGraph);
		DisposeAUGraph(auGraph);
	}
    
    if (currentInputAudioBufferList) free(currentInputAudioBufferList);
    if (outputBufferList) delete outputBufferList;
	
	[super dealloc];
}

#pragma mark ======== Audio capture methods =========

/*
 Called by AVCaptureAudioDataOutput as it receives CMSampleBufferRef objects containing audio frames captured by the AVCaptureSession.
 Each CMSampleBufferRef will contain multiple frames of audio encoded in the default AVCapture audio format. This is where all the work is done,
 the first time through setting up and initializing the graph and format settings then continually rendering the provided audio though the
 audio unit graph manually and if we're recording, writing the processed audio out to the file.
*/
- (void)captureOutput:(AVCaptureOutput *)captureOutput
        didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer
        fromConnection:(AVCaptureConnection *)connection
{
	OSStatus err = noErr;
	
    // Get the sample buffer's AudioStreamBasicDescription which will be used to set the input format of the audio unit and ExtAudioFile
    CMFormatDescriptionRef formatDescription = CMSampleBufferGetFormatDescription(sampleBuffer);
    CAStreamBasicDescription sampleBufferASBD(*CMAudioFormatDescriptionGetStreamBasicDescription(formatDescription));
    if (kAudioFormatLinearPCM != sampleBufferASBD.mFormatID) { NSLog(@"Bad format or bogus ASBD!"); return; }
    
    if ((sampleBufferASBD.mChannelsPerFrame != currentInputASBD.mChannelsPerFrame) || (sampleBufferASBD.mSampleRate != currentInputASBD.mSampleRate)) {
        NSLog(@"AVCaptureAudioDataOutput Audio Format:");
        sampleBufferASBD.Print();
        /* 
         Although in iOS AVCaptureAudioDataOutput as of iOS 6 will output 16-bit PCM only by default, the sample rate will depend on the hardware and the
         current route and whether you've got any 30-pin audio microphones plugged in and so on. By default, you'll get mono and AVFoundation will request 44.1 kHz,
         but if the audio route demands a lower sample rate, AVFoundation will deliver that instead. Some 30-pin devices present a stereo stream,
         in which case AVFoundation will deliver stereo. If there is a change for input format after initial setup, the audio units receiving the buffers needs
         to be reconfigured with the new format. This also must be done when a buffer is received for the first time.
        */
        currentInputASBD = sampleBufferASBD;
        currentRecordingChannelLayout = (AudioChannelLayout *)CMAudioFormatDescriptionGetChannelLayout(formatDescription, NULL);
        
        if (didSetUpAudioUnits) {
            // The audio units were previously set up, so they must be uninitialized now
            err = AUGraphUninitialize(auGraph);
            NSLog(@"AUGraphUninitialize failed (%ld)", (long)err);
			
        if (outputBufferList) delete outputBufferList;
            outputBufferList = NULL;
        } else {
            didSetUpAudioUnits = YES;
        }
        
        // set the input stream format, this is the format of the audio for the converter input bus
        err = AudioUnitSetProperty(converterAudioUnit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Input, 0, &currentInputASBD, sizeof(currentInputASBD));
		
		if (noErr == err) {
            CAStreamBasicDescription outputFormat(currentInputASBD.mSampleRate, currentInputASBD.mChannelsPerFrame, CAStreamBasicDescription::kPCMFormatFloat32, false);
            NSLog(@"AUGraph Output Audio Format:");
            outputFormat.Print();
            
            graphOutputASBD = outputFormat;
            
            // in an au graph, each nodes output stream format (including sample rate) needs to be set explicitly
            // this stream format is propagated to its destination's input stream format
    
            // set the output stream format of the converter
            err = AudioUnitSetProperty(converterAudioUnit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Output, 0, &graphOutputASBD, sizeof(graphOutputASBD));
            if (noErr == err)
                // set the output stream format of the delay
                err = AudioUnitSetProperty(delayAudioUnit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Output, 0, &graphOutputASBD, sizeof(graphOutputASBD));
        }
		
        // Initialize the graph
		if (noErr == err)
			err = AUGraphInitialize(auGraph);
		
		if (noErr != err) {
			NSLog(@"Failed to set up audio units (%ld)", (long)err);
			
			didSetUpAudioUnits = NO;
			bzero(&currentInputASBD, sizeof(currentInputASBD));
		}
        
        CAShow(auGraph);
    }

    CMItemCount numberOfFrames = CMSampleBufferGetNumSamples(sampleBuffer); // corresponds to the number of CoreAudio audio frames
		
    // In order to render continuously, the effect audio unit needs a new time stamp for each buffer
    // Use the number of frames for each unit of time continuously incrementing
    currentSampleTime += (double)numberOfFrames;
    
    AudioTimeStamp timeStamp;
    memset(&timeStamp, 0, sizeof(AudioTimeStamp));
    timeStamp.mSampleTime = currentSampleTime;
    timeStamp.mFlags |= kAudioTimeStampSampleTimeValid;		
    
    AudioUnitRenderActionFlags flags = 0;
    
    // Create an output AudioBufferList as the destination for the AU rendered audio
    if (NULL == outputBufferList) {
        outputBufferList = new AUOutputBL(graphOutputASBD, numberOfFrames);
    }
    outputBufferList->Prepare(numberOfFrames);
    
    /*
     Get an audio buffer list from the sample buffer and assign it to the currentInputAudioBufferList instance variable.
     The the audio unit render callback called PushCurrentInputBufferIntoAudioUnit can access this value by calling the
     currentInputAudioBufferList method.
    */
    
    // CMSampleBufferGetAudioBufferListWithRetainedBlockBuffer requires a properly allocated AudioBufferList struct
    currentInputAudioBufferList = CAAudioBufferList::Create(currentInputASBD.mChannelsPerFrame);
    
    size_t bufferListSizeNeededOut;
    CMBlockBufferRef blockBufferOut = nil;
    
    err = CMSampleBufferGetAudioBufferListWithRetainedBlockBuffer(sampleBuffer,
                                                                  &bufferListSizeNeededOut,
                                                                  currentInputAudioBufferList,
                                                                  CAAudioBufferList::CalculateByteSize(currentInputASBD.mChannelsPerFrame),
                                                                  kCFAllocatorSystemDefault,
                                                                  kCFAllocatorSystemDefault,
                                                                  kCMSampleBufferFlag_AudioBufferList_Assure16ByteAlignment,
                                                                  &blockBufferOut);
    
    if (noErr == err) {
        // Tell the effect audio unit to render -- This will synchronously call PushCurrentInputBufferIntoAudioUnit, which will
        // feed currentInputAudioBufferList into the effect audio unit
        err = AudioUnitRender(delayAudioUnit, &flags, &timeStamp, 0, numberOfFrames, outputBufferList->ABL());
        if (err) {
            // kAudioUnitErr_TooManyFramesToProcess may happen on a route change if CMSampleBufferGetNumSamples
            // returns more than 1024 (the default) number of samples. This is ok and on the next cycle this error should not repeat
            NSLog(@"AudioUnitRender failed! (%ld)", err);
        }
        
        CFRelease(blockBufferOut);
        CAAudioBufferList::Destroy(currentInputAudioBufferList);
        currentInputAudioBufferList = NULL;
    } else {
        NSLog(@"CMSampleBufferGetAudioBufferListWithRetainedBlockBuffer failed! (%ld)", (long)err);
    }

    if (noErr == err) {
        @synchronized(self) {
            if (extAudioFile) {
                err = ExtAudioFileWriteAsync(extAudioFile, numberOfFrames, outputBufferList->ABL());
            }
        }// @synchronized
        if (err) {
            NSLog(@"ExtAudioFileWriteAsync failed! (%ld)", (long)err);
        }
    }
}

/*
 Used by PushCurrentInputBufferIntoAudioUnit() to access the current audio buffer list
 that has been output by the AVCaptureAudioDataOutput.
*/
- (AudioBufferList *)currentInputAudioBufferList
{
	return currentInputAudioBufferList;
}

#pragma mark ======== AVCapture Session & Recording =========

- (void)startCaptureSession
{
    static UInt8 retry = 0;
    
    // this sample always attempts to keep the capture session running without tearing it all down,
    // which means we may be trying to start the capture session while it's still
    // in some interim interrupted state (after a phone call for example) which will usually
    // get cleared up after a very short delay handle by a simple retry mechanism
    // if we still can't start, then resort to releasing the previous capture session and creating a new one
    if (captureSession.isInterrupted) {
        if (retry < 3) {
            retry++;
            NSLog(@"Capture Session interrupted try starting again...");
            [self performSelector:@selector(startCaptureSession) withObject:self afterDelay:2];
            return;
        } else {
            NSLog(@"Resetting Capture Session");
            BOOL result = [self resetCaptureSession];
            if (NO == result) {
                // this is bad, and means we can never start...should never see this
                NSLog(@"FAILED in resetCaptureSession! Cannot restart capture session!");
                return;
            }
        }
    }
    
    if (!captureSession.running) {
        NSLog(@"startCaptureSession");
        
        [captureSession startRunning];
        
        retry = 0;
    }
}

- (void)stopCaptureSession
{
    if (captureSession.running) {
        NSLog(@"stopCaptureSession");
        [captureSession stopRunning];
    }
}

- (void)startRecording
{
    if (!self.isRecording) {
        OSErr err = kAudioFileUnspecifiedError;
        @synchronized(self) {
            if (!extAudioFile) {
                /*
                 Start recording by creating an ExtAudioFile and configuring it with the same sample rate and
                 channel layout as those of the current sample buffer.
                */
                
                // recording format is the format of the audio file itself
                CAStreamBasicDescription recordingFormat(currentInputASBD.mSampleRate, currentInputASBD.mChannelsPerFrame, CAStreamBasicDescription::kPCMFormatInt16, true);
                recordingFormat.mFormatFlags |= kAudioFormatFlagIsBigEndian;
                
                NSLog(@"Recording Audio Format:");
                recordingFormat.Print();
                       
                err = ExtAudioFileCreateWithURL(_outputFile,
                                                kAudioFileAIFFType,
                                                &recordingFormat,
                                                currentRecordingChannelLayout,
                                                kAudioFileFlags_EraseFile,
                                                &extAudioFile);
                if (noErr == err)
                    // client format is the output format from the delay unit
                    err = ExtAudioFileSetProperty(extAudioFile, kExtAudioFileProperty_ClientDataFormat, sizeof(graphOutputASBD), &graphOutputASBD);
                    
                if (noErr != err) {
                    if (extAudioFile) ExtAudioFileDispose(extAudioFile);
                    extAudioFile = NULL;
                }
            }
        } // @synchronized
        
        if (noErr == err) {
            self.recording = YES;
            NSLog(@"Recording Started");
        } else {
            NSLog(@"Failed to setup audio file! (%ld)", (long)err);
        }
    }
}

- (void)stopRecording
{
    if (self.isRecording) {
        OSStatus err = kAudioFileNotOpenError;
        @synchronized(self) {
            if (extAudioFile) {
                // Close the file by disposing the ExtAudioFile
                err = ExtAudioFileDispose(extAudioFile);
                extAudioFile = NULL;
            }
        } // @synchronized

        AudioUnitReset(delayAudioUnit, kAudioUnitScope_Global, 0);
        
        self.recording = NO;
        NSLog(@"Recording Stopped (%ld)", (long)err);
    }
}

#pragma mark ======== Observers =========

// observe state changes from the capture session, we log interruptions but activate the UI via notification when running
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqualToString:@"interrupted"] ) {
        NSLog(@"CaptureSesson is interrupted %@", (captureSession.isInterrupted) ? @"Yes" : @"No");
    }
    
    if ([keyPath isEqualToString:@"running"] ) {
        NSLog(@"CaptureSesson is running %@", (captureSession.isRunning) ? @"Yes" : @"No");
        if (captureSession.isRunning) {
            [[NSNotificationCenter defaultCenter] postNotificationName:@"CaptureSessionRunningNotification" object:nil];
        }
    }
}

#pragma mark ======== Notifications =========

// notifications for standard things we want to know about
- (void)registerForNotifications
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(willResignActive)
                                                 name:UIApplicationWillResignActiveNotification
                                               object:nil];
    
	[[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didBecomeActive)
                                                 name:UIApplicationDidBecomeActiveNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(routeChangeHandler:)
                                                 name:AVAudioSessionRouteChangeNotification 
                                               object:[AVAudioSession sharedInstance]];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(captureSessionRuntimeError:)
                                                 name:AVCaptureSessionRuntimeErrorNotification 
                                               object:nil];
}

// log any runtime erros from the capture session
- (void)captureSessionRuntimeError:(NSNotification *)notification
{
    NSError *error = [notification.userInfo objectForKey: AVCaptureSessionErrorKey];
    
    NSLog(@"AVFoundation error %d", [error code]);
}

// log route changes
- (void)routeChangeHandler:(NSNotification *)notification
{
    UInt8 reasonValue = [[notification.userInfo valueForKey: AVAudioSessionRouteChangeReasonKey] intValue];
    
    if (AVAudioSessionRouteChangeReasonNewDeviceAvailable == reasonValue || AVAudioSessionRouteChangeReasonOldDeviceUnavailable == reasonValue) {
       	NSLog(@"CaptureSessionController routeChangeHandler called:");
        (reasonValue == AVAudioSessionRouteChangeReasonNewDeviceAvailable) ? NSLog(@"     NewDeviceAvailable") :
                                                                             NSLog(@"     OldDeviceUnavailable");
    }
}

// need to stop capture session and close the file if recording on resign
- (void)willResignActive
{
    NSLog(@"CaptureSessionController willResignActive");
    
    [self stopCaptureSession];
    
    if (self.isRecording) {
        [self stopRecording];
    }
}

// we want to start the capture session again automatically on active
- (void)didBecomeActive
{
    NSLog(@"CaptureSessionController didBecomeActive");
    
    [self startCaptureSession];
}

@end

#pragma mark ======== AudioUnit render callback =========

/*
 Synchronously called by the effect audio unit whenever AudioUnitRender() is called.
 Used to feed the audio samples output by the ATCaptureAudioDataOutput to the AudioUnit.
 */
static OSStatus PushCurrentInputBufferIntoAudioUnit(void *							inRefCon,
													AudioUnitRenderActionFlags *	ioActionFlags,
													const AudioTimeStamp *			inTimeStamp,
													UInt32							inBusNumber,
													UInt32							inNumberFrames,
													AudioBufferList *				ioData)
{
	CaptureSessionController *self = (CaptureSessionController *)inRefCon;
	AudioBufferList *currentInputAudioBufferList = [self currentInputAudioBufferList];
	UInt32 bufferIndex, bufferCount = currentInputAudioBufferList->mNumberBuffers;
	
	if (bufferCount != ioData->mNumberBuffers) return kAudioFormatUnknownFormatError;
	
	// Fill the provided AudioBufferList with the data from the AudioBufferList output by the audio data output
	for (bufferIndex = 0; bufferIndex < bufferCount; bufferIndex++) {
		ioData->mBuffers[bufferIndex].mDataByteSize = currentInputAudioBufferList->mBuffers[bufferIndex].mDataByteSize;
		ioData->mBuffers[bufferIndex].mData = currentInputAudioBufferList->mBuffers[bufferIndex].mData;
		ioData->mBuffers[bufferIndex].mNumberChannels = currentInputAudioBufferList->mBuffers[bufferIndex].mNumberChannels;
	}
	
	return noErr;
}