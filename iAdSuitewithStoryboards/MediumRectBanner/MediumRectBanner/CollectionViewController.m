/*
Copyright (C) 2015 Apple Inc. All Rights Reserved.
See LICENSE.txt for this sample’s licensing information

Abstract:
A simple view controller that manages a collection view controller and a medium rect ADBannerView.
*/

@import iAd;

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
        self.imageView.contentMode = UIViewContentModeScaleAspectFit;
        [self.contentView addSubview:self.imageView];
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

@property (nonatomic, strong) ADBannerView *banner;
// We only want to insert/delete our banner if we are changing from Loaded to Non-loaded
// and vice versa, so we use this ivar to track that state. If this wasn't a concern,
// we wouldn't need this ivar at all.
//
@property (nonatomic, assign) BOOL bannerWasLoaded;

@end


#pragma mark -

@implementation CollectionViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    _banner = [[ADBannerView alloc] initWithAdType:ADAdTypeMediumRectangle];
    self.banner.delegate = self;
    [self.collectionView registerClass:[ImageViewCell class] forCellWithReuseIdentifier:@"ImageView"];
    [self.collectionView registerClass:[BannerViewCell class] forCellWithReuseIdentifier:@"BannerView"];
}


#pragma mark - UICollectionViewDataSource

#define kBaseNumberOfItems 30
#define kNumberOfItemsWithBanners 33

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    // We only have 1 banner, but we display it in one of 3 locations, so if the banner is loaded, we add 3 more items.
    return self.banner.bannerLoaded ? kNumberOfItemsWithBanners : kBaseNumberOfItems;
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
    if (self.banner.bannerLoaded && [self isBannerItem:indexPath]) {
        BannerViewCell *bannerCell = [collectionView dequeueReusableCellWithReuseIdentifier:@"BannerView" forIndexPath:indexPath];
        bannerCell.bannerView = self.banner;
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
    if (!self.bannerWasLoaded) {
        [self.collectionView performBatchUpdates:^{
            [self.collectionView insertItemsAtIndexPaths:@[ [NSIndexPath indexPathForItem:kBannerLocation1 inSection:0], [NSIndexPath indexPathForItem:kBannerLocation2 inSection:0], [NSIndexPath indexPathForItem:kBannerLocation3 inSection:0]]];
        } completion:nil];
    }
    self.bannerWasLoaded = YES;
}

- (void)bannerView:(ADBannerView *)banner didFailToReceiveAdWithError:(NSError *)error
{
    if (self.bannerWasLoaded) {
        [self.collectionView performBatchUpdates:^{
            [self.collectionView deleteItemsAtIndexPaths:@[ [NSIndexPath indexPathForItem:kBannerLocation1 inSection:0], [NSIndexPath indexPathForItem:kBannerLocation2 inSection:0], [NSIndexPath indexPathForItem:kBannerLocation3 inSection:0]]];
        } completion:nil];
        
        NSLog(@"didFailToReceiveAdWithError: %@", error);
    }
    self.bannerWasLoaded = NO;
}

@end
