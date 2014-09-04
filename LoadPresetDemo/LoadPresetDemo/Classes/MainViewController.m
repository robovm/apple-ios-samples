/*
     File: MainViewController.m
 Abstract: The view controller for this app. Includes all the audio code.
  Version: 1.1
 
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
 
 Copyright (C) 2011 Apple Inc. All Rights Reserved.
 
 */


#import "MainViewController.h"
#import <AssertMacros.h>

// some MIDI constants:
enum {
	kMIDIMessage_NoteOn    = 0x9,
	kMIDIMessage_NoteOff   = 0x8,
};

#define kLowNote  48
#define kHighNote 72
#define kMidNote  60

// private class extension
@interface MainViewController ()
@property (readwrite) Float64   graphSampleRate;
@property (readwrite) AUGraph   processingGraph;
@property (readwrite) AudioUnit samplerUnit;
@property (readwrite) AudioUnit ioUnit;

- (OSStatus)    loadSynthFromPresetURL:(NSURL *) presetURL;
- (void)        registerForUIApplicationNotifications;
- (BOOL)        createAUGraph;
- (void)        configureAndStartAudioProcessingGraph: (AUGraph) graph;
- (void)        stopAudioProcessingGraph;
- (void)        restartAudioProcessingGraph;
@end

@implementation MainViewController

@synthesize graphSampleRate     = _graphSampleRate;
@synthesize currentPresetLabel  = _currentPresetLabel;
@synthesize presetOneButton     = _presetOneButton;
@synthesize presetTwoButton     = _presetTwoButton;
@synthesize lowNoteButton       = _lowNoteButton;
@synthesize midNoteButton       = _midNoteButton;
@synthesize highNoteButton      = _highNoteButton;
@synthesize samplerUnit         = _samplerUnit;
@synthesize ioUnit              = _ioUnit;
@synthesize processingGraph     = _processingGraph;

#pragma mark -
#pragma mark Audio setup


// Create an audio processing graph.
- (BOOL) createAUGraph {
    
	OSStatus result = noErr;
	AUNode samplerNode, ioNode;

    // Specify the common portion of an audio unit's identify, used for both audio units
    // in the graph.
	AudioComponentDescription cd = {};
	cd.componentManufacturer     = kAudioUnitManufacturer_Apple;
	cd.componentFlags            = 0;
	cd.componentFlagsMask        = 0;

    // Instantiate an audio processing graph
	result = NewAUGraph (&_processingGraph);
    NSCAssert (result == noErr, @"Unable to create an AUGraph object. Error code: %d '%.4s'", (int) result, (const char *)&result);
		
	//Specify the Sampler unit, to be used as the first node of the graph
	cd.componentType = kAudioUnitType_MusicDevice;
	cd.componentSubType = kAudioUnitSubType_Sampler;
	
    // Add the Sampler unit node to the graph
	result = AUGraphAddNode (self.processingGraph, &cd, &samplerNode);
    NSCAssert (result == noErr, @"Unable to add the Sampler unit to the audio processing graph. Error code: %d '%.4s'", (int) result, (const char *)&result);

	// Specify the Output unit, to be used as the second and final node of the graph	
	cd.componentType = kAudioUnitType_Output;
	cd.componentSubType = kAudioUnitSubType_RemoteIO;  

    // Add the Output unit node to the graph
	result = AUGraphAddNode (self.processingGraph, &cd, &ioNode);
    NSCAssert (result == noErr, @"Unable to add the Output unit to the audio processing graph. Error code: %d '%.4s'", (int) result, (const char *)&result);

    // Open the graph
	result = AUGraphOpen (self.processingGraph);
    NSCAssert (result == noErr, @"Unable to open the audio processing graph. Error code: %d '%.4s'", (int) result, (const char *)&result);

    // Connect the Sampler unit to the output unit
	result = AUGraphConnectNodeInput (self.processingGraph, samplerNode, 0, ioNode, 0);
    NSCAssert (result == noErr, @"Unable to interconnect the nodes in the audio processing graph. Error code: %d '%.4s'", (int) result, (const char *)&result);

	// Obtain a reference to the Sampler unit from its node
	result = AUGraphNodeInfo (self.processingGraph, samplerNode, 0, &_samplerUnit);
    NSCAssert (result == noErr, @"Unable to obtain a reference to the Sampler unit. Error code: %d '%.4s'", (int) result, (const char *)&result);

	// Obtain a reference to the I/O unit from its node
	result = AUGraphNodeInfo (self.processingGraph, ioNode, 0, &_ioUnit);
    NSCAssert (result == noErr, @"Unable to obtain a reference to the I/O unit. Error code: %d '%.4s'", (int) result, (const char *)&result);
    
    return YES;
}


