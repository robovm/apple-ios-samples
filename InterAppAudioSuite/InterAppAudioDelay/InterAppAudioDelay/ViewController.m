/*
     File: ViewController.m
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
#import "Delay.h"
#import "AppDelegate.h"

@implementation IADelayViewController

#pragma mark Initialization / deallocation
- (void)dealloc {
    [delayAmount release];
    [delayAmountSlider release];
    [feedbackAmount release];
    [lowPassAmount release];
    [wetDryAmount release];
    [feedbackSlider release];
    [lowPassSlider release];
    [wetDrySlider release];
    
    [super dealloc];
}

- (void) viewDidLoad {
    [super viewDidLoad];
    
    transportView.engine = DELAY_ENGINE;
    [self setInitialSliderValues];
}

- (void) setInitialSliderValues {
    /* bind sliders to audio parameters and ranges */
    int delayTag = [DELAY_ENGINE getDelayTag];
	[delayAmountSlider setTag:delayTag];
    [delayAmountSlider setMinimumValue:[DELAY_ENGINE getMinValueForParam:delayTag]];
    [delayAmountSlider setMaximumValue:[DELAY_ENGINE getMaxValueForParam:delayTag]];
	
    //Get the initial slider values from the delay engine
    float delayTime = [DELAY_ENGINE delayTime];
    [delayAmountSlider setValue:delayTime];
	[delayAmount setText: [NSString stringWithFormat:@"%.02f secs", delayTime]];
    
    int wetDryTag = [DELAY_ENGINE getWetDryTag];
    [wetDrySlider setTag:wetDryTag];
    [wetDrySlider setMinimumValue:[DELAY_ENGINE getMinValueForParam:wetDryTag]];
    [wetDrySlider setMaximumValue:[DELAY_ENGINE getMaxValueForParam:wetDryTag]];

    //wetDrySlider
    float wetDry = [DELAY_ENGINE wetDryMix];
    [wetDrySlider setValue:wetDry];
	[wetDryAmount setText: [NSString stringWithFormat:@"%.01f %%", wetDry]];
    
    int feedbackTag = [DELAY_ENGINE getFeedbackTag];
    [feedbackSlider setMinimumValue:[DELAY_ENGINE getMinValueForParam:feedbackTag]];
    [feedbackSlider setMaximumValue:[DELAY_ENGINE getMaxValueForParam:feedbackTag]];
 
	//feedbackSlider
    float feedback = [DELAY_ENGINE feedback];
    [feedbackSlider setValue:feedback];
	[feedbackAmount setText: [NSString stringWithFormat:@"%.01f %%", feedback]];

    int lowPassCutoffTag = [DELAY_ENGINE getLowPassCutoffTag];
    [lowPassSlider setMinimumValue:[DELAY_ENGINE getMinValueForParam:lowPassCutoffTag]];
    [lowPassSlider setMaximumValue:[DELAY_ENGINE getMaxValueForParam:lowPassCutoffTag]];

    //lowPassSlider
    float lowPassCutOff = [DELAY_ENGINE lowPassCutoff];
    [lowPassSlider setValue:lowPassCutOff];
	[lowPassAmount setText: [NSString stringWithFormat:@"%.0f Hz", lowPassCutOff]];

	UIColor *keyColor = [UIColor colorWithRed:.988 green:.663 blue:.196 alpha:1];
	[delayAmountSlider	setMinimumTrackTintColor: keyColor];
	[wetDrySlider		setMinimumTrackTintColor: keyColor];
	[feedbackSlider		setMinimumTrackTintColor: keyColor];
	[lowPassSlider		setMinimumTrackTintColor: keyColor];
}

#pragma mark IBActions
- (IBAction) delayAmountSlider:(id) sender {
    [DELAY_ENGINE setDelayTime:[((UISlider *)sender) value]];
	[delayAmount setText: [NSString stringWithFormat:@"%.2f secs", [((UISlider *)sender) value]]];
}

- (IBAction) feedbackAmountSlider:(id) sender {
    [DELAY_ENGINE setFeedback:[((UISlider *)sender) value]];
	[feedbackAmount setText: [NSString stringWithFormat:@"%.1f %%", [((UISlider *)sender) value]]];
}

- (IBAction) lowpassAmountSlider:(id) sender {
    [DELAY_ENGINE setLowPassCutoff:[((UISlider *)sender) value]];
	[lowPassAmount setText: [NSString stringWithFormat:@"%.0f Hz", [((UISlider *)sender) value]]];
}

- (IBAction) wetDryAmountSlider:(id) sender {
    [DELAY_ENGINE setWetDryMix:[((UISlider *)sender) value]];
	[wetDryAmount setText: [NSString stringWithFormat:@"%.01f %%", [((UISlider *)sender) value]]];
}

@end
