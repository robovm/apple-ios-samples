/*
    File: MyViewController.m 
Abstract: The main view controller. 
 Version: 1.2.2 
 
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

#import "MyViewController.h"

#define kTransitionDuration	0.75

@implementation MyViewController

@synthesize instructionsView, eqView, webView, contentView, infoButtonItem, eqButtonItem, doneButtonItem, startButton, bus0Switch, bus0VolumeSlider, bus1Switch, bus1VolumeSlider, outputVolumeSlider, eqSwitch, graphController;

#pragma mark- UIView

- (void)viewDidLoad
{
	// load up the info text
    NSString *infoSouceFile = [[NSBundle mainBundle] pathForResource:@"info" ofType:@"html"];
	NSString *infoText = [NSString stringWithContentsOfFile:infoSouceFile encoding:NSUTF8StringEncoding error:nil];
    [self.webView loadHTMLString:infoText baseURL:nil];
    
    // set up start button
    UIImage *greenImage = [[UIImage imageNamed:@"green_button.png"] stretchableImageWithLeftCapWidth:12.0 topCapHeight:0.0];
	UIImage *redImage = [[UIImage imageNamed:@"red_button.png"] stretchableImageWithLeftCapWidth:12.0 topCapHeight:0.0];
	
	[startButton setBackgroundImage:greenImage forState:UIControlStateNormal];
	[startButton setBackgroundImage:redImage forState:UIControlStateSelected];
    
    // add the subview
    [self.view addSubview:instructionsView];
	[self.view addSubview:contentView];
	
	// add our custom buttons as the nav bars custom views
	UIButton* infoButton = [UIButton buttonWithType:UIButtonTypeInfoLight];
	[infoButton addTarget:self action:@selector(flipInfoAction:) forControlEvents:UIControlEventTouchUpInside];
    
    UIButton* disclosureButton = [UIButton buttonWithType:UIButtonTypeDetailDisclosure];   
	[disclosureButton addTarget:self action:@selector(flipEQAction:) forControlEvents:UIControlEventTouchUpInside];
	
    infoButtonItem = [[UIBarButtonItem alloc] initWithCustomView:infoButton];
    self.navigationItem.leftBarButtonItem = infoButtonItem;
    
    eqButtonItem = [[UIBarButtonItem alloc] initWithCustomView:disclosureButton];
    self.navigationItem.rightBarButtonItem = nil; // eqButtonItem;
	
	// create our done button for the flipped views (used later)
	doneButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:nil];
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
    [eqView release];
    [webView release];
    [contentView release];
    
    self.infoButtonItem = nil;
    self.eqButtonItem = nil;
    self.doneButtonItem = nil;

    [startButton release];
    
    [bus0Switch release];
    [bus0VolumeSlider release];
    [bus1Switch release];
    [bus1VolumeSlider release];
    [outputVolumeSlider release];
    [eqSwitch release];
        
    [graphController release];
    
	[super dealloc];
}

#pragma mark-

// set the mixers values according to the UI state
- (void)setUIDefaults
{
    [graphController enableInput:0 isOn:bus0Switch.isOn];
    [graphController enableInput:1 isOn:bus1Switch.isOn];
    [graphController setInputVolume:0 value:bus0VolumeSlider.value];
    [graphController setInputVolume:1 value:bus1VolumeSlider.value];
    [graphController setOutputVolume:outputVolumeSlider.value];
    
    bus0VolumeSlider.continuous = YES;
    bus1VolumeSlider.continuous = YES;
    outputVolumeSlider.continuous = YES;
    
    // the ipod eq has a list of presets, the first at index 0 is called "Disabled"
    // and is selected by default when the EQ instance is created -- we don't need
    // to specifically do anything since our default UI has the EQ turned off
    // however we do want to pick the "Flat" preset when the EQ is initially enabled
    // after that, it will represent what the user has selected from the list
    selectedEQPresetIndex = 8; // index 8 is the "Flat" preset
    
    // set the picker view UI to represent the initial preset value
    // this is offset by 1 since we don't display the 0th "Disabled" preset
    UIPickerView *thePickerView = (UIPickerView*)[eqView viewWithTag:100];
    [thePickerView selectRow:(selectedEQPresetIndex - 1) inComponent:0 animated:NO];
}

// do the info button flip
- (void)flipInfoAction:(id)sender
{
    if ([self.contentView superview]) {
        // flip to readme info view
        self.navigationItem.title = @"Read Me eh?";
        self.navigationItem.rightBarButtonItem = self.navigationItem.leftBarButtonItem = nil;
        
        [UIView transitionFromView:self.contentView
                            toView:self.instructionsView
                          duration:kTransitionDuration
                           options:UIViewAnimationOptionTransitionFlipFromLeft
                        completion:^(BOOL finished){
                                self.navigationItem.leftBarButtonItem = doneButtonItem;
                        }];
    } else {
        // flip back to main content view
        self.navigationItem.title = @"MixerEQGraph Test";
        self.navigationItem.rightBarButtonItem = self.navigationItem.leftBarButtonItem = nil;
        
        [UIView transitionFromView:self.instructionsView
                            toView:self.contentView
                          duration:kTransitionDuration
                           options:UIViewAnimationOptionTransitionFlipFromRight
                        completion:^(BOOL finished){
                                self.navigationItem.leftBarButtonItem = infoButtonItem;
                                if (eqSwitch.isOn) {
                                    self.navigationItem.rightBarButtonItem = eqButtonItem;
                                }

                        }];
    }
    
    doneButtonItem.action = @selector(flipInfoAction:);
}

// do the eq button flip
- (void)flipEQAction:(id)sende
{
    if ([self.contentView superview]) {
        // flip to eq view
        self.navigationItem.title = @"iPod Equalizer";
        self.navigationItem.rightBarButtonItem = self.navigationItem.leftBarButtonItem = nil;
        
        [UIView transitionFromView:self.contentView
                            toView:self.eqView
                          duration:kTransitionDuration
                           options:UIViewAnimationOptionTransitionFlipFromRight
                        completion:^(BOOL finished){
                                self.navigationItem.rightBarButtonItem = doneButtonItem;
                        }];
    } else {
        // flip back to main content view
        self.navigationItem.title = @"MixerEQGraph Test";
        self.navigationItem.rightBarButtonItem = self.navigationItem.leftBarButtonItem = nil;
        
        [UIView transitionFromView:self.eqView
                            toView:self.contentView
                          duration:kTransitionDuration
                           options:UIViewAnimationOptionTransitionFlipFromLeft
                        completion:^(BOOL finished){
                                self.navigationItem.leftBarButtonItem = infoButtonItem;
                                if (eqSwitch.isOn) {
                                    self.navigationItem.rightBarButtonItem = eqButtonItem;
                                }
                        }];
    }
    
    doneButtonItem.action = @selector(flipEQAction:);
}

// called if we've been interrupted and if we're playing, stop
- (void)stopForInterruption
{
    if (graphController.isPlaying) {
        [graphController stopAUGraph];
        self.startButton.selected = NO;
    }
}

#pragma mark- Actions

// handle input on/off switch action
- (IBAction)enableInput:(UISwitch *)sender
{
    UInt32 inputNum = [sender tag];
    AudioUnitParameterValue isOn = (AudioUnitParameterValue)sender.isOn;
    
    if (0 == inputNum) self.bus0VolumeSlider.enabled = isOn;
    if (1 == inputNum) self.bus1VolumeSlider.enabled = isOn;
                                    
    [graphController enableInput:inputNum isOn:isOn];
}

// handle input volume changes
- (IBAction)setInputVolume:(UISlider *)sender
{
	UInt32 inputNum = [sender tag];
    AudioUnitParameterValue value = sender.value;
    
    [graphController setInputVolume:inputNum value:value];
}

// handle output volume changes
- (IBAction)setOutputVolume:(UISlider *)sender
{
    AudioUnitParameterValue value = sender.value;
    
    [graphController setOutputVolume:value];
}

// turns on/off the EQ by selecting the "Disabled" preset when off
// and whatever the user has selected when on
- (IBAction)enableEQ:(UISwitch *)sender
{
    if (sender.isOn) {
        [graphController selectEQPreset:selectedEQPresetIndex];
        self.navigationItem.rightBarButtonItem = eqButtonItem;
    } else {
        [graphController selectEQPreset:0];
        self.navigationItem.rightBarButtonItem = nil;
    }
}

// handle the button press
- (IBAction)buttonPressedAction:(id)sender
{
    if (graphController.isPlaying) {
        [graphController stopAUGraph];
        self.startButton.selected = NO;
    } else {
        [graphController startAUGraph];
        self.startButton.selected = YES;
    } 
}

#pragma mark - UIPickerView

// methods to implement the picker view
- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)thePickerView {
	
	return 1;
}

- (NSInteger)pickerView:(UIPickerView *)thePickerView numberOfRowsInComponent:(NSInteger)component {
	
	return (CFArrayGetCount(graphController.iPodEQPresetsArray) - 1);
}

- (NSString *)pickerView:(UIPickerView *)thePickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
	
    AUPreset *currentPreset;
    
    currentPreset = (AUPreset *)CFArrayGetValueAtIndex(graphController.iPodEQPresetsArray, row + 1);
    
	return (NSString *)currentPreset->presetName;
}

- (void)pickerView:(UIPickerView *)thePickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component {
    
    selectedEQPresetIndex = row + 1;
    
    [graphController selectEQPreset:selectedEQPresetIndex];
}

@end