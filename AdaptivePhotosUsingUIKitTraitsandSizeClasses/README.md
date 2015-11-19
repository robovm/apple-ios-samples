# AdaptivePhotos: Using UIKit Traits and Size Classes

This sample demonstrates how to use UIKit APIs to make your app work great on all devices and any orientation. You'll see how to use size classes, traits, and view controller additions to create an app that displays properly at any size (including iPhone 6 Plus) and and configuration (including iPad Multitasking).

There are two versions of this project. One uses adaptive code to change its layout to match its environment, the other uses storyboards. 

- The AppDelegate class implements new UISplitViewController delegate methods for collapsing/expanding.
- The Main.storyboard file includes all of the storyboards, including different layouts when appropriate. 
- The RatingControl class uses images for different traits along with Auto Layout to automatically resize when changing to a Vertically Compact size class.
- The OverlayView class changes its intrinsic content size depending on its size class.
- The ListTableViewController class shows a list of contacts that will show either a single photo as a Detail view, or a conversation view on its navigation controller
- The ConversationViewController class shows a list of photos that can be shown as the Detail view
- The ProfileViewController class shows a profile and changes its layout based on its vertical size class.
- The UIViewController+PhotoContents extension adds support for determining what photos a view controller shows.
- The UIViewController+ViewControllerShowing extension adds support for determining whether calling showViewController(_:sender:) and showDetailViewController(_:sender:) will push.

For more information, see:
- Session 216 "Building Adaptive Apps with UIKit" from WWDC 2014 (https://developer.apple.com/videos/wwdc/2014/#216)
- Session 205 "Adopting Multitasking in iOS 9" from WWDC 2015

## Requirements

### Build

Xcode 7.0, iOS 9 SDK

### Runtime

iOS 9.0

CHANGES FROM PREVIOUS VERSIONS:
--------------------------------------------------------------------------------

+ Version 3.0
  - Converted to Swift.
  - Added support for iPad Multitasking.
  - Adopted Launch Storyboards.

+ Version 2.0
  - Updated for iPhone 6 Plus.
  - Added Storyboard version.
  - Added additional comments.

+ Version 1.0
  - First release.

================================================================================
Copyright (C) 2015 Apple Inc. All rights reserved.
