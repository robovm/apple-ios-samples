/*
 Copyright (C) 2014 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 
  The sample's application delegate.
  
 */

#import <UIKit/UIKit.h>

@class AAPLDataSource;

@interface AAPLAppDelegate : UIResponder <UIApplicationDelegate>

@property (nonatomic, strong) UIWindow *window;
@property (nonatomic, readonly) AAPLDataSource *dataSource;

@end
