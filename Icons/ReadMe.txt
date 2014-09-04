Application Icons and Launch Images for iOS

================================================================================
ABSTRACT:

This sample, previously named Icons, demonstrates the proper use of application icons and launch images on iOS.

ICONS:
Every app is required to have an app icon. In addition, it is recommended that apps also provide icons for additional areas outside of the app including: Homescreen, Spotlight, the Settings app, and when creating an Ad Hoc build and adding it to iTunes.  See QA1686: App Icons on iPad and iPhone, for a complete listing of icons required for iPhone, iPad, and Universal apps <https://developer.apple.com/library/ios/qa/qa1686/_index.html>.


LAUNCH IMAGES:
The launch image is displayed while your app starts up, before the first view has loaded.  Every app must included at least one launch image.  If your app is an iPhone or Universal app, it must included a launch image specifically for devices with 4" screens (iPhone 5, iPhone 5s, iPod Touch 5).  In addition, it is recommended that apps also provide launch images for all applicable launch conditions.  See the App Launch (Default) Images chapter in the iOS App Programming Guide for further discussion <https://developer.apple.com/library/ios/documentation/iPhone/Conceptual/iPhoneOSProgrammingGuide/App-RelatedResources/App-RelatedResources.html#//apple_ref/doc/uid/TP40007072-CH6-SW12>.

Note: The iOS 7 specific launch images in this sample use the following convention, Default-iOS7-<usage_specific_modifiers><scale_modifier><device_modifier>.png.  This convention is completely arbitrary, you may give any name to your iOS 7 specific launch images.  However, all of your app's iOS 7 specific launch images must be listed under the UILaunchImages key in your app's information property list.  If you configure your launch images using the Launch Images UI in the project editor, the necessary changes to the information property list will be applied automatically.  Launch images for iOS 6, or launch images that will be shared between iOS 6 and iOS 7 must continue to name their launch images according to the legacy convention which may be found in the iOS App Programming Guide.


This sample is a universal binary that supports iPhone/iPod touch/iPad and includes support for high resolution displays.  It includes two targets, Icons, and IconsWithAssetCataogs.  Icons demonstrates the older method for configuring icons, including the images as resources and adding the CFBundleIconFiles key to its Info.plist.  IconsWithAssetCataogs, as the name implies, uses asset catalogs to store the icons and launch images.  Developers are encouraged to migrate their apps to use asset catalogs.

================================================================================
BUILD REQUIREMENTS:

iOS SDK 7.0 or later


================================================================================
RUNTIME REQUIREMENTS:

iOS 6.0 or later


================================================================================
PACKAGING LIST:

AppDelegate.{h,m}
    - The application delegate sets up the initial iPhone/iPod touch/iPad view and makes the window visible.

RootViewController.{h,m}
    - The view controller displays what each icon does on iOS.

Settings.bundle.{h,m}
    - An example settings bundle used for application preferences in Settings app.  UI is not significant here, but it is used only to exhibit the app icon for that bundle.


================================================================================
CHANGES FROM PREVIOUS VERSIONS:

Version 1.2
- Upgraded for iOS 7.0 SDK.
- Renamed to Application Icons and Launch Images for iOS.

Version 1.1
- Upgraded for iOS 6.0 SDK, now uses Storyboards.

Version 1.0
- First version.

================================================================================
Copyright (C) 2010-2014 Apple Inc. All rights reserved.