// Starting with instantiated audio processing graph, configure its 
// audio units, initialize it, and start it.
- (void) configureAndStartAudioProcessingGraph: (AUGraph) graph {

    OSStatus result = noErr;
    UInt32 framesPerSlice = 0;
    UInt32 framesPerSlicePropertySize = sizeof (framesPerSlice);
    UInt32 sampleRatePropertySize = sizeof (self.graphSampleRate);
    
    result = AudioUnitInitialize (self.ioUnit);
    NSCAssert (result == noErr, @"Unable to initialize the I/O unit. Error code: %d '%.4s'", (int) result, (const char *)&result);

    // Set the I/O unit's output sample rate.
    result =    AudioUnitSetProperty (
                  self.ioUnit,
                  kAudioUnitProperty_SampleRate,
                  kAudioUnitScope_Output,
                  0,
                  &_graphSampleRate,
                  sampleRatePropertySize
                );
    
    NSAssert (result == noErr, @"AudioUnitSetProperty (set Sampler unit output stream sample rate). Error code: %d '%.4s'", (int) result, (const char *)&result);

    // Obtain the value of the maximum-frames-per-slice from the I/O unit.
    result =    AudioUnitGetProperty (
                    self.ioUnit,
                    kAudioUnitProperty_MaximumFramesPerSlice,
                    kAudioUnitScope_Global,
                    0,
                    &framesPerSlice,
                    &framesPerSlicePropertySize
                );

    NSCAssert (result == noErr, @"Unable to retrieve the maximum frames per slice property from the I/O unit. Error code: %d '%.4s'", (int) result, (const char *)&result);

    // Set the Sampler unit's output sample rate.
    result =    AudioUnitSetProperty (
                  self.samplerUnit,
                  kAudioUnitProperty_SampleRate,
                  kAudioUnitScope_Output,
                  0,
                  &_graphSampleRate,
                  sampleRatePropertySize
                );
    
    NSAssert (result == noErr, @"AudioUnitSetProperty (set Sampler unit output stream sample rate). Error code: %d '%.4s'", (int) result, (const char *)&result);

    // Set the Sampler unit's maximum frames-per-slice.
    result =    AudioUnitSetProperty (
                    self.samplerUnit,
                    kAudioUnitProperty_MaximumFramesPerSlice,
                    kAudioUnitScope_Global,
                    0,
                    &framesPerSlice,
                    framesPerSlicePropertySize
                );
    
    NSAssert( result == noErr, @"AudioUnitSetProperty (set Sampler unit maximum frames per slice). Error code: %d '%.4s'", (int) result, (const char *)&result);
    
    
    if (graph) {
        
        // Initialize the audio processing graph.
        result = AUGraphInitialize (graph);
        NSAssert (result == noErr, @"Unable to initialze AUGraph object. Error code: %d '%.4s'", (int) result, (const char *)&result);
        
        // Start the graph
        result = AUGraphStart (graph);
        NSAssert (result == noErr, @"Unable to start audio processing graph. Error code: %d '%.4s'", (int) result, (const char *)&result);
        
        // Print out the graph to the console
        CAShow (graph); 
    }
}


