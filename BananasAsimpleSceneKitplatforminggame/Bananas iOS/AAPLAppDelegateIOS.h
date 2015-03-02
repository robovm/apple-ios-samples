/*
 Copyright (C) 2014 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 
  The iOS-specific implementation of the application delegate. See AAPLAppDelegate for implementation shared between platforms. Uses NSProgress to display a loading UI while the app loads its assets.
  
 */

#import "AAPLAppDelegate.h"
#import <UIKit/UIKit.h>

@interface AAPLAppDelegateIOS : AAPLAppDelegate <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

@end
