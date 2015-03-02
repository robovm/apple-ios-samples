/*
 Copyright (C) 2014 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 
  A category that returns information about photos contained in view controllers.
 */

@import UIKit;
@class AAPLPhoto;

// This category is specific to this application. Some of the specific view controllers in the app override these to return the values that make sense for them.

@interface UIViewController (AAPLPhotoContents)

// Returns the photo currently being displayed by the receiver, or nil if the receiver is not displaying a photo.
- (AAPLPhoto *)aapl_containedPhoto;

- (BOOL)aapl_containsPhoto:(AAPLPhoto *)photo;
- (AAPLPhoto *)aapl_currentVisibleDetailPhotoWithSender:(id)sender;

@end