// Load the Trombone preset
- (IBAction)loadPresetOne:(id)sender {

	NSURL *presetURL = [[NSURL alloc] initFileURLWithPath:[[NSBundle mainBundle] pathForResource:@"Trombone" ofType:@"aupreset"]];
	if (presetURL) {
		NSLog(@"Attempting to load preset '%@'\n", [presetURL description]);
        self.currentPresetLabel.text = @"Trombone";
	}
	else {
		NSLog(@"COULD NOT GET PRESET PATH!");
	}

	[self loadSynthFromPresetURL: presetURL];
}

// Load the Vibraphone preset
- (IBAction)loadPresetTwo:(id)sender {
    
	NSURL *presetURL = [[NSURL alloc] initFileURLWithPath:[[NSBundle mainBundle] pathForResource:@"Vibraphone" ofType:@"aupreset"]];
	if (presetURL) {
		NSLog(@"Attempting to load preset '%@'\n", [presetURL description]);
        self.currentPresetLabel.text = @"Vibraphone";	}
	else {
		NSLog(@"COULD NOT GET PRESET PATH!");
	}

	[self loadSynthFromPresetURL: presetURL];
}

// Load a synthesizer preset file and apply it to the Sampler unit
- (OSStatus) loadSynthFromPresetURL: (NSURL *) presetURL {
    
	CFDataRef propertyResourceData = 0;
	Boolean status;
	SInt32 errorCode = 0;
	OSStatus result = noErr;
	
	// Read from the URL and convert into a CFData chunk
	status = CFURLCreateDataAndPropertiesFromResource (
                kCFAllocatorDefault,
                (__bridge CFURLRef) presetURL,
                &propertyResourceData,
                NULL,
                NULL,
                &errorCode
             );

    NSAssert (status == YES && propertyResourceData != 0, @"Unable to create data and properties from a preset. Error code: %d '%.4s'", (int) errorCode, (const char *)&errorCode);
   	
	// Convert the data object into a property list
	CFPropertyListRef presetPropertyList = 0;
	CFPropertyListFormat dataFormat = 0;
	CFErrorRef errorRef = 0;
	presetPropertyList = CFPropertyListCreateWithData (
                            kCFAllocatorDefault,
                            propertyResourceData,
                            kCFPropertyListImmutable,
                            &dataFormat,
                            &errorRef
                        );

    // Set the class info property for the Sampler unit using the property list as the value.
	if (presetPropertyList != 0) {
		
		result = AudioUnitSetProperty(
                    self.samplerUnit,
                    kAudioUnitProperty_ClassInfo,
                    kAudioUnitScope_Global,
                    0,
                    &presetPropertyList,
                    sizeof(CFPropertyListRef)
                );

		CFRelease(presetPropertyList);
	}

    if (errorRef) CFRelease(errorRef);
	CFRelease (propertyResourceData);

	return result;
}


// Set up the audio session for this app.
- (BOOL) setupAudioSession {
    
    AVAudioSession *mySession = [AVAudioSession sharedInstance];
    
    // Specify that this object is the delegate of the audio session, so that
    //    this object's endInterruption method will be invoked when needed.
    [mySession setDelegate: self];
    
    // Assign the Playback category to the audio session. This category supports
    //    audio output with the Ring/Silent switch in the Silent position.
    NSError *audioSessionError = nil;
    [mySession setCategory: AVAudioSessionCategoryPlayback error: &audioSessionError];
    if (audioSessionError != nil) {NSLog (@"Error setting audio session category."); return NO;}    

    // Request a desired hardware sample rate.
    self.graphSampleRate = 44100.0;    // Hertz
    
    [mySession setPreferredHardwareSampleRate: self.graphSampleRate error: &audioSessionError];
    if (audioSessionError != nil) {NSLog (@"Error setting preferred hardware sample rate."); return NO;}
        
    // Activate the audio session
    [mySession setActive: YES error: &audioSessionError];
    if (audioSessionError != nil) {NSLog (@"Error activating the audio session."); return NO;}
    
    // Obtain the actual hardware sample rate and store it for later use in the audio processing graph.
    self.graphSampleRate = [mySession currentHardwareSampleRate];

    return YES;
}


