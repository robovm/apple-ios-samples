/*
     File: APAParallaxSprite.m
 Abstract: n/a
  Version: 1.2
 
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

#import "APAParallaxSprite.h"

@interface APAParallaxSprite ()
@property (nonatomic) CGFloat parallaxOffset;
@end

@implementation APAParallaxSprite

#pragma mark - Initialization
- (id)initWithSprites:(NSArray *)sprites usingOffset:(CGFloat)offset {
    self = [super init];
    
    if (self) {
        _usesParallaxEffect = YES;
        
        // Make sure our z layering is correct for the stack.
        CGFloat zOffset = 1.0f / (CGFloat)[sprites count];
        
        // All nodes in the stack are direct children, with ordered zPosition.
        CGFloat ourZPosition = self.zPosition;
        NSUInteger childNumber = 0;
        for (SKNode *node in sprites) {
            node.zPosition = ourZPosition + (zOffset + (zOffset * childNumber));
            [self addChild:node];
            childNumber++;
        }
        
        _parallaxOffset = offset;
    }
    
    return self;
}

#pragma mark - Copying
- (id)copyWithZone:(NSZone *)zone {
    APAParallaxSprite *sprite = [super copyWithZone:zone];
    if (sprite) {
        sprite->_parallaxOffset = self.parallaxOffset;
        sprite->_usesParallaxEffect = self.usesParallaxEffect;
    }
    return sprite;
}

#pragma mark - Rotation and Offsets
- (void)setZRotation:(CGFloat)rotation {
    // Override to apply the zRotation just to the stack nodes, but only if the parallax effect is enabled.
    if (!self.usesParallaxEffect) {
        [super setZRotation:rotation];
        return;
    }
    
    if (rotation > 0.0f) {
        self.zRotation = 0.0f; // never rotate the group node
        
        // Instead, apply the desired rotation to each node in the stack.
        for (SKNode *child in self.children) {
            child.zRotation = rotation;
        }
        
        self.virtualZRotation = rotation;
    }
}

- (void)updateOffset {
    SKScene *scene = self.scene;
    SKNode *parent = self.parent;
    
    if (!self.usesParallaxEffect || parent == nil) {
        return;
    }
    
    CGPoint scenePos = [scene convertPoint:self.position fromNode:parent];
    
    // Calculate the offset directions relative to the center of the screen.
    // Bias to (-0.5, 0.5) range.
    CGFloat offsetX =  (-1.0f + (2.0 * (scenePos.x / scene.size.width)));
    CGFloat offsetY =  (-1.0f + (2.0 * (scenePos.y / scene.size.height)));
    
    CGFloat delta = self.parallaxOffset / (CGFloat)self.children.count;
    
    int childNumber = 0;
    for (SKNode *node in self.children) {
        node.position = CGPointMake(offsetX*delta*childNumber, offsetY*delta*childNumber);
        childNumber++;
    }
}

@end
