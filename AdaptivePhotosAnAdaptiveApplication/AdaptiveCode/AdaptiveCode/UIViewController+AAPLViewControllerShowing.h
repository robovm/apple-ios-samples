/*
 Copyright (C) 2014 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 
  A category that gives information about how view controllers will be shown, for determining disclosure indicator visibility and row deselection.
 */

@import UIKit;

@interface UIViewController (AAPLViewControllerShowing)

// Returns whether calling showViewController:sender: would cause a navigation "push" to occur.
- (BOOL)aapl_willShowingViewControllerPushWithSender:(id)sender;

// Returns whether calling showDetailViewController:sender: would cause a navigation "push" to occur.
- (BOOL)aapl_willShowingDetailViewControllerPushWithSender:(id)sender;

@end
