iAdSuite with Storyboards
=========================

iAdSuite is a set of samples demonstrating how to manage an ADBannerView in many common scenarios, each scenario demonstrated in a particular sample application.

BasicBanner
    This application demonstrates the basics of how you might add a banner view to an application that dynamically adapts to the presence of an advertisement, as well as showing how to respond in a simple way to the standard delegate methods.

ContainerBanner
    By using view controller containment, this sample abstracts the setup demonstrated in BasicBanner to a custom container view controller (BannerViewController). This view controller manages hiding and showing the banner view at the appropriate time, and resizing its contained view controller.

SplitNavigationBanner
    Using the approach demonstrated in ContainerBanner, this sample demonstrates adding an ADBannerView to an application that is based on UINavigationController (iPhone) or UISplitViewController (iPad). This sample replaces the NavigationBanner and SplitViewBanner samples.
    
TabbedBanner
    When using a UITabBarController, the banner should appear above the tabs. This sample again builds upon the approach from ContainerBanner, modifying BannerViewController to allow for the existence of multiple instances that share the same ADBannerView.

MediumRectBanner
    iOS 6 introduces a new banner size that is intended for use inline with your content. This sample demonstrates using the new MediumRect 300x250 sized banner in a simple image gallery type application.

In many of the samples the content is represented by a simple TextViewController view controller that displays some text in a read-only UITextView and runs a timer. The UITextView represents your application's content and the timer represents ongoing activity in your application that you will want to pause when the advertisement takes over the user interface. The MediumRectBanner sample uses a UICollectionView with image content instead, adding the banners as additional cells.

The traditional banner (represented with the ADAdTypeBanner constant) is expected to be placed at or near the bottom of the screen and placed to consume the full width of the screen. New in iOS 6 is the Medium Rect sized banner (represented with the ADAdTypeMediumRectangle constant) which is intended to be placed inline with other content from your application. It is highly recommended that you create only a single instance of each type of banner that you use (so if you use both a banner and medium rect type, you would have at most 1 instance of each) and that you share these instances among the places in your UI that they are used.

Build Requirements
iOS 7.0 SDK, Automated Reference Counting (ARC).

Runtime Requirements
iOS 6.0 or later

Changes from Previous Versions
1.2 - TabbedBanner no longer throws exception in viewDidLayoutSubviews (layoutSubviews required for auto layout).
1.1 - Upgraded for iOS 7 SDK, all projects now use Auto Layout, fixed TabbedBanner: now properly showing iAds for iOS 7.
1.0 - First release, adopted from the original iAdSuite sample code.

Copyright (C) 2010-2014 Apple Inc. All rights reserved.
