/*
 Copyright (C) 2014 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 
  The primary collection view controller for this app.
  
 */

#import <UIKit/UIKit.h>

@class AAPLDataSource;

@interface AAPLViewController : UICollectionViewController

@property (nonatomic, strong) AAPLDataSource *dataSource;

// these are used by the AppDelegate
- (BOOL)handleUserActivity:(NSUserActivity *)userActivity;
- (void)prepareForActivity;
- (void)handleActivityFailure;

@end
