/*
 Copyright (C) 2014 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 
  A category that gives information about how view controllers will be shown, for determining disclosure indicator visibility and row deselection.
 */

#import "UIViewController+AAPLViewControllerShowing.h"

@implementation UIViewController (AAPLViewControllerShowing)

- (BOOL)aapl_willShowingViewControllerPushWithSender:(id)sender
{
    // Find and ask the right view controller about showing.
    UIViewController *target = [self targetViewControllerForAction:@selector(aapl_willShowingViewControllerPushWithSender:) sender:sender];
    if (target) {
        return [target aapl_willShowingViewControllerPushWithSender:sender];
    } else {
        // Or if we can't find one, we won't be pushing.
        return NO;
    }
}

- (BOOL)aapl_willShowingDetailViewControllerPushWithSender:(id)sender
{
    // Find and ask the right view controller about showing detail.
    UIViewController *target = [self targetViewControllerForAction:@selector(aapl_willShowingDetailViewControllerPushWithSender:) sender:sender];
    if (target) {
        return [target aapl_willShowingDetailViewControllerPushWithSender:sender];
    } else {
        // Or if we can't find one, we won't be pushing.
        return NO;
    }
}

@end

@implementation UINavigationController (AAPLViewControllerShowing)

- (BOOL)aapl_willShowingViewControllerPushWithSender:(id)sender
{
    // Navigation Controllers always push for showViewController:.
    return YES;
}

@end

@implementation UISplitViewController (AAPLViewControllerShowing)

- (BOOL)aapl_willShowingViewControllerPushWithSender:(id)sender
{
    // Split View Controllers never push for showViewController:.
    return NO;
}

- (BOOL)aapl_willShowingDetailViewControllerPushWithSender:(id)sender
{
    if (self.collapsed) {
        // If we're collapsed, re-ask this question as showViewController: to our primary view controller.
        UIViewController *target = [self.viewControllers lastObject];
        return [target aapl_willShowingViewControllerPushWithSender:sender];
    } else {
        // Otherwise, we don't push for showDetailViewController:.
        return NO;
    }
}

@end
