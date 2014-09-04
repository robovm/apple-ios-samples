/*
     File: APLAttachmentsViewController.m
 Abstract: Provides the "Attachments + Collision" demonstration.
 
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

#import "APLAttachmentsViewController.h"
#import "APLDecorationView.h"

@interface APLAttachmentsViewController ()
@property (nonatomic, weak) IBOutlet UIView *square1;
//! The view that displays the attachment point on square1.
@property (nonatomic, weak) IBOutlet UIImageView *square1AttachmentView;
//! The view that the user drags to move square1.
@property (nonatomic, weak) IBOutlet UIImageView *attachmentView;
@property (nonatomic, strong) UIDynamicAnimator *animator;
@property (nonatomic, strong) UIAttachmentBehavior *attachmentBehavior;
@end


@implementation APLAttachmentsViewController

//| ----------------------------------------------------------------------------
- (void)viewDidLoad
{
    [super viewDidLoad];

    UIDynamicAnimator *animator = [[UIDynamicAnimator alloc] initWithReferenceView:self.view];
    
    UICollisionBehavior *collisionBehavior = [[UICollisionBehavior alloc] initWithItems:@[self.square1]];
    // Creates collision boundaries from the bounds of the dynamic animator's
    // reference view (self.view).
    collisionBehavior.translatesReferenceBoundsIntoBoundary = YES;
    [animator addBehavior: collisionBehavior];

    CGPoint squareCenterPoint = CGPointMake(self.square1.center.x, self.square1.center.y - 110.0);
    UIOffset attachmentPoint = UIOffsetMake(-25.0, -25.0);
    // By default, an attachment behavior uses the center of a view. By using a
    // small offset, we get a more interesting effect which will cause the view
    // to have rotation movement when dragging the attachment.
    UIAttachmentBehavior *attachmentBehavior = [[UIAttachmentBehavior alloc] initWithItem:self.square1 offsetFromCenter:attachmentPoint attachedToAnchor:squareCenterPoint];
    [animator addBehavior:attachmentBehavior];
    self.attachmentBehavior = attachmentBehavior;
    
    // Visually show the attachment points
    self.attachmentView.center = attachmentBehavior.anchorPoint;
    self.attachmentView.tintColor = [UIColor redColor];
    self.attachmentView.image = [self.attachmentView.image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    
    self.square1AttachmentView.center = CGPointMake(25.0, 25.0);
    self.square1AttachmentView.tintColor = [UIColor blueColor];
    self.square1AttachmentView.image = [self.square1AttachmentView.image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    
    // Visually show the connection between the attachment points.
    [(APLDecorationView*)self.view trackAndDrawAttachmentFromView:self.attachmentView toView:self.square1 withAttachmentOffset:CGPointMake(-25.0, -25.0)];

    self.animator = animator;
}


//| ----------------------------------------------------------------------------
//  IBAction for the Pan Gesture Recognizer that has been configured to track
//  touches in self.view.
//
- (IBAction)handleAttachmentGesture:(UIPanGestureRecognizer*)gesture
{
    [self.attachmentBehavior setAnchorPoint:[gesture locationInView:self.view]];
    self.attachmentView.center = self.attachmentBehavior.anchorPoint;
}

@end
