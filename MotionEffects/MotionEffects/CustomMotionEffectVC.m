/*
     File: CustomMotionEffectVC.m
 Abstract: Demonstrates using a custom motion effect to bring a 
 specially-prepared image to life by allowing the viewer to look behind objects
 in the foreground as they rotate the device.
 
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
 
 Copyright (C) 2014 Apple Inc. All Rights Reserved.
 
 */

#import "CustomMotionEffectVC.h"
#import "PerspectiveMotionEffect.h"

@interface CustomMotionEffectVC () <UINavigationControllerDelegate>
@property (nonatomic, weak) CALayer *sky;
@property (nonatomic, weak) CALayer *water;
@property (nonatomic, weak) CALayer *foreground5;
@property (nonatomic, weak) CALayer *foreground4;
@property (nonatomic, weak) CALayer *foreground3;
@property (nonatomic, weak) CALayer *foreground2;
@property (nonatomic, weak) CALayer *foreground1;
@property (nonatomic, strong) PerspectiveMotionEffect *motionEffect;
@end


@implementation CustomMotionEffectVC

//| ----------------------------------------------------------------------------
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    NSBundle *mainBundle = [NSBundle mainBundle];
    
    CALayer* (^LoadPhotoLayer)(NSString*) = ^(NSString *imgName) {
        UIImage *layerImage = [[UIImage alloc] initWithContentsOfFile:[mainBundle pathForResource:imgName ofType:@"png"]];
        CALayer *layer = [CALayer layer];
        layer.contents = (__bridge id)(layerImage.CGImage);
        layer.bounds = CGRectMake(0, 0, layerImage.size.width, layerImage.size.height);
        layer.contentsScale = layerImage.scale;
        [self.view.layer addSublayer:layer];
        return layer;
    };

    self.sky = LoadPhotoLayer(@"Sky");
    self.water = LoadPhotoLayer(@"Water");
    self.foreground5 = LoadPhotoLayer(@"Foreground5");
    self.foreground4 = LoadPhotoLayer(@"Foreground4");
    self.foreground3 = LoadPhotoLayer(@"Foreground3");
    self.foreground2 = LoadPhotoLayer(@"Foreground2");
    self.foreground1 = LoadPhotoLayer(@"Foreground1");
    
    // Create, configure, and apply our custom motion effect.
    // See the ReadMe for a discussion about how the values used to
    // configure the PerspectiveMotionEffect were chosen.
    PerspectiveMotionEffect *motionEffect = [[PerspectiveMotionEffect alloc] init];
    motionEffect.cameraPositionZ = 1504;
    motionEffect.maximumViewingAngleX = 2.0 * M_PI / 180.0f;
    motionEffect.maximumViewingAngleY = 18.0 * M_PI / 180.0f;
    [self.view addMotionEffect:motionEffect];
    self.motionEffect = motionEffect;
}


//| ----------------------------------------------------------------------------
- (void)viewDidLayoutSubviews
{
    // The layers must be positioned here because the bounds of our view are
    // undefined until layout has occurred at least once, which has not happened
    // when -viewDidLoad was invoked.
    
    CGPoint center = CGPointMake(CGRectGetMidX(self.view.bounds), CGRectGetMidY(self.view.bounds));
    
    // See the ReadMe for a discussion about how these position values were
    // chosen.
    
    self.sky.position = center;
    
    self.water.position = center;
    self.water.zPosition = 5;
    
    self.foreground5.position = center;
    self.foreground5.zPosition = 40;
    
    self.foreground4.position = center;
    self.foreground4.zPosition = 66;
    
    self.foreground3.position = center;
    self.foreground3.zPosition = 82;
    
    self.foreground2.position = center;
    self.foreground2.zPosition = 97;
    
    self.foreground1.position = center;
    self.foreground1.zPosition = 104;
}


//| ----------------------------------------------------------------------------
- (void)viewDidAppear:(BOOL)animated
{
    // Start with the navigation bar hidden so the full image is visible.
    [self.navigationController setNavigationBarHidden:YES animated:YES];
}


//| ----------------------------------------------------------------------------
//! Toggles the 'hidden' property of the navigation bar.
//
- (IBAction)tapGestureRecognizerAction:(id)sender
{
    [self.navigationController setNavigationBarHidden:!self.navigationController.navigationBarHidden animated:YES];
}


//| ----------------------------------------------------------------------------
- (IBAction)dismissButtonAction:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:NULL];
}


//| ----------------------------------------------------------------------------
- (BOOL)prefersStatusBarHidden
{
    return YES;
}

@end

