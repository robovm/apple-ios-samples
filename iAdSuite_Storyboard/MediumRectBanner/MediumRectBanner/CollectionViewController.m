/*
     File: CollectionViewController.m
 Abstract: A simple view controller that manages a collection view controller and a medium rect ADBannerView.
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
 
 Copyright (C) 2014 Apple Inc. All Rights Reserved.
 
 */

#import <iAd/iAd.h>
#import "CollectionViewController.h"

@interface ImageViewCell : UICollectionViewCell

@property (nonatomic, readonly) UIImageView *imageView;

@end


#pragma mark -

@implementation ImageViewCell

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self != nil) {
        _imageView = [[UIImageView alloc] initWithFrame:self.contentView.bounds];
        _imageView.contentMode = UIViewContentModeScaleAspectFit;
        [self.contentView addSubview:_imageView];
    }
    return self;
}

@end


#pragma mark -

@interface BannerViewCell : UICollectionViewCell

@property (nonatomic, retain) ADBannerView *bannerView;

@end


#pragma mark -

@implementation BannerViewCell

- (void)setBannerView:(ADBannerView *)bannerView
{
    [_bannerView removeFromSuperview];
    _bannerView = bannerView;
    [self.contentView addSubview:_bannerView];
    _bannerView.center = CGPointMake(CGRectGetMidX(self.contentView.bounds), CGRectGetMidY(self.contentView.bounds));
}

@end


#pragma mark -

@interface CollectionViewController () <ADBannerViewDelegate>

@end


#pragma mark -

@implementation CollectionViewController
{
    ADBannerView *_banner;
    // We only want to insert/delete our banner if we are changing from Loaded to Non-loaded
    // and vice versa, so we use this ivar to track that state. If this wasn't a concern,
    // we wouldn't need this ivar at all.
    //
    BOOL _bannerWasLoaded;
}

- (void)viewDidLoad
{
    _banner = [[ADBannerView alloc] initWithAdType:ADAdTypeMediumRectangle];
    _banner.delegate = self;
    [self.collectionView registerClass:[ImageViewCell class] forCellWithReuseIdentifier:@"ImageView"];
    [self.collectionView registerClass:[BannerViewCell class] forCellWithReuseIdentifier:@"BannerView"];
}


#pragma mark - UICollectionViewDataSource

#define kBaseNumberOfItems 30
#define kNumberOfItemsWithBanners 33

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    // We only have 1 banner, but we display it in one of 3 locations, so if the banner is loaded, we add 3 more items.
    return _banner.bannerLoaded ? kNumberOfItemsWithBanners : kBaseNumberOfItems;
}

- (UIImage *)makeArt:(NSInteger)index
{
    static UIImage *art[kBaseNumberOfItems];
    if (art[index] == nil) {
        UIGraphicsBeginImageContextWithOptions(CGSizeMake(300.0, 300.0), YES, 0.0);
        CGContextRef context = UIGraphicsGetCurrentContext();
        [[UIColor redColor] setFill];
        [[UIColor blueColor] setStroke];
        CGPoint center = CGPointMake(150.0, 150.0);
        CGContextMoveToPoint(context, center.x, center.y + 120.0);
        NSInteger numPoints = index * 2 + 3;
        for(int i = 1; i < numPoints; ++i)
        {
            CGFloat x = 120.0 * sinf(i * (numPoints - 1) * M_PI / numPoints);
            CGFloat y = 120.0 * cosf(i * (numPoints - 1) * M_PI / numPoints);
            CGContextAddLineToPoint(context, center.x + x, center.y + y);
        }
        CGContextClosePath(context);
        CGContextDrawPath(context, kCGPathEOFillStroke);
        art[index] = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
    }
    return art[index];
}

#define kBannerLocation1 5
#define kBannerLocation2 16
#define kBannerLocation3 27

- (BOOL)isBannerItem:(NSIndexPath *)indexPath
{
    return (indexPath.item == kBannerLocation1) || (indexPath.item == kBannerLocation2) || (indexPath.item == kBannerLocation3);
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    UICollectionViewCell *cell;
    if (_banner.bannerLoaded && [self isBannerItem:indexPath]) {
        BannerViewCell *bannerCell = [collectionView dequeueReusableCellWithReuseIdentifier:@"BannerView" forIndexPath:indexPath];
        bannerCell.bannerView = _banner;
        cell = bannerCell;
    } else {
        ImageViewCell *imageCell = [collectionView dequeueReusableCellWithReuseIdentifier:@"ImageView" forIndexPath:indexPath];
        NSInteger index = indexPath.item;
        if (index > kBannerLocation3) {
            index -= 3;
        } else if (index > kBannerLocation2) {
            index -= 2;
        } else if (index > kBannerLocation1) {
            index -= 1;
        }
        imageCell.imageView.image = [self makeArt:index];
        cell = imageCell;
    }
    return cell;
}


#pragma mark - ADBannerViewDelegate

- (void)bannerViewDidLoadAd:(ADBannerView *)banner
{
    if (!_bannerWasLoaded) {
        [self.collectionView performBatchUpdates:^{
            [self.collectionView insertItemsAtIndexPaths:@[ [NSIndexPath indexPathForItem:kBannerLocation1 inSection:0], [NSIndexPath indexPathForItem:kBannerLocation2 inSection:0], [NSIndexPath indexPathForItem:kBannerLocation3 inSection:0]]];
        } completion:nil];
    }
    _bannerWasLoaded = YES;
}

- (void)bannerView:(ADBannerView *)banner didFailToReceiveAdWithError:(NSError *)error
{
    if (_bannerWasLoaded) {
        [self.collectionView performBatchUpdates:^{
            [self.collectionView deleteItemsAtIndexPaths:@[ [NSIndexPath indexPathForItem:kBannerLocation1 inSection:0], [NSIndexPath indexPathForItem:kBannerLocation2 inSection:0], [NSIndexPath indexPathForItem:kBannerLocation3 inSection:0]]];
        } completion:nil];
        
        NSLog(@"didFailToReceiveAdWithError: %@", error);
    }
    _bannerWasLoaded = NO;
}

@end
