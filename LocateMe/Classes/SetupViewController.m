/*
     File: SetupViewController.m
 Abstract: Displayed by either a GetLocationViewController or a TrackLocationViewController, this view controller is presented modally and communicates back to the presenting controller using a simple delegate protocol. The protocol sends setupViewController:didFinishSetupWithInfo: to its delegate with a dictionary containing a desired accuracy and either a timeout or a distance filter value. A custom UIPickerView specifies the desired accuracy. A slider is shown for setting the timeout or distance filter. This view controller can be initialized using either of two nib files: GetLocationSetupView.xib or TrackLocationSetupView.xib. These nibs have nearly identical layouts, but differ in the labels and attributes for the slider.
 
  Version: 2.2
 
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

#import "SetupViewController.h"
#import <CoreLocation/CoreLocation.h>

NSString * const kSetupInfoKeyAccuracy = @"SetupInfoKeyAccuracy";
NSString * const kSetupInfoKeyDistanceFilter = @"SetupInfoKeyDistanceFilter";
NSString * const kSetupInfoKeyTimeout = @"SetupInfoKeyTimeout";

static NSString * const kAccuracyNameKey = @"AccuracyNameKey";
static NSString * const kAccuracyValueKey = @"AccuracyValueKey";

@implementation SetupViewController

@synthesize delegate;
@synthesize setupInfo;
@synthesize accuracyOptions;
@synthesize configureForTracking;
@synthesize accuracyPicker;
@synthesize slider;

- (void)viewDidLoad {
    NSMutableArray *options = [NSMutableArray array];
    [options addObject:[NSDictionary dictionaryWithObjectsAndKeys:NSLocalizedString(@"AccuracyBest", @"AccuracyBest"), kAccuracyNameKey, [NSNumber numberWithDouble:kCLLocationAccuracyBest], kAccuracyValueKey, nil]];
    [options addObject:[NSDictionary dictionaryWithObjectsAndKeys:NSLocalizedString(@"Accuracy10", @"Accuracy10"), kAccuracyNameKey, [NSNumber numberWithDouble:kCLLocationAccuracyNearestTenMeters], kAccuracyValueKey, nil]];
    [options addObject:[NSDictionary dictionaryWithObjectsAndKeys:NSLocalizedString(@"Accuracy100", @"Accuracy100"), kAccuracyNameKey, [NSNumber numberWithDouble:kCLLocationAccuracyHundredMeters], kAccuracyValueKey, nil]];
    [options addObject:[NSDictionary dictionaryWithObjectsAndKeys:NSLocalizedString(@"Accuracy1000", @"Accuracy1000"), kAccuracyNameKey, [NSNumber numberWithDouble:kCLLocationAccuracyKilometer], kAccuracyValueKey, nil]];
    [options addObject:[NSDictionary dictionaryWithObjectsAndKeys:NSLocalizedString(@"Accuracy3000", @"Accuracy3000"), kAccuracyNameKey, [NSNumber numberWithDouble:kCLLocationAccuracyThreeKilometers], kAccuracyValueKey, nil]];
    self.accuracyOptions = options;
}

- (void)viewDidUnload {
    self.accuracyPicker = nil;
    self.slider = nil;
}

- (void)dealloc {
    [accuracyPicker release];
    [slider release];
    [setupInfo release];
    [super dealloc];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [accuracyPicker selectRow:2 inComponent:0 animated:NO];
    self.setupInfo = [NSMutableDictionary dictionary];
    [setupInfo setObject:[NSNumber numberWithDouble:100.0] forKey:kSetupInfoKeyDistanceFilter]; 
    [setupInfo setObject:[NSNumber numberWithDouble:30] forKey:kSetupInfoKeyTimeout];
    [setupInfo setObject:[NSNumber numberWithDouble:kCLLocationAccuracyHundredMeters] forKey:kSetupInfoKeyAccuracy];
}

- (IBAction)done:(id)sender {
    [self dismissModalViewControllerAnimated:YES];
    if ([delegate respondsToSelector:@selector(setupViewController:didFinishSetupWithInfo:)]) {
        [delegate setupViewController:self didFinishSetupWithInfo:setupInfo];
    }
}

- (IBAction)sliderChangedValue:(id)sender {
    if (configureForTracking) {
        [setupInfo setObject:[NSNumber numberWithDouble:pow(10, [(UISlider *)sender value])] forKey:kSetupInfoKeyDistanceFilter]; 
    } else {
        [setupInfo setObject:[NSNumber numberWithDouble:[(UISlider *)sender value]] forKey:kSetupInfoKeyTimeout];
    }
}

#pragma mark Picker DataSource/Delegate

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
    return 1;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
    return 5;
}

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
    NSDictionary *optionForRow = [accuracyOptions objectAtIndex:row];
    return [optionForRow objectForKey:kAccuracyNameKey];
}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component {
    NSDictionary *optionForRow = [accuracyOptions objectAtIndex:row];
    [setupInfo setObject:[optionForRow objectForKey:kAccuracyValueKey] forKey:kSetupInfoKeyAccuracy];
}


@end
