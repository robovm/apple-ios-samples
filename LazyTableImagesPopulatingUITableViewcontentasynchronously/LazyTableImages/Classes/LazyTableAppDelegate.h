/*
 Copyright (C) 2015 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 Application delegate for the LazyTableImages sample.
  It also downloads in the background the "Top Paid iPhone Apps" RSS feed using NSURLSession/NSURLSessionDataTask.
 */

@import UIKit;

@interface LazyTableAppDelegate : UIResponder <UIApplicationDelegate>

@property (nonatomic, strong) UIWindow *window;

@end

