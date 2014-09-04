/*
     File: APLPendulumBehavior.m
 Abstract: Composite Dyanamic Behavior that provides a pendulum behavior.
 
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

#import "APLPendulumBehavior.h"

@interface APLPendulumBehavior ()
@property (nonatomic, strong) UIAttachmentBehavior *draggingBehavior;
@property (nonatomic, strong) UIPushBehavior *pushBehavior;
@end


@implementation APLPendulumBehavior

//| ----------------------------------------------------------------------------
//! Initializes and returns a newly allocated APLPendulumBehavior which suspends
//! @a item hanging from @a p at a fixed distance (derived from the current
//! distance from @a item to @a p.).
//
- (instancetype)initWithWeight:(id<UIDynamicItem>)item suspendedFromPoint:(CGPoint)p
{
    self = [super init];
    if (self)
    {
        // The high-level pendulum behavior is built from 2 primitive behaviors.
        UIGravityBehavior *gravityBehavior = [[UIGravityBehavior alloc] initWithItems:@[item]];
        UIAttachmentBehavior *attachmentBehavior = [[UIAttachmentBehavior alloc] initWithItem:item attachedToAnchor:p];
        
        // These primative behaviors allow the user to drag the pendulum weight.
        UIAttachmentBehavior *draggingBehavior = [[UIAttachmentBehavior alloc] initWithItem:item attachedToAnchor:CGPointZero];
        UIPushBehavior *pushBehavior = [[UIPushBehavior alloc] initWithItems:@[item] mode:UIPushBehaviorModeInstantaneous];
        
        pushBehavior.active = NO;
        
        [self addChildBehavior:gravityBehavior];
        [self addChildBehavior:attachmentBehavior];
        
        [self addChildBehavior:pushBehavior];
        // The draggingBehavior is added as needed, when the user begins dragging
        // the weight.
        
        self.draggingBehavior = draggingBehavior;
        self.pushBehavior = pushBehavior;
    }
    return self;
}


//| ----------------------------------------------------------------------------
- (void)beginDraggingWeightAtPoint:(CGPoint)p
{
    self.draggingBehavior.anchorPoint = p;
    [self addChildBehavior:self.draggingBehavior];
}


//| ----------------------------------------------------------------------------
- (void)dragWeightToPoint:(CGPoint)p
{
    self.draggingBehavior.anchorPoint = p;
}


//| ----------------------------------------------------------------------------
- (void)endDraggingWeightWithVelocity:(CGPoint)v
{
    CGFloat magnitude = sqrtf(powf(v.x, 2.0)+powf(v.y, 2.0));
    CGFloat angle = atan2(v.y, v.x);
    
    // Reduce the volocity to something meaningful.  (Prevents the user from
    // flinging the pendulum weight).
    magnitude /= 500;
    
    self.pushBehavior.angle = angle;
    self.pushBehavior.magnitude = magnitude;
    self.pushBehavior.active = YES;
    
    [self removeChildBehavior:self.draggingBehavior];
}

@end
