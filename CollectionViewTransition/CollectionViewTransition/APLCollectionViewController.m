/*
     File: APLCollectionViewController.m
 Abstract: Base UICollectionViewController containing the basic functionality for collection views.
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

#import "APLCollectionViewController.h"
#import "APLTransitionLayout.h"
#import "APLCollectionViewCell.h"

#define USE_IMAGES   1  // if 1 images are used for each cell, if 0 we use varying UIColors swatches for each cell

#define MAX_COUNT    24
#define CELL_ID      @"CELL_ID"


#pragma mark -

@implementation APLCollectionViewController

- (id)initWithCollectionViewLayout:(UICollectionViewFlowLayout *)layout
{
    if (self = [super initWithCollectionViewLayout:layout])
    {
        // make sure we know about our cell prototype so dequeueReusableCellWithReuseIdentifier can work
        [self.collectionView registerClass:[APLCollectionViewCell class] forCellWithReuseIdentifier:CELL_ID];
    }
    return self;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    APLCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:CELL_ID forIndexPath:indexPath];
    
#if USE_IMAGES
    // set the cell to use an image
    cell.imageView.image = [UIImage imageNamed:[NSString stringWithFormat:@"sa%ld.jpg", (long)indexPath.item]];
#else
    // set the cell to use a color swatch
    CGFloat hue = ((CGFloat)indexPath.item)/MAX_COUNT;
    UIColor *cellColor = [UIColor colorWithHue:hue saturation:1.0 brightness:1.0 alpha:1.0];
    cell.contentView.backgroundColor = cellColor;
#endif
    
    return cell;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return MAX_COUNT;
}

- (UICollectionViewController *)nextViewControllerAtPoint:(CGPoint)p
{
    return nil; // subclass must override this method
}

// return our own UICollectionViewTransitionLayout object subclass to help in the transition
// the cell positions based on gesture position
//
- (UICollectionViewTransitionLayout *)collectionView:(UICollectionView *)collectionView transitionLayoutForOldLayout:(UICollectionViewLayout *)fromLayout newLayout:(UICollectionViewLayout *)toLayout
{
    APLTransitionLayout *myCustomTransitionLayout =
        [[APLTransitionLayout alloc] initWithCurrentLayout:fromLayout nextLayout:toLayout];
    return myCustomTransitionLayout;
}

@end
