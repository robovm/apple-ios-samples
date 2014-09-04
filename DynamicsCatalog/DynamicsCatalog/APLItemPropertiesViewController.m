/*
     File: APLItemPropertiesViewController.m
 Abstract: Provides the "Item Properties" demonstration.
 
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

#import "APLItemPropertiesViewController.h"

@interface APLItemPropertiesViewController ()
@property (nonatomic, weak) IBOutlet UIView *square1;
@property (nonatomic, weak) IBOutlet UIView *square2;
@property (nonatomic, strong) UIDynamicItemBehavior *square1PropertiesBehavior;
@property (nonatomic, strong) UIDynamicItemBehavior *square2PropertiesBehavior;
@property (nonatomic, strong) UIDynamicAnimator *animator;
@end


@implementation APLItemPropertiesViewController

//| ----------------------------------------------------------------------------
- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    UIDynamicAnimator *animator = [[UIDynamicAnimator alloc] initWithReferenceView:self.view];
    
    // We want to show collisions between views and boundaries with different
    // elasticities, we thus associate the two views to gravity and collision
    // behaviors. We will only change the restitution parameter for one of these
    // views.
    UIGravityBehavior *gravityBeahvior = [[UIGravityBehavior alloc] initWithItems:@[self.square1, self.square2]];
    UICollisionBehavior *collisionBehavior = [[UICollisionBehavior alloc] initWithItems:@[self.square1, self.square2]];
    collisionBehavior.translatesReferenceBoundsIntoBoundary = YES;

    // A dynamic item behavior gives access to low-level properties of an item
    // in Dynamics, here we change restitution on collisions only for square2,
    // and keep square1 with its default value.
    self.square2PropertiesBehavior = [[UIDynamicItemBehavior alloc] initWithItems:@[self.square2]];
    self.square2PropertiesBehavior.elasticity = 0.5;
    
    // A dynamic item behavior is created for square1 so it's velocity can be
    // manipulated in the -resetAction: method.
    self.square1PropertiesBehavior = [[UIDynamicItemBehavior alloc] initWithItems:@[self.square1]];

    [animator addBehavior:self.square1PropertiesBehavior];
    [animator addBehavior:self.square2PropertiesBehavior];
    [animator addBehavior:gravityBeahvior];
    [animator addBehavior:collisionBehavior];
    
    self.animator = animator;
}


//| ----------------------------------------------------------------------------
//  IBAction for the "Replay" bar button item used to restart the demo.
//
- (IBAction)replayAction:(id)sender
{
    // Moving an item does not reset its velocity.  Here we do that manually
    // using the dynamic item behaviors, adding the inverse velocity for each
    // square.
    [self.square1PropertiesBehavior addLinearVelocity:CGPointMake(0, -1 * [self.square1PropertiesBehavior linearVelocityForItem:self.square1].y) forItem:self.square1];
    self.square1.center = CGPointMake(90, 171);
    [self.animator updateItemUsingCurrentState:self.square1];
    
    [self.square2PropertiesBehavior addLinearVelocity:CGPointMake(0, -1 * [self.square2PropertiesBehavior linearVelocityForItem:self.square2].y) forItem:self.square2];
    self.square2.center = CGPointMake(230, 171);
    [self.animator updateItemUsingCurrentState:self.square2];
}

@end
