/*
     File: BasicInterpolationVC.m
 Abstract: View controller that applies interpolation motion effects to
 the position of it's subviews.  A basic parallax effect is created in which a
 view in the foreground appears to float above a recessed background.
 Demonstrates UIInterpolatingMotionEffect and UIMotionEffectGroup.
 
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

#import "BasicInterpolationVC.h"

@interface BasicInterpolationVC ()

@property (nonatomic, weak) IBOutlet UIImageView *backgroundView;
@property (nonatomic, weak) IBOutlet UIView *foregroundView;
@property (nonatomic, weak) IBOutlet UISwitch *foregroundEffectSwitch;
@property (nonatomic, weak) IBOutlet UISwitch *backgroundEffectSwitch;

@property (nonatomic, strong) UIMotionEffectGroup *foregroundMotionEffect;
@property (nonatomic, strong) UIMotionEffectGroup *backgroundMotionEffect;

@property (nonatomic, weak) IBOutlet NSLayoutConstraint *separatorHeightConstraint;
@property (nonatomic, weak) IBOutlet UITextView *textView;

@end


@implementation BasicInterpolationVC

//| ----------------------------------------------------------------------------
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.foregroundView.layer.cornerRadius = 6.0f;
    self.foregroundView.layer.masksToBounds = YES;
    
    // Create and apply the motion effect for the foreground view.
    {
        UIInterpolatingMotionEffect *xAxis = [[UIInterpolatingMotionEffect alloc] initWithKeyPath:@"center.x" type:UIInterpolatingMotionEffectTypeTiltAlongHorizontalAxis];
        xAxis.minimumRelativeValue = @(-15.0);
        xAxis.maximumRelativeValue = @(15.0);
        
        UIInterpolatingMotionEffect *yAxis = [[UIInterpolatingMotionEffect alloc] initWithKeyPath:@"center.y" type:UIInterpolatingMotionEffectTypeTiltAlongVerticalAxis];
        yAxis.minimumRelativeValue = @(-15.0);
        yAxis.maximumRelativeValue = @(15.0);
        
        self.foregroundMotionEffect = [[UIMotionEffectGroup alloc] init];
        self.foregroundMotionEffect.motionEffects = @[xAxis, yAxis];
        
        [self.foregroundView addMotionEffect:self.foregroundMotionEffect];
    }
    
    // Create and apply the motion effect for the background view.
    {
        // When configuring a motion effect that effects the position of a
        // view, a positive minimum value combined with a negative maximum
        // value create the illusion of the view being recessed below
        // the screen plane.  For the best looking effect, make sure the
        // view is larger than the bounds of its parent view.
        
        UIInterpolatingMotionEffect *xAxis = [[UIInterpolatingMotionEffect alloc] initWithKeyPath:@"center.x" type:UIInterpolatingMotionEffectTypeTiltAlongHorizontalAxis];
        xAxis.minimumRelativeValue = @(25.0);
        xAxis.maximumRelativeValue = @(-25.0);
        
        UIInterpolatingMotionEffect *yAxis = [[UIInterpolatingMotionEffect alloc] initWithKeyPath:@"center.y" type:UIInterpolatingMotionEffectTypeTiltAlongVerticalAxis];
        yAxis.minimumRelativeValue = @(32.0);
        yAxis.maximumRelativeValue = @(-32.0);
        
        self.backgroundMotionEffect = [[UIMotionEffectGroup alloc] init];
        self.backgroundMotionEffect.motionEffects = @[xAxis, yAxis];
        
        [self.backgroundView addMotionEffect:self.backgroundMotionEffect];
    }
    
    [self switchValueChanged:Nil];
    
    self.separatorHeightConstraint.constant = 0.5;
}


//| ----------------------------------------------------------------------------
- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [self.textView flashScrollIndicators];
}


//| ----------------------------------------------------------------------------
- (IBAction)switchValueChanged:(id)sender
{
    // Update motion effects on the foregroundView.
    if (self.foregroundEffectSwitch.on &&
        ![self.foregroundView.motionEffects containsObject:self.foregroundMotionEffect])
    {
        [self.foregroundView addMotionEffect:self.foregroundMotionEffect];
    }
    else if (!self.foregroundEffectSwitch.on &&
             [self.foregroundView.motionEffects containsObject:self.foregroundMotionEffect])
    {
        [self.foregroundView removeMotionEffect:self.foregroundMotionEffect];
    }
    
    // Update motion effects on the backgroundView.
    if (self.backgroundEffectSwitch.on &&
        ![self.backgroundView.motionEffects containsObject:self.backgroundMotionEffect])
    {
        [self.backgroundView addMotionEffect:self.backgroundMotionEffect];
    }
    else if (!self.backgroundEffectSwitch.on &&
             [self.backgroundView.motionEffects containsObject:self.backgroundMotionEffect])
    {
        [self.backgroundView removeMotionEffect:self.backgroundMotionEffect];
    }
}

@end
