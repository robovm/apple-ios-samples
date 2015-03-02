/*
 Copyright (C) 2014 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 
  AAPLRootViewController header.
  
 */

@import UIKit;

@interface AAPLRootViewController : UICollectionViewController

- (BOOL)presentationShouldBeAwesome;

@property (nonatomic) UISwitch *coolSwitch;
@property (nonatomic) id<UIViewControllerTransitioningDelegate> transitioningDelegate;

@end
