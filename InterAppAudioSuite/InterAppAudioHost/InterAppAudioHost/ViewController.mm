/*
     File: ViewController.mm
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

#import "ViewController.h"

#import "KeyBoardViewController.h"
#import "AppDelegate.h"
#import "PublishedEffectsViewController.h"

@implementation ViewController
{
	IBOutlet UIRemoteAudioUnitButton *instrumentButton;
	IBOutlet UIRemoteAudioUnitButton *effectButton;

	IBOutlet UIButton				 *instrumentCloseButton;
	IBOutlet UIButton				 *effectCloseButton;

	IBOutlet CAUITransportView		 *transportView;

	IBOutlet UIButton				 *showKeyboard;

	IBOutlet UILabel				 *currentTime;
    IBOutlet UILabel				 *duration;
    IBOutlet CAUITransportSlider	 *slider;

	NSMutableArray *_audioUnits;
    NSTimer		   *_pollPlayerTimer;

	BOOL			sliderDragging;
	BOOL			engineWasPlaying;
}

#pragma mark - Initialization / deallocation
- (void) viewDidLoad {
    [super viewDidLoad];

	_audioUnits = [[NSMutableArray alloc] init];
    _pollPlayerTimer = NULL;
    sliderDragging = NO;
	
	slider.primaryColor = [UIColor colorWithRed:.984f green:.251f blue:.173f alpha:1.0];
	slider.secondaryColor = [UIColor darkGrayColor];
    instrumentButton.type = remoteInstrumentButtonType;
    effectButton.type = remoteEffectButtonType;

	effectCloseButton.hidden = YES;
	effectCloseButton.userInteractionEnabled = NO;
	
    // Wire view upto the audio engine
    [AUDIO_ENGINE addEngineObserver: ^{
        [duration setText:[AUDIO_ENGINE getDurationString]];
        [currentTime setText:[AUDIO_ENGINE getPlayTimeString]];
        [slider setCurrentPosition:[AUDIO_ENGINE getPlayProgress]];

        // get the slot zero au
        if (![AUDIO_ENGINE isRemoteInstrumentConnected])
            instrumentButton.remoteAU = NULL;
	
        if ([AUDIO_ENGINE getNumberOfConnectedNodes] == 0)
            effectButton.remoteAU = NULL;
	
        // get the slot zero au
        if ([AUDIO_ENGINE isRemoteInstrumentConnected]) {
            instrumentButton.remoteAU = [AUDIO_ENGINE getNodeAt: 0];
            instrumentCloseButton.hidden = NO;
            instrumentCloseButton.enabled = YES;
            instrumentCloseButton.userInteractionEnabled = YES;
        }
        
        if ([AUDIO_ENGINE getNumberOfConnectedNodes] > 1) {
            effectButton.remoteAU = [AUDIO_ENGINE getNodeAt: 1];
            effectCloseButton.hidden = NO;
            effectCloseButton.enabled = YES;
            effectCloseButton.userInteractionEnabled = YES;
        }
        [self togglePolling];
    } key: [NSString stringWithFormat:@"%@,%@", NSStringFromClass([self class]),  @"ViewController"]];
	
	[self updateControls: NO];

	[transportView updateTransportControls];

    [slider addTarget: self action: @selector(dragEnded:) forControlEvents: UIControlEventTouchUpInside];
    [slider addTarget: self action: @selector(dragBegin:) forControlEvents: UIControlEventTouchDown];
    [slider addTarget: self action: @selector(touchUpOutside:) forControlEvents: UIControlEventTouchUpOutside];
    
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(appHasGoneInBackground)
                                                 name: UIApplicationDidEnterBackgroundNotification
                                               object: nil];
	
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(appHasGoneForeground)
                                                 name: UIApplicationWillEnterForegroundNotification
                                               object: nil];
}

- (void) dealloc {
    [slider release];
    [super dealloc];
}

#pragma mark - ReturnToParentViewControllerDelegate method
- (void) closeView {
    [self dismissViewControllerAnimated:YES completion:nil];
 	
	// get the slot zero au
	if ([AUDIO_ENGINE isRemoteInstrumentConnected]) {
		instrumentButton.remoteAU = [AUDIO_ENGINE getNodeAt: 0];
		[self updateControls: YES];
	}
	
	if ([AUDIO_ENGINE getNumberOfConnectedNodes] > 1) {
		effectButton.remoteAU = [AUDIO_ENGINE getNodeAt: 1];
		effectCloseButton.hidden = NO;
		effectCloseButton.enabled = YES;
		effectCloseButton.userInteractionEnabled = YES;
	}
	
	[transportView performSelectorOnMainThread:@selector(updateTransportControls) withObject:nil waitUntilDone: NO];
}

#pragma mark - IBAction methods
- (IBAction) sliderMoved:(id) sender {
    [AUDIO_ENGINE seekPlayheadTo:slider.currentPosition];
}

- (IBAction) closeRemoteInstrument:(id) sender {
	[self closeRemoteEffect: self];
	[self updateControls: NO];
	[transportView performSelectorOnMainThread:@selector(updateTransportControls) withObject:nil waitUntilDone: NO];
}

- (IBAction) closeRemoteEffect:(id) sender {
	effectCloseButton.hidden = YES;
	effectCloseButton.enabled = NO;
	effectCloseButton.userInteractionEnabled = NO;
	instrumentCloseButton.hidden = YES;
	instrumentCloseButton.enabled = NO;
	instrumentCloseButton.userInteractionEnabled = NO;
	[AUDIO_ENGINE disconnectInstrument];
}

#pragma mark - UI updating methods
- (void) togglePolling {
	BOOL isPlayingOrPaused = [AUDIO_ENGINE isPlaying] || [AUDIO_ENGINE isPaused];
	
	slider.enabled = isPlayingOrPaused;
	duration.enabled = isPlayingOrPaused;
	currentTime.enabled = isPlayingOrPaused;
	
	if (isPlayingOrPaused)
		[self startPollingPlayer];
	else
		[self stopPollingPlayer];
}

- (void) startPollingPlayer {
    if (!_pollPlayerTimer) {
        if ([AUDIO_ENGINE isPlaying] || [AUDIO_ENGINE isPaused]) {
            [duration setText:[AUDIO_ENGINE getDurationString]];
            _pollPlayerTimer =  [NSTimer scheduledTimerWithTimeInterval: 0.05
                                                                 target: self
                                                               selector: @selector(pollPlayer)
                                                               userInfo: nil
                                                                repeats: YES];
        }
    }
}

- (void) pollPlayer {
    //While the slider is updating the playhead don't poll the Audio Engine
    if (!sliderDragging) {
        [currentTime setText:[AUDIO_ENGINE getPlayTimeString]];
        [slider setCurrentPosition:[AUDIO_ENGINE getPlayProgress]];
    }
}

- (void) stopPollingPlayer {
    if (_pollPlayerTimer) {
        [_pollPlayerTimer invalidate];
        _pollPlayerTimer = NULL;
    }
}

- (void) updateControls:(BOOL) active {
	instrumentCloseButton.hidden = !active;
	instrumentCloseButton.enabled = active;
	instrumentCloseButton.userInteractionEnabled = active;
	
	showKeyboard.enabled = active;
	showKeyboard.userInteractionEnabled = active;
	showKeyboard.alpha = active ? 1 : .1;
	
	BOOL canPlay = [AUDIO_ENGINE canPlay];
	currentTime.enabled = canPlay;
	duration.enabled = canPlay;
	slider.enabled = canPlay;
}

#pragma mark - Activation / deactivation handling
- (void) appHasGoneInBackground {
    [self stopPollingPlayer];
}

- (void) appHasGoneForeground {
    [self togglePolling];
}

#pragma mark - Seque methods
- (void) prepareForSegue:(UIStoryboardSegue *) segue sender:(id) sender {
    if ([segue.identifier isEqualToString:@"keyBoardSegue"]) {
        KeyBoardViewController *keyboardViewController = (KeyBoardViewController *)segue.destinationViewController;
        keyboardViewController.delegate = self;
    }
    else if ([segue.identifier isEqualToString:@"InstrumentSegue"]) {
        UINavigationController *navigationController = ((UINavigationController *)segue.destinationViewController);
        PublishInstrumentsViewController *publishedInstrumentsViewController = (PublishInstrumentsViewController *)navigationController.topViewController;
        publishedInstrumentsViewController.delegate = self;
    } else if ([segue.identifier isEqualToString:@"EffectsSegue"]) {
        UINavigationController *navigationController = ((UINavigationController *)segue.destinationViewController);
        PublishedEffectsViewController *publishedEffectsViewController = (PublishedEffectsViewController *)navigationController.topViewController;
        publishedEffectsViewController.delegate = self;
    }
}

- (BOOL) shouldPerformSegueWithIdentifier:(NSString *) identifier sender:(id) sender {
    if ([identifier isEqualToString:@"EffectsSegue"]) {
        if (![AUDIO_ENGINE isRemoteInstrumentConnected]) {
            displayAlertDialog(@"Effect error!", @"Please select an instrument before selecting an effect");
            return NO;
        } else if ([AUDIO_ENGINE isRemoteEffectConnected]){
            [AUDIO_ENGINE gotoRemoteEffect];
            return NO;
        }
    }
    else if ([identifier isEqualToString:@"InstrumentSegue"]){
        if ([AUDIO_ENGINE isRemoteInstrumentConnected]) {
            [AUDIO_ENGINE gotoRemoteInstrument];
            return NO;
        }
    }
    return YES;
}

#pragma mark - Event handling
- (void) dragBegin:(NSNotification *) notification {
    sliderDragging = YES;
	engineWasPlaying = [AUDIO_ENGINE isPlaying];
    [AUDIO_ENGINE stopPlaying];
}

- (void) dragEnded:(NSNotification *) notification {
    sliderDragging = NO;
	if (engineWasPlaying)
		[AUDIO_ENGINE startPlaying];
}

- (void) touchUpOutside:(NSNotification *) notification {
    [self dragEnded:notification];
}

@end
