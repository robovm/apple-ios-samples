/*
    Copyright (C) 2015 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    The main view controller of this app
*/

#import "MyViewController.h"

#define kTransitionDuration	0.75

@implementation MyViewController

@synthesize instructionsView, webView, contentView, flipButton, doneButton, startButton, bus0Switch, bus0VolumeSlider, bus1Switch, bus1VolumeSlider, outputVolumeSlider, mixerController;

#pragma mark- UIView

- (void)viewDidLoad
{
    [super viewDidLoad];
    
	// load up the info text
    NSString *infoSouceFile = [[NSBundle mainBundle] pathForResource:@"info" ofType:@"html"];
	NSString *infoText = [NSString stringWithContentsOfFile:infoSouceFile encoding:NSUTF8StringEncoding error:nil];
    [self.webView loadHTMLString:infoText baseURL:nil];
    
    // add the subview
	[self.view addSubview:contentView];
	
	// add our custom flip buttons as the nav bars custom right view
	UIButton* infoButton = [UIButton buttonWithType:UIButtonTypeInfoLight];
	[infoButton addTarget:self action:@selector(flipAction:) forControlEvents:UIControlEventTouchUpInside];
	
    flipButton = [[UIBarButtonItem alloc] initWithCustomView:infoButton];
    self.navigationItem.rightBarButtonItem = flipButton;
	
	// create our done button as the nav bar's custom right view for the flipped view (used later)
	doneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(flipAction:)];
}

- (void)didReceiveMemoryWarning
{
	// invoke super's implementation to do the Right Thing. In practice this is unlikely to be used in this application,
    // and it would be of little benefit, but the principle is the important thing.
    [super didReceiveMemoryWarning];
}

- (void)dealloc
{    
    [instructionsView release];
    [webView release];
    [contentView release];
    
    self.flipButton = nil;
    self.doneButton = nil;

    [startButton release];
    
    [bus0Switch release];
    [bus0VolumeSlider release];
    [bus1Switch release];
    [bus1VolumeSlider release];
    [outputVolumeSlider release];
        
    [mixerController release];
    
	[super dealloc];
}

#pragma mark-

// set the mixers values according to the UI state
- (void)setUIDefaults
{
    [mixerController enableInput:0 isOn:bus0Switch.isOn];
    [mixerController enableInput:1 isOn:bus1Switch.isOn];
    [mixerController setInputVolume:0 value:bus0VolumeSlider.value];
    [mixerController setInputVolume:1 value:bus1VolumeSlider.value];
    [mixerController setOutputVolume:outputVolumeSlider.value];
}

// do the info button flip
- (void)flipAction:(id)sender
{
	[UIView setAnimationDelegate:self];
	[UIView setAnimationDidStopSelector:@selector(animationDidStop:animationIDfinished:finished:context:)];
	[UIView beginAnimations:nil context:nil];
	[UIView setAnimationDuration:kTransitionDuration];
	
	[UIView setAnimationTransition:([self.contentView superview] ? UIViewAnimationTransitionFlipFromLeft : UIViewAnimationTransitionFlipFromRight)
                                    forView:self.view
                                    cache:YES];
                                    
	if ([self.instructionsView superview]) {
		[self.instructionsView removeFromSuperview];
		[self.view addSubview:contentView];
	} else {
		[self.contentView removeFromSuperview];
		[self.view addSubview:instructionsView];
	}
	
	[UIView commitAnimations];
	
	// adjust our done/info buttons accordingly
	if ([instructionsView superview]) {
		self.navigationItem.rightBarButtonItem = doneButton;
	} else {
		self.navigationItem.rightBarButtonItem = flipButton;
    }
}

// called if we've been interrupted and if we're playing, stop
- (void)stopForInterruption
{
    if (mixerController.isPlaying) {
        [mixerController stopAUGraph];
        self.startButton.selected = NO;
    }
}

#pragma mark- Actions

// handle input on/off switch action
- (IBAction)enableInput:(UISwitch *)sender
{
    UInt32 inputNum = (UInt32)[sender tag];
    AudioUnitParameterValue isOn = (AudioUnitParameterValue)sender.isOn;
    
    if (0 == inputNum) self.bus0VolumeSlider.enabled = isOn;
    if (1 == inputNum) self.bus1VolumeSlider.enabled = isOn;
                                    
    [mixerController enableInput:inputNum isOn:isOn];
}

// handle input volume changes
- (IBAction)setInputVolume:(UISlider *)sender
{
	UInt32 inputNum = (UInt32)[sender tag];
    AudioUnitParameterValue value = sender.value;
    
    [mixerController setInputVolume:inputNum value:value];
}

// handle output volume changes
- (IBAction)setOutputVolume:(UISlider *)sender
{
    AudioUnitParameterValue value = sender.value;
    
    [mixerController setOutputVolume:value];
}

// handle the button press
- (IBAction)doSomethingAction:(id)sender
{
    if (mixerController.isPlaying) {
        [mixerController stopAUGraph];
        self.startButton.selected = NO;
    } else {
        [mixerController startAUGraph];
        self.startButton.selected = YES;
    } 
}

@end