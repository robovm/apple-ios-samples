/*
     File: APLStackLayout.m
 Abstract: Custon collection view layout to stack collection view cells.
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

#import "APLStackLayout.h"

@interface APLStackLayout ()

@property (nonatomic, readwrite) NSInteger stackCount;
@property (nonatomic, readwrite) CGSize itemSize;
@property (nonatomic, readwrite) NSMutableArray *angles;
@property (nonatomic, readwrite) NSMutableArray *attributesArray;

@end

#pragma mark -

@implementation APLStackLayout

- (id)init
{
    self = [super init];
    if (self != nil)
    {
        _stackCount = 5;
        _itemSize = CGSizeMake(150.0, 200.0);
        _angles = [[NSMutableArray alloc] initWithCapacity:self.stackCount * 10];
    }
    return self;
}

- (void)prepareLayout
{
    // Compute the angles for each photo in the stack layout
    //
    // Keep in mind we only display one section in this layout.
    //
    // We use rand() to generate the varying angles, but with always the same seed value
    // so we have consistent angles when calling this method.
    //
    srand(42);
    
    CGSize size = self.collectionView.bounds.size;
    CGPoint center = CGPointMake(size.width / 2.0, size.height / 2.0);

    // we only display one section in this layout
    NSInteger itemCount = [self.collectionView numberOfItemsInSection:0];

    // remove all the old attributes
    [self.angles removeAllObjects];

    CGFloat maxAngle = M_1_PI / 3.0;
    CGFloat minAngle = - M_1_PI / 3.0;
    CGFloat diff = maxAngle - minAngle;

    // compute and add the necessary angles for each photo
    [_angles addObject:@0.0];
    for (NSInteger i = 1; i < self.stackCount * 10; i++)
    {
        CGFloat currentAngle = ((((CGFloat)rand()) / RAND_MAX) * diff) + minAngle;
        [self.angles addObject:[NSNumber numberWithFloat:currentAngle]];
    }

    if (self.attributesArray == nil)
    {
        _attributesArray = [[NSMutableArray alloc] initWithCapacity:itemCount];
    }
    // generate the new attributes array for each photo in the stack
    for (NSInteger i = 0; i < itemCount; i++)
    {
        NSInteger angleIndex = i % (self.stackCount * 10);

        NSNumber *angleNumber = self.angles[angleIndex];
        
        CGFloat angle = angleNumber.floatValue;

        UICollectionViewLayoutAttributes *attributes =
            [UICollectionViewLayoutAttributes layoutAttributesForCellWithIndexPath:[NSIndexPath indexPathForItem:i inSection:0]];
        attributes.size = self.itemSize;
        attributes.center = center;
        attributes.transform = CGAffineTransformMakeRotation(angle);

        if (i > self.stackCount)
        {
            attributes.alpha = 0.0;
        }
        else
        {
            attributes.alpha = 1.0;
        }
        attributes.zIndex = (itemCount - i);

        [self.attributesArray addObject:attributes];
    }
}

- (void)invalidateLayout
{
    [super invalidateLayout];
    _attributesArray = nil;
}

- (BOOL)shouldInvalidateLayoutForBoundsChange:(CGRect)newBounds
{
    CGRect bounds = self.collectionView.bounds;
    return ((CGRectGetWidth(newBounds) != CGRectGetWidth(bounds) ||
            (CGRectGetHeight(newBounds) != CGRectGetHeight(bounds))));
}

- (CGSize)collectionViewContentSize
{
    return self.collectionView.bounds.size;
}

- (UICollectionViewLayoutAttributes *)layoutAttributesForItemAtIndexPath:(NSIndexPath *)indexPath
{
    return self.attributesArray[indexPath.item];
}

- (NSArray *)layoutAttributesForElementsInRect:(CGRect)rect
{
    return self.attributesArray;
}

@end
