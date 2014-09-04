PageControl

This application primarily demonstrates use of UIScrollView's paging functionality to use horizontal scrolling as a mechanism for navigating between different pages of content.  With the iPad, this type of user interface is not really necessary since the screen is larger allowing for more content and detailed information.

Designed as a universal application for both iPhone and iPad, this sample shows how to use two different sets of content, depending on which device the sample is running.  The idea is that the iPhone uses a "smaller" set of images, while the iPad uses a "larger" set of images plus more detailed information. ÊAs a universal app this sample shows how to factor out these two types of UI and data based on the device.Ê

For the iPhone - The app uses UIScrollView and UIPageControl to move between pages.
For the iPad - The app uses one large UIView with tiled pages, each page presenting a popover to display more detailed information.

Based on the UIDevice idiom type, the UIApplication delegate loads two different set of nib files, one for the iPhone and the other for the iPad.  ÊTo direct this kind of UI factoring, the sample uses a base class called "ContentController".  Subclasses of ContentController are used to support each device.  Hence, the app loads two different user interfaces (or xibs) as well as two different sets of data driven by the ContentController.

Build Requirements
iOS SDK 7.0 and later

Runtime Requirements
iOS 7.0 and later

Changes from Previous Versions
1.6 - Upgraded for iOS 7 SDK, now uses Autolayout, replaced deprecated APIs, now uses ImageAssets.
1.5 - Upgraded to use iOS 6.0 SDK, UIWindow now uses rootViewController, now uses Automatic Reference Counting (ARC), updated to adopt current best practices for Objective-C.
1.4 - Updated as a universal application for iPhone and iPad.
1.3 - Upgraded project to build with the iOS 4.0 SDK.
1.2 - Fixed issue where scrolling by dragging the UIScrollView did not update the UIPageControl.
1.1 - Added a check to eliminate flicker of the UIPageControl when it is used to change pages.
1.0 - Initial version.

Copyright (C) 2010-2014 Apple Inc. All rights reserved.
