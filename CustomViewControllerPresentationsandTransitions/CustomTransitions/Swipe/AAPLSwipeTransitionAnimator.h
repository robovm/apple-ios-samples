/*
 Copyright (C) 2016 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 A transition animator that slides the incoming view controller over the
  presenting view controller.
 */

@import UIKit;

@interface AAPLSwipeTransitionAnimator : NSObject <UIViewControllerAnimatedTransitioning>

- (instancetype)initWithTargetEdge:(UIRectEdge)targetEdge;

@property (nonatomic, readwrite) UIRectEdge targetEdge;

@end
