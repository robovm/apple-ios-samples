/*
 Copyright (C) 2016 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 The transition delegate for the Swipe demo.  Vends instances of 
  AAPLSwipeTransitionAnimator and optionally 
  AAPLSwipeTransitionInteractionController.
 */

@import UIKit;

@interface AAPLSwipeTransitionDelegate : NSObject <UIViewControllerTransitioningDelegate>

//! If this transition will be interactive, this property is set to the
//! gesture recognizer which will drive the interactivity.
@property (nonatomic, strong) UIScreenEdgePanGestureRecognizer *gestureRecognizer;

@property (nonatomic, readwrite) UIRectEdge targetEdge;

@end
