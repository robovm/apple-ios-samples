/*
     File: APLCollisionsGravitySpringViewController.m
 Abstract: Provides the "Collisions + Gravity + Spring" demonstration.
 
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

#import "APLCollisionsGravitySpringViewController.h"
#import "APLDecorationView.h"

@interface APLCollisionsGravitySpringViewController ()
@property (nonatomic, weak) IBOutlet UIView *square1;
//! The view that displays the attachment point on square1.
@property (nonatomic, weak) IBOutlet UIImageView *square1AttachmentView;
//! The view that the user drags to move square1.
@property (nonatomic, weak) IBOutlet UIImageView *attachmentView;
@property (nonatomic, strong) UIDynamicAnimator *animator;
@property (nonatomic, strong) UIAttachmentBehavior *attachmentBehavior;
@end


@implementation APLCollisionsGravitySpringViewController

//| ----------------------------------------------------------------------------
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    UIDynamicAnimator *animator = [[UIDynamicAnimator alloc] initWithReferenceView:self.view];
    UIGravityBehavior *gravityBeahvior = [[UIGravityBehavior alloc] initWithItems:@[self.square1]];
    UICollisionBehavior *collisionBehavior = [[UICollisionBehavior alloc] initWithItems:@[self.square1]];

    CGPoint anchorPoint = CGPointMake(self.square1.center.x, self.square1.center.y - 110.0);
    UIAttachmentBehavior *attachmentBehavior = [[UIAttachmentBehavior alloc] initWithItem:self.square1 attachedToAnchor:anchorPoint];
    collisionBehavior.translatesReferenceBoundsIntoBoundary = YES;
    // These parameters set the attachment in spring mode, instead of a rigid
    // connection.
    [attachmentBehavior setFrequency:1.0];
    [attachmentBehavior setDamping:0.1];

    // Visually show the attachment point.
    self.attachmentView.center = attachmentBehavior.anchorPoint;
    self.attachmentView.tintColor = [UIColor redColor];
    self.attachmentView.image = [self.attachmentView.image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    
    // Visually show the attachment point.
    self.square1AttachmentView.center = CGPointMake(50.0, 50.0);
    self.square1AttachmentView.tintColor = [UIColor blueColor];
    self.square1AttachmentView.image = [self.square1AttachmentView.image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];

    // Visually show the connection between the attachment points.
    [(APLDecorationView*)self.view trackAndDrawAttachmentFromView:self.attachmentView toView:self.square1 withAttachmentOffset:CGPointZero];
    
    [animator addBehavior:attachmentBehavior];
    [animator addBehavior:collisionBehavior];
    [animator addBehavior:gravityBeahvior];
    self.animator = animator;

    self.attachmentBehavior = attachmentBehavior;
}


//| ----------------------------------------------------------------------------
//  IBAction for the Pan Gesture Recognizer and Tap Gesture Recognizer that have
//  been configured to track touches in self.view.  (Both types of gesture
//  recognizers are used so that square1AttachmentView is repositioned
//  immediately in response to a new touch, instead of waiting for that touch
//  to be recognized as a drag.)
//
- (IBAction)handleSpringAttachmentGesture:(UIGestureRecognizer*)gesture
{
    [self.attachmentBehavior setAnchorPoint:[gesture locationInView:self.view]];
    self.attachmentView.center = self.attachmentBehavior.anchorPoint;
}

@end

