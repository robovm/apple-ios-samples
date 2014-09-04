/*
     File: APLStackCollectionViewController.m
 Abstract: The UICollectionViewController containing the custom stack layout.
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

#import "APLStackCollectionViewController.h"
#import "APLGridCollectionViewController.h"
#import "APLTransitionLayout.h"


@implementation APLStackCollectionViewController

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    // NOTE: the following line of code is necessary to work around a bug in UICollectionView,
    // when you transition back to this view controller from a pinch inward gesture,
    // the z-ordering of the stacked photos may be wrong.
    //
    [self.collectionView reloadData];
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    // user tapped a stack of photos, navigate the grid layout view controller
    [self.navigationController pushViewController:[self nextViewControllerAtPoint:CGPointZero] animated:YES];
}

// obtain the next collection view controller based on where the user tapped in case there are multiple stacks
- (UICollectionViewController *)nextViewControllerAtPoint:(CGPoint)p
{
    // we could have multiple section stacks, so we need to find the right one
    UICollectionViewFlowLayout *grid = [[UICollectionViewFlowLayout alloc] init];
    grid.itemSize = CGSizeMake(75.0, 75.0);
    grid.sectionInset = UIEdgeInsetsMake(10.0, 10.0, 10.0, 10.0);
    
    APLGridCollectionViewController *nextCollectionViewController =
        [[APLGridCollectionViewController alloc] initWithCollectionViewLayout:grid];
    
    // Set "useLayoutToLayoutNavigationTransitions" to YES before pushing a a
    // UICollectionViewController onto a UINavigationController. The top view controller of
    // the navigation controller must be a UICollectionViewController that was pushed with
    // this property set to NO. This property should NOT be changed on a UICollectionViewController
    // that has already been pushed onto a UINavigationController.
    //
    nextCollectionViewController.useLayoutToLayoutNavigationTransitions = YES;
    
    nextCollectionViewController.title = @"Grid Layout";
    
    return nextCollectionViewController;
}

@end

