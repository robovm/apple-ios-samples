/*
 Copyright (C) 2015 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 The view controller template describing each page in our magazine.
 */

#import "DataViewController.h"
@import iAd;

#define AUTOMATIC_AD_POLICY 1

@interface DataViewController ()

@property (strong, nonatomic) IBOutlet UIImageView *imageView;

@end


#pragma mark -

@implementation DataViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
 
#if AUTOMATIC_AD_POLICY
    self.interstitialPresentationPolicy = ADInterstitialPresentationPolicyAutomatic;
#else
    self.interstitialPresentationPolicy = ADInterstitialPresentationPolicyManual;
    // since we have a manual policy, we later need to call
#endif
}

- (BOOL)shouldPresentInterstitialAd
{
    return YES;
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

    if (self.presentingFullScreenAd)
    {
        NSLog(@"Interstitial was dismissed.");
    }
    else
    {
#if !AUTOMATIC_AD_POLICY
        // display an interstitial ad 5 seconds from now
        [NSTimer scheduledTimerWithTimeInterval:5.0
                                         target:self
                                       selector:@selector(handleAdTimer:)
                                       userInfo:nil
                                        repeats:NO];
#endif
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    if ([self.dataObject isKindOfClass:[NSString class]])
    {
        self.imageView.image = [UIImage imageNamed:self.dataObject];
    }
}

- (void)handleAdTimer:(NSTimer *)timer
{
    [self requestInterstitialAdPresentation];
}

@end
