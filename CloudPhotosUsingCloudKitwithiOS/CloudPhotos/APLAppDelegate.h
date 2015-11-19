/*
 Copyright (C) 2015 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 UIApplicationDelegate for this sample
 */

@import UIKit;

@class APLCloudManager;

// handy macro to access APLAppDelegate's APLCloudManager object
#define CloudManager [(APLAppDelegate *)[[UIApplication sharedApplication] delegate] cloudManager]

@interface APLAppDelegate : NSObject <UIApplicationDelegate>

@property (nonatomic, strong) APLCloudManager *cloudManager;

@end
