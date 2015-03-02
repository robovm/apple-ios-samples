/*
 Copyright (C) 2014 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 
  AAPLOverlayAnimatedTransitioning and AAPLOverlayTransitioningDelegate interfaces.
  
 */

@import UIKit;

@interface AAPLOverlayAnimatedTransitioning : NSObject <UIViewControllerAnimatedTransitioning>
@property (nonatomic) BOOL isPresentation;
@end

@interface AAPLOverlayTransitioningDelegate : NSObject <UIViewControllerTransitioningDelegate>
@end