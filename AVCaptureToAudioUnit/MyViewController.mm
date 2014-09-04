/*
     File: MyViewController.mm
 Abstract: Main view controller for this sample.
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

#import "MyViewController.h"
#import "CaptureSessionController.h"

@interface MyViewController ()
@property (readonly, nonatomic) IBOutlet UIButton *startButton;
@property (readonly, nonatomic) IBOutlet UILabel *playbackText;
@property (nonatomic, strong) IBOutlet CaptureSessionController *captureSessionController;

- (IBAction)buttonAction:(id)sender;
@end

@implementation MyViewController

- (void)viewDidLoad
{
	[super viewDidLoad];
    
    // set up the start button
    // we've also set up different button titles in IB depending on state etc.
    UIImage *greenImage = [[UIImage imageNamed:@"green_button.png"] stretchableImageWithLeftCapWidth:12.0 topCapHeight:0.0];
	UIImage *redImage = [[UIImage imageNamed:@"red_button.png"] stretchableImageWithLeftCapWidth:12.0 topCapHeight:0.0];
	
	[self.startButton setBackgroundImage:greenImage forState:UIControlStateNormal];
	[self.startButton setBackgroundImage:redImage forState:UIControlStateSelected];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
    return (toInterfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}

- (void)viewWillAppear:(BOOL)animated
{
    [self registerForNotifications];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [self unregisterForNotifications];
}

#pragma mark ======== Capture Session =========

- (void)initCaptureSession
{
    if ([self.captureSessionController setupCaptureSession]) {
        [self updateUISelected:NO enabled:YES];
    }
    else NSLog(@"Initializing CaptureSessionController failed just BAIL!");
}

// button starts and stops recording to the file
// capture session is running before button is enabled
- (IBAction)buttonAction:(id)sender
{
    if (self.captureSessionController.isRecording) {
        [self.captureSessionController stopRecording];
        [self updateUISelected:NO enabled:NO];
        [self playRecordedAudio];
    } else {
        [self.captureSessionController startRecording];
        [self updateUISelected:YES enabled:YES];
    }
}

- (void)updateUISelected:(BOOL)selected enabled:(BOOL)enabled
{
    self.startButton.selected = selected;
    self.startButton.enabled = enabled;
}

#pragma mark ======== AVAudioPlayer =========

// when interrupted, just toss the player and we're done
- (void)audioPlayerBeginInterruption:(AVAudioPlayer *)player
{
    NSLog(@"AVAudioPlayer audioPlayerBeginInterruption");
    
    [player setDelegate:nil];
    [player release];
    
    self.playbackText.hidden = YES;
}

// when finished, toss the player and restart the capture session
- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag
{
	(flag == NO) ? NSLog(@"AVAudioPlayer unsuccessfull!") :
                   NSLog(@"AVAudioPlayer finished playing");

	[player setDelegate:nil];
    [player release];
    
    self.playbackText.hidden = YES;
    
    // start the capture session
    [self.captureSessionController startCaptureSession];
}

// basic AVAudioPlayer implementation to play back recorded file
- (void)playRecordedAudio
{
    NSError *error = nil;
    
    // stop the capture session
    [self.captureSessionController stopCaptureSession];
    
    NSLog(@"Playing Recorded Audio");
    
    // play the result
    AVAudioPlayer *player = [[AVAudioPlayer alloc] initWithContentsOfURL:(NSURL *)self.captureSessionController.outputFile error:nil];
    if (nil == player) {
        NSLog(@"AVAudioPlayer alloc failed! %@", [error localizedDescription]);
        [self.startButton setTitle:@"FAIL!" forState:UIControlStateDisabled];
        return;
    } 

    self.playbackText.hidden = NO;
    
    [player setDelegate:self];
    [player play];
}

#pragma mark ======== Notifications =========

// notification handling to do the right thing when the app comes and goes
- (void)registerForNotifications
{    
	[[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(willResignActive)
                                                 name:UIApplicationWillResignActiveNotification
                                               object:nil];
    
	[[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(enableButton)
                                                 name:@"CaptureSessionRunningNotification"
                                               object:nil];
}

- (void)unregisterForNotifications
{
	[[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIApplicationWillResignActiveNotification
                                               object:nil];
    
	[[NSNotificationCenter defaultCenter] removeObserver:self
                                                 name:@"CaptureSessionRunningNotification"
                                               object:nil];
}

- (void)willResignActive
{
    NSLog(@"MyViewController willResignActive");
    
    [self updateUISelected:NO enabled:NO];
}

- (void)enableButton
{
    NSLog(@"MyViewController enableButton");
    
    [self updateUISelected:NO enabled:YES];
}

@end
