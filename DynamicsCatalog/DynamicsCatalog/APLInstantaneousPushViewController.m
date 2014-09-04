/*
     File: APLInstantaneousPushViewController.m
 Abstract: Provides the "Instantaneous Push + Collision" demo.
 Tapping the view changes the angle and magnitude of the impulse. 
 To visually show the impulse vector on screen, a red arrow representing 
 the angle and magnitude of this vector is briefly drawn on screen.
 
  Version: 1.3
 
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
 
 Copyright (C) 2013 Apple Inc. All Rights Reserved.
 
 */

#import "APLInstantaneousPushViewController.h"
#import "APLDecorationView.h"

@interface APLInstantaneousPushViewController ()
@property (nonatomic, weak) IBOutlet UIView *square1;
@property (nonatomic, strong) UIDynamicAnimator *animator;
@property (nonatomic, strong) UIPushBehavior *pushBehavior;
@end


@implementation APLInstantaneousPushViewController

//| ----------------------------------------------------------------------------
- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    UIDynamicAnimator *animator = [[UIDynamicAnimator alloc] initWithReferenceView:self.view];

    UICollisionBehavior *collisionBehavior = [[UICollisionBehavior alloc] initWithItems:@[self.square1]];
    // Account for any top and bottom bars when setting up the reference bounds.
    [collisionBehavior setTranslatesReferenceBoundsIntoBoundaryWithInsets:UIEdgeInsetsMake(self.topLayoutGuide.length, 0, self.bottomLayoutGuide.length, 0)];
    [animator addBehavior:collisionBehavior];

    UIPushBehavior *pushBehavior = [[UIPushBehavior alloc] initWithItems:@[self.square1] mode:UIPushBehaviorModeInstantaneous];
    pushBehavior.angle = 0.0;
    pushBehavior.magnitude = 0.0;
    [animator addBehavior:pushBehavior];
    self.pushBehavior = pushBehavior;

    self.animator = animator;
}


//| ----------------------------------------------------------------------------
//  IBAction for the Tap Gesture Recognizer that has been configured to track
//  touches in self.view.
//
- (IBAction)handlePushGesture:(UITapGestureRecognizer*)gesture
{
    // Tapping will change the angle and magnitude of the impulse. To visually
    // show the impulse vector on screen, a red arrow representing the angle
    // and magnitude of this vector is briefly drawn.
    CGPoint p = [gesture locationInView:self.view];
    CGPoint o = CGPointMake(CGRectGetMidX(self.view.bounds), CGRectGetMidY(self.view.bounds));
    CGFloat distance = sqrtf(powf(p.x-o.x, 2.0)+powf(p.y-o.y, 2.0));
    CGFloat angle = atan2(p.y-o.y, p.x-o.x);
    distance = MIN(distance, 100.0);
    
    // Display an arrow showing the direction and magnitude of the applied
    // impulse.
    [(APLDecorationView*)self.view drawMagnitudeVectorWithLength:distance angle:angle color:[UIColor redColor] forLimitedTime:YES];

    // These two lines change the actual force vector.
    [self.pushBehavior setMagnitude:distance / 100.0];
    [self.pushBehavior setAngle:angle];
    // A push behavior in instantaneous (impulse) mode automatically
    // deactivate itself after applying the impulse. We thus need to reactivate
    // it when changing the impulse vector.
    [self.pushBehavior setActive:TRUE];
}

@end