#pragma mark -
#pragma mark Audio control
// Play the low note
- (IBAction) startPlayLowNote:(id)sender {

	UInt32 noteNum = kLowNote;
	UInt32 onVelocity = 127;
	UInt32 noteCommand = 	kMIDIMessage_NoteOn << 4 | 0;
    
    OSStatus result = noErr;
	require_noerr (result = MusicDeviceMIDIEvent (self.samplerUnit, noteCommand, noteNum, onVelocity, 0), logTheError);

logTheError:
    if (result != noErr) NSLog (@"Unable to start playing the low note. Error code: %d '%.4s'\n", (int) result, (const char *)&result);
}

// Stop the low note
- (IBAction) stopPlayLowNote:(id)sender {

	UInt32 noteNum = kLowNote;
	UInt32 noteCommand = 	kMIDIMessage_NoteOff << 4 | 0;
	
    OSStatus result = noErr;
	require_noerr (result = MusicDeviceMIDIEvent (self.samplerUnit, noteCommand, noteNum, 0, 0), logTheError);

logTheError:
    if (result != noErr) NSLog (@"Unable to stop playing the low note. Error code: %d '%.4s'\n", (int) result, (const char *)&result);
}

// Play the mid note
- (IBAction) startPlayMidNote:(id)sender {

	UInt32 noteNum = kMidNote;
	UInt32 onVelocity = 127;
	UInt32 noteCommand = 	kMIDIMessage_NoteOn << 4 | 0;
	
    OSStatus result = noErr;
	require_noerr (result = MusicDeviceMIDIEvent(self.samplerUnit, noteCommand, noteNum, onVelocity, 0), logTheError);
    
logTheError:
    if (result != noErr) NSLog (@"Unable to start playing the mid note. Error code: %d '%.4s'\n", (int) result, (const char *)&result);
}

// Stop the mid note
- (IBAction) stopPlayMidNote:(id)sender {

	UInt32 noteNum = kMidNote;
	UInt32 noteCommand = 	kMIDIMessage_NoteOff << 4 | 0;
	
    OSStatus result = noErr;
	require_noerr (result = MusicDeviceMIDIEvent(self.samplerUnit, noteCommand, noteNum, 0, 0), logTheError);
    
logTheError:
    if (result != noErr) NSLog (@"Unable to stop playing the mid note. Error code: %d '%.4s'\n", (int) result, (const char *)&result);
}

// Play the high note
- (IBAction) startPlayHighNote:(id)sender {

	UInt32 noteNum = kHighNote;
	UInt32 onVelocity = 127;
	UInt32 noteCommand = 	kMIDIMessage_NoteOn << 4 | 0;
	
    OSStatus result = noErr;
	require_noerr (result = MusicDeviceMIDIEvent(self.samplerUnit, noteCommand, noteNum, onVelocity, 0), logTheError);
    
logTheError:
    if (result != noErr) NSLog (@"Unable to start playing the high note. Error code: %d '%.4s'\n", (int) result, (const char *)&result);
}

// Stop the high note
- (IBAction)stopPlayHighNote:(id)sender {

	UInt32 noteNum = kHighNote;
	UInt32 noteCommand = 	kMIDIMessage_NoteOff << 4 | 0;
	
    OSStatus result = noErr;
	require_noerr (result = MusicDeviceMIDIEvent(self.samplerUnit, noteCommand, noteNum, 0, 0), logTheError);
    
logTheError:
    if (result != noErr) NSLog (@"Unable to stop playing the high note. Error code: %d '%.4s'", (int) result, (const char *)&result);
}

// Stop the audio processing graph
- (void) stopAudioProcessingGraph {

    OSStatus result = noErr;
	if (self.processingGraph) result = AUGraphStop(self.processingGraph);
    NSAssert (result == noErr, @"Unable to stop the audio processing graph. Error code: %d '%.4s'", (int) result, (const char *)&result);
}

// Restart the audio processing graph
- (void) restartAudioProcessingGraph {

    OSStatus result = noErr;
	if (self.processingGraph) result = AUGraphStart (self.processingGraph);
    NSAssert (result == noErr, @"Unable to restart the audio processing graph. Error code: %d '%.4s'", (int) result, (const char *)&result);
}


