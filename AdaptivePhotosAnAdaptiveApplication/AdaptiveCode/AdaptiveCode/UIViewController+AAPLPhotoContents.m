/*
 Copyright (C) 2014 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 
  A category that returns information about photos contained in view controllers.
 */

#import "UIViewController+AAPLPhotoContents.h"

@implementation UIViewController (AAPLPhotoContents)

- (AAPLPhoto *)aapl_containedPhoto
{
    // By default, view controllers don't contain photos.
    return nil;
}

- (BOOL)aapl_containsPhoto:(AAPLPhoto *)photo
{
    // By default, view controllers don't contain photos.
    return NO;
}

- (AAPLPhoto *)aapl_currentVisibleDetailPhotoWithSender:(id)sender
{
    // Look for a view controller that has a visible photo.
    UIViewController *target = [self targetViewControllerForAction:@selector(aapl_currentVisibleDetailPhotoWithSender:) sender:sender];
    if (target) {
        return [target aapl_currentVisibleDetailPhotoWithSender:sender];
    } else {
        return nil;
    }
}

@end

@implementation UISplitViewController (AAPLPhotoContents)

- (AAPLPhoto *)aapl_currentVisibleDetailPhotoWithSender:(id)sender
{
    if (self.collapsed) {
        // If we're collapsed, we don't have a detail.
        return nil;
    } else {
        // Otherwise, return our detail controller's contained photo (if any).
        UIViewController *controller = [self.viewControllers lastObject];
        
        return [controller aapl_containedPhoto];
    }
}

@end
