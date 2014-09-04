/*
    File: MixerHostViewController.m
Abstract: View controller: Sets up the user interface and conveys UI actions 
to the MixerHostAudio object. Also responds to state-change notifications from
the MixerHostAudio object.
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

Copyright (C) 2010 Apple Inc. All Rights Reserved.

*/


#import "MixerHostViewController.h"
#import "MixerHostAudio.h"

NSString *MixerHostAudioObjectPlaybackStateDidChangeNotification = @"MixerHostAudioObjectPlaybackStateDidChangeNotification";


@implementation MixerHostViewController

// To learn about properties, see "Declared Properties" in the "Cocoa Objects" chapter
//    in Cocoa Fundamentals Guide
@synthesize playButton;
@synthesize mixerBus0Switch;
@synthesize mixerBus0LevelFader;
@synthesize mixerBus1Switch;
@synthesize mixerBus1LevelFader;
@synthesize mixerOutputLevelFader;

@synthesize audioObject;


# pragma mark -
# pragma mark User interface methods
// Set the initial multichannel mixer unit parameter values according to the UI state
- (void) initializeMixerSettingsToUI {

    // Initialize mixer settings to UI
    [audioObject enableMixerInput: 0 isOn: mixerBus0Switch.isOn];
    [audioObject enableMixerInput: 1 isOn: mixerBus1Switch.isOn];
        
    [audioObject setMixerOutputGain: mixerOutputLevelFader.value];
    
    [audioObject setMixerInput: 0 gain: mixerBus0LevelFader.value];
    [audioObject setMixerInput: 1 gain: mixerBus1LevelFader.value];
}

// Handle a change in the mixer output gain slider.
- (IBAction) mixerOutputGainChanged: (UISlider *) sender {

    [audioObject setMixerOutputGain: (AudioUnitParameterValue) sender.value];
}

// Handle a change in a mixer input gain slider. The "tag" value of the slider lets this 
//    method distinguish between the two channels.
- (IBAction) mixerInputGainChanged: (UISlider *) sender {

    UInt32 inputBus = sender.tag;
    [audioObject setMixerInput: (UInt32) inputBus gain: (AudioUnitParameterValue) sender.value];
}


#pragma mark -
#pragma mark Audio processing graph control

// Handle a play/stop button tap
- (IBAction) playOrStop: (id) sender {

    if (audioObject.isPlaying) {
    
        [audioObject stopAUGraph];
        self.playButton.title = @"Play";
        
    } else {
    
        [audioObject startAUGraph];
        self.playButton.title = @"Stop";
    } 
}

// Handle a change in playback state that resulted from an audio session interruption or end of interruption
- (void) handlePlaybackStateChanged: (id) notification {

    [self playOrStop: nil];
}


#pragma mark -
#pragma mark Mixer unit control

// Handle a Mixer unit input on/off switch action. The "tag" value of the switch lets this
//    method distinguish between the two channels.
- (IBAction) enableMixerInput: (UISwitch *) sender {

    UInt32 inputBus = sender.tag;
    AudioUnitParameterValue isOn = (AudioUnitParameterValue) sender.isOn;
    
    [audioObject enableMixerInput: inputBus isOn: isOn];

}


#pragma mark -
#pragma mark Remote-control event handling
// Respond to remote control events
- (void) remoteControlReceivedWithEvent: (UIEvent *) receivedEvent {

    if (receivedEvent.type == UIEventTypeRemoteControl) {
    
        switch (receivedEvent.subtype) {
        
            case UIEventSubtypeRemoteControlTogglePlayPause:
                [self playOrStop: nil];
                break;
            
            default:
                break;
        }
    }
}


#pragma mark -
#pragma mark Notification registration
// If this app's audio session is interrupted when playing audio, it needs to update its user interface 
//    to reflect the fact that audio has stopped. The MixerHostAudio object conveys its change in state to
//    this object by way of a notification. To learn about notifications, see Notification Programming Topics.
- (void) registerForAudioObjectNotifications {

    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    
    [notificationCenter addObserver: self
                           selector: @selector (handlePlaybackStateChanged:)
                               name: MixerHostAudioObjectPlaybackStateDidChangeNotification
                             object: audioObject];
}


#pragma mark -
#pragma mark Application state management

- (void) viewDidLoad {

    [super viewDidLoad];

    MixerHostAudio *newAudioObject = [[MixerHostAudio alloc] init];
    self.audioObject = newAudioObject;
    [newAudioObject release];
    
    [self registerForAudioObjectNotifications];
    [self initializeMixerSettingsToUI];
}


// If using a nonmixable audio session category, as this app does, you must activate reception of 
//    remote-control events to allow reactivation of the audio session when running in the background.
//    Also, to receive remote-control events, the app must be eligible to become the first responder.
- (void) viewDidAppear: (BOOL) animated {

    [super viewDidAppear: animated];
    [[UIApplication sharedApplication] beginReceivingRemoteControlEvents];
    [self becomeFirstResponder];
}

- (BOOL) canBecomeFirstResponder {

    return YES;
}


- (void) didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}


- (void) viewWillDisppear: (BOOL) animated {

    [[UIApplication sharedApplication] endReceivingRemoteControlEvents];
    [self resignFirstResponder];
    
    [super viewWillDisappear: animated];
}


- (void) viewDidUnload {

    self.playButton             = nil;
    self.mixerBus0Switch        = nil;
    self.mixerBus1Switch        = nil;
    self.mixerBus0LevelFader    = nil;
    self.mixerBus1LevelFader    = nil;
    self.mixerOutputLevelFader  = nil;

    [[NSNotificationCenter defaultCenter] removeObserver: self
                                                    name: MixerHostAudioObjectPlaybackStateDidChangeNotification
                                                  object: audioObject];

    self.audioObject            = nil;
    [super viewDidUnload];
}


- (void) dealloc {

    [playButton             release];
    [mixerBus0Switch        release];
    [mixerBus1Switch        release];
    [mixerBus0LevelFader    release];
    [mixerBus1LevelFader    release];
    [mixerOutputLevelFader  release];

    [[NSNotificationCenter defaultCenter] removeObserver: self
                                                    name: MixerHostAudioObjectPlaybackStateDidChangeNotification
                                                  object: audioObject];

    [audioObject            release];
    [[UIApplication sharedApplication] endReceivingRemoteControlEvents];
    [super dealloc];
}

@end
