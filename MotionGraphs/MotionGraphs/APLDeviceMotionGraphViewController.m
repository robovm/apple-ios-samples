
/*
     File: APLDeviceMotionGraphViewController.m
 Abstract: View controller to manage display of output from the motion detector.
 
  Version: 1.0.1
 
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

#import "APLDeviceMotionGraphViewController.h"
#import "APLAppDelegate.h"
#import "APLGraphView.h"


static const NSTimeInterval deviceMotionMin = 0.01;

typedef enum {
    kDeviceMotionGraphTypeAttitude = 0,
    kDeviceMotionGraphTypeRotationRate,
    kDeviceMotionGraphTypeGravity,
    kDeviceMotionGraphTypeUserAcceleration
} DeviceMotionGraphType;

@interface APLDeviceMotionGraphViewController ()

@property (weak, nonatomic) IBOutlet UISegmentedControl *segmentedControl;

@property (strong, nonatomic) IBOutletCollection(APLGraphView) NSArray *graphViews;
@property (strong, nonatomic) IBOutlet UILabel *graphLabel;

@property (strong, nonatomic) NSArray *graphTitles;

@end



@implementation APLDeviceMotionGraphViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.graphTitles = @[@"deviceMotion.attitude", @"deviceMotion.rotationRate", @"deviceMotion.gravity", @"deviceMotion.userAcceleration"];
    [self showGraphAtIndex:0];
}


- (IBAction)segmentedControlChanged:(UISegmentedControl *)sender
{
    NSUInteger selectedIndex = sender.selectedSegmentIndex;
    [self showGraphAtIndex:selectedIndex];
}


- (void)showGraphAtIndex:(NSUInteger)selectedIndex
{
    [self.graphViews enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        BOOL hidden = (idx != selectedIndex);
        UIView *graphView = obj;
        graphView.hidden = hidden;
    }];

    self.graphLabel.text = [self.graphTitles objectAtIndex:selectedIndex];
}


- (void)startUpdatesWithSliderValue:(int)sliderValue
{
    NSTimeInterval delta = 0.005;
    NSTimeInterval updateInterval = deviceMotionMin + delta * sliderValue;

    CMMotionManager *mManager = [(APLAppDelegate *)[[UIApplication sharedApplication] delegate] sharedManager];

    APLDeviceMotionGraphViewController * __weak weakSelf = self;

    if ([mManager isDeviceMotionAvailable] == YES) {
        [mManager setDeviceMotionUpdateInterval:updateInterval];
        [mManager startDeviceMotionUpdatesToQueue:[NSOperationQueue mainQueue] withHandler:^(CMDeviceMotion *deviceMotion, NSError *error) {
            // attitude
            [[weakSelf.graphViews objectAtIndex:kDeviceMotionGraphTypeAttitude] addX:deviceMotion.attitude.roll y:deviceMotion.attitude.pitch z:deviceMotion.attitude.yaw];
            //rotationRate
            [[weakSelf.graphViews objectAtIndex:kDeviceMotionGraphTypeRotationRate] addX:deviceMotion.rotationRate.x y:deviceMotion.rotationRate.y z:deviceMotion.rotationRate.z];
            // gravity
            [[weakSelf.graphViews objectAtIndex:kDeviceMotionGraphTypeGravity] addX:deviceMotion.gravity.x y:deviceMotion.gravity.y z:deviceMotion.gravity.z];
            // userAcceleration
            [[weakSelf.graphViews objectAtIndex:kDeviceMotionGraphTypeUserAcceleration] addX:deviceMotion.userAcceleration.x y:deviceMotion.userAcceleration.y z:deviceMotion.userAcceleration.z];

            switch (weakSelf.segmentedControl.selectedSegmentIndex) {
                case kDeviceMotionGraphTypeAttitude:
                    [weakSelf setLabelValueRoll:deviceMotion.attitude.roll pitch:deviceMotion.attitude.pitch yaw:deviceMotion.attitude.yaw];
                    break;
                case kDeviceMotionGraphTypeRotationRate:
                    [weakSelf setLabelValueX:deviceMotion.rotationRate.x y:deviceMotion.rotationRate.y z:deviceMotion.rotationRate.z];
                    break;
                case kDeviceMotionGraphTypeGravity:
                    [weakSelf setLabelValueX:deviceMotion.gravity.x y:deviceMotion.gravity.y z:deviceMotion.gravity.z];
                    break;
                case kDeviceMotionGraphTypeUserAcceleration:
                    [weakSelf setLabelValueX:deviceMotion.userAcceleration.x y:deviceMotion.userAcceleration.y z:deviceMotion.userAcceleration.z];
                    break;
                default:
                    break;
            }
        }];
    }

    self.graphLabel.text = [self.graphTitles objectAtIndex:[self.segmentedControl selectedSegmentIndex]];
    self.updateIntervalLabel.text = [NSString stringWithFormat:@"%f", updateInterval];
}


- (void)stopUpdates
{
    CMMotionManager *mManager = [(APLAppDelegate *)[[UIApplication sharedApplication] delegate] sharedManager];

    if ([mManager isDeviceMotionActive] == YES) {
        [mManager stopDeviceMotionUpdates];
    }
}


@end
