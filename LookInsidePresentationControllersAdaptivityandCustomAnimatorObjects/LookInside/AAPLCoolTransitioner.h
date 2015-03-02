/*
 Copyright (C) 2014 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 
  AAPLCoolAnimatedTransitioning and AAPLCoolTransitioningDelegate interfaces.
  
 */

@import UIKit;

@interface AAPLCoolAnimatedTransitioning : NSObject <UIViewControllerAnimatedTransitioning>
@property (nonatomic) BOOL isPresentation;
@end

@interface AAPLCoolTransitioningDelegate : NSObject <UIViewControllerTransitioningDelegate>
@end