#pragma mark -
#pragma mark Audio session delegate methods

// Respond to an audio interruption, such as a phone call or a Clock alarm.
- (void) beginInterruption {
    
    // Stop any notes that are currently playing.
    [self stopPlayLowNote: self];
    [self stopPlayMidNote: self];
    [self stopPlayHighNote: self];

    // Interruptions do not put an AUGraph object into a "stopped" state, so
    //    do that here.
    [self stopAudioProcessingGraph];
}


// Respond to the ending of an audio interruption.
- (void) endInterruptionWithFlags: (NSUInteger) flags {
    
    NSError *endInterruptionError = nil;
    [[AVAudioSession sharedInstance] setActive: YES
                                         error: &endInterruptionError];
    if (endInterruptionError != nil) {
        
        NSLog (@"Unable to reactivate the audio session.");
        return;
    }
    
    if (flags & AVAudioSessionInterruptionFlags_ShouldResume) {
        
        /*
         In a shipping application, check here to see if the hardware sample rate changed from 
         its previous value by comparing it to graphSampleRate. If it did change, reconfigure 
         the ioInputStreamFormat struct to use the new sample rate, and set the new stream 
         format on the two audio units. (On the mixer, you just need to change the sample rate).
         
         Then call AUGraphUpdate on the graph before starting it.
         */
        
        [self restartAudioProcessingGraph];
    }
}


#pragma mark - Application state management

// The audio processing graph should not run when the screen is locked or when the app has 
//  transitioned to the background, because there can be no user interaction in those states.
//  (Leaving the graph running with the screen locked wastes a significant amount of energy.)
//
// Responding to these UIApplication notifications allows this class to stop and restart the 
//    graph as appropriate.
- (void) registerForUIApplicationNotifications {
    
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    
    [notificationCenter addObserver: self
                           selector: @selector (handleResigningActive:)
                               name: UIApplicationWillResignActiveNotification
                             object: [UIApplication sharedApplication]];
    
    [notificationCenter addObserver: self
                           selector: @selector (handleBecomingActive:)
                               name: UIApplicationDidBecomeActiveNotification
                             object: [UIApplication sharedApplication]];
}


- (void) handleResigningActive: (id) notification {
    
    [self stopPlayLowNote: self];
    [self stopPlayMidNote: self];
    [self stopPlayHighNote: self];
    [self stopAudioProcessingGraph];
}


- (void) handleBecomingActive: (id) notification {
    
    [self restartAudioProcessingGraph];
}

- (id) initWithNibName: (NSString *) nibNameOrNil bundle: (NSBundle *) nibBundleOrNil {
        
    self = [super initWithNibName: nibNameOrNil bundle: nibBundleOrNil];
        
    // If object initialization fails, return immediately.
    if (!self) {
        return nil;
    }

    // Set up the audio session for this app, in the process obtaining the 
    // hardware sample rate for use in the audio processing graph.
    BOOL audioSessionActivated = [self setupAudioSession];
    NSAssert (audioSessionActivated == YES, @"Unable to set up audio session.");
    
    // Create the audio processing graph; place references to the graph and to the Sampler unit
    // into the processingGraph and samplerUnit instance variables.
    [self createAUGraph];
    [self configureAndStartAudioProcessingGraph: self.processingGraph];
    
    return self;
}


- (void) viewDidLoad {

    [super viewDidLoad];
    
    // Load the Trombone preset so the app is ready to play upon launch.
    [self loadPresetOne: self];
    [self registerForUIApplicationNotifications];
}

- (void) viewDidUnload {

    self.currentPresetLabel = nil;
    self.presetOneButton    = nil;
	self.presetTwoButton    = nil;
	self.lowNoteButton      = nil;
	self.midNoteButton      = nil;
	self.highNoteButton     = nil;

    [super viewDidUnload];
}

- (BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {

    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void) didReceiveMemoryWarning {

    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}


@end
