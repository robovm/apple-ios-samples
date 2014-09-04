/*
     File: APLTransitionLayout.m
 Abstract: Helps in the transition the of cell positions based on the pinch gesture position.
 
  Version: 1.1
 
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

#import "APLTransitionLayout.h"

static NSString *kOffsetH = @"offsetH";
static NSString *kOffsetV = @"offsetV";

@implementation APLTransitionLayout

// set the completion progress of the current transition.
//
- (void)setTransitionProgress:(CGFloat)transitionProgress
{
    [super setTransitionProgress:transitionProgress];    
    
    // return the most recently set values for each key
    CGFloat offsetH = [self valueForAnimatedKey:kOffsetH];
    CGFloat offsetV = [self valueForAnimatedKey:kOffsetV];
    _offset = UIOffsetMake(offsetH, offsetV);
}

// called by the APLTransitionManager class while updating its transition progress, animating
// the collection view items in an out of stack mode.
//
- (void)setOffset:(UIOffset)offset
{
    // store the floating-point values with out meaningful keys for our transition layout object
    [self updateValue:offset.horizontal forAnimatedKey:kOffsetH];
    [self updateValue:offset.vertical forAnimatedKey:kOffsetV];
    _offset = offset;
}

// return the layout attributes for all of the cells and views in the specified rectangle
- (NSArray *)layoutAttributesForElementsInRect:(CGRect)rect
{
    NSArray *attributes = [super layoutAttributesForElementsInRect:rect];
    
    for (UICollectionViewLayoutAttributes *currentAttribute in attributes)
    {
        CGPoint currentCenter = currentAttribute.center;
        CGPoint updatedCenter = CGPointMake(currentCenter.x + self.offset.horizontal, currentCenter.y + self.offset.vertical);
        currentAttribute.center = updatedCenter;
    }
    return attributes;
}

- (UICollectionViewLayoutAttributes *)layoutAttributesForItemAtIndexPath:(NSIndexPath *)indexPath
{
    // returns the layout attributes for the item at the specified index path
    UICollectionViewLayoutAttributes *attributes = [super layoutAttributesForItemAtIndexPath:indexPath];
    CGPoint currentCenter = attributes.center;
    CGPoint updatedCenter = CGPointMake(currentCenter.x + self.offset.horizontal, currentCenter.y + self.offset.vertical);
    attributes.center = updatedCenter;
    return attributes;
}

@end
