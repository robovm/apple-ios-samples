/*
Copyright (C) 2015 Apple Inc. All Rights Reserved.
See LICENSE.txt for this sample’s licensing information

Abstract:
A container view controller that manages an ADBannerView and a content view controller.
*/

@import iAd;

#import "BannerViewController.h"

NSString * const BannerViewActionWillBegin = @"BannerViewActionWillBegin";
NSString * const BannerViewActionDidFinish = @"BannerViewActionDidFinish";


@interface BannerViewManager : NSObject <ADBannerViewDelegate>

@property (nonatomic, readonly) ADBannerView *bannerView;

+ (BannerViewManager *)sharedInstance;

- (void)addBannerViewController:(BannerViewController *)controller;
- (void)removeBannerViewController:(BannerViewController *)controller;

@end


#pragma mark -

@interface BannerViewController ()
@property (nonatomic, strong) UIViewController *contentController;
@end


#pragma mark -

@implementation BannerViewController

- (void)dealloc
{
    [[BannerViewManager sharedInstance] removeBannerViewController:self];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [[BannerViewManager sharedInstance] addBannerViewController:self];
    
    NSArray *children = self.childViewControllers;
    assert(children != nil);    // must have children
    
    // keep track of our child view controller for rotation and frame management
    _contentController = children[0];
}

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation
{
    return [self.contentController preferredInterfaceOrientationForPresentation];
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    
    CGRect contentFrame = self.view.bounds, bannerFrame = CGRectZero;
    ADBannerView *bannerView = [BannerViewManager sharedInstance].bannerView;

    // If configured to support iOS >= 6.0 only, then we want to avoid
    // currentContentSizeIdentifier as it is deprecated.
    // Fortunately all we need to do is ask the banner for a size that fits into the layout
    // area we are using. At this point in this method contentFrame=self.view.bounds,
    // so we'll use that size for the layout.
    //
    bannerFrame.size = [bannerView sizeThatFits:contentFrame.size];
    
    if (bannerView.bannerLoaded) {
        contentFrame.size.height -= bannerFrame.size.height;
        bannerFrame.origin.y = contentFrame.size.height;
    } else {
        bannerFrame.origin.y = contentFrame.size.height;
    }
    self.contentController.view.frame = contentFrame;
    
    // We only want to modify the banner view itself if this view controller is actually
    // visible to the user. This prevents us from modifying it while it is being displayed elsewhere.
    //
    if (self.isViewLoaded && (self.view.window != nil)) {
        [self.view addSubview:bannerView];
        bannerView.frame = bannerFrame;
        [self.view layoutSubviews]; // required by auto layout
    }
}

- (void)updateLayout
{
    [UIView animateWithDuration:0.25 animations:^{
        // viewDidLayoutSubviews will handle positioning the banner view so that it is visible.
        // You must not call [self.view layoutSubviews] directly.  However, you can flag the view
        // as requiring layout...
        [self.view setNeedsLayout];
        // ... then ask it to lay itself out immediately if it is flagged as requiring layout...
        [self.view layoutIfNeeded];
        // ... which has the same effect.
    }];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.view addSubview:[BannerViewManager sharedInstance].bannerView];
}

- (NSString *)title
{
    return self.contentController.title;
}

@end


#pragma mark -

@implementation BannerViewManager {
    ADBannerView *_bannerView;
    NSMutableSet *_bannerViewControllers;
}

+ (BannerViewManager *)sharedInstance
{
    static BannerViewManager *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[BannerViewManager alloc] init];
    });
    return sharedInstance;
}

- (instancetype)init
{
    self = [super init];
    if (self != nil) {
        // On iOS 6 ADBannerView introduces a new initializer, use it when available.
        if ([ADBannerView instancesRespondToSelector:@selector(initWithAdType:)]) {
            _bannerView = [[ADBannerView alloc] initWithAdType:ADAdTypeBanner];
        } else {
            _bannerView = [[ADBannerView alloc] init];
        }
        _bannerView.delegate = self;
        _bannerViewControllers = [[NSMutableSet alloc] init];
    }
    return self;
}

- (void)addBannerViewController:(BannerViewController *)controller
{
    [_bannerViewControllers addObject:controller];
}

- (void)removeBannerViewController:(BannerViewController *)controller
{
    [_bannerViewControllers removeObject:controller];
}

- (void)bannerViewDidLoadAd:(ADBannerView *)banner
{
    NSLog(@"bannerViewDidLoadAd");
    
    for (BannerViewController *bvc in _bannerViewControllers) {
        [bvc updateLayout];
    }
}

- (void)bannerView:(ADBannerView *)banner didFailToReceiveAdWithError:(NSError *)error
{
    NSLog(@"didFailToReceiveAdWithError %@", error);
    
    for (BannerViewController *bvc in _bannerViewControllers) {
        [bvc updateLayout];
    }
}

- (BOOL)bannerViewActionShouldBegin:(ADBannerView *)banner willLeaveApplication:(BOOL)willLeave
{
    [[NSNotificationCenter defaultCenter] postNotificationName:BannerViewActionWillBegin object:self];
    return YES;
}

- (void)bannerViewActionDidFinish:(ADBannerView *)banner
{
    [[NSNotificationCenter defaultCenter] postNotificationName:BannerViewActionDidFinish object:self];
}

@end
