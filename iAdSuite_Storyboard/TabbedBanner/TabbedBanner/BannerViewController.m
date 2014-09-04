/*
     File: BannerViewController.m
 Abstract: A container view controller that manages an ADBannerView and a content view controller.
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

#import "BannerViewController.h"
#import <iAd/iAd.h>

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

- (NSUInteger)supportedInterfaceOrientations
{
    return [self.contentController supportedInterfaceOrientations];
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
