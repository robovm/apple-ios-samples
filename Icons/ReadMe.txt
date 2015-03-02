Application Icons and Launch Images for iOS

================================================================================
ABSTRACT:

This sample, previously named Icons, demonstrates the proper configuration of application icons and launch images on iOS.

ICONS:

Every app is required to include an app icon.  It is recommended that apps also provide icons for: Spotlight, the Settings app, and when creating an Ad Hoc build and adding it to iTunes.  See QA1686: App Icons on iPad and iPhone, for a complete listing of icons required for iPhone, iPad, and Universal apps <https://developer.apple.com/library/ios/qa/qa1686/_index.html>.


LAUNCH ARTWORK:

The launch artwork is displayed while your app starts up, before the first view has loaded.  Beginning with iOS 8, there are two ways to include launch artwork with your app: a launch file, or a collection of launch images.

LAUNCH FILE:

Beginning with iOS 8, you may designate a storyboard or xib file as the launch file for your application.  iOS 8 devices will display the initial scene from a storyboard launch file, or the first view from a xib launch file during launch.  Because there is only one launch file, it must take advantage of size classes and auto layout to adapt to the current device's screen size.  See <https://developer.apple.com/design/adaptivity/>.  Including a launch file indicates to the system that your application supports the native display size of the iPhone 6 and iPhone 6 Plus, removing the compatibility mode on these devices.  See the Launch Images in the iOS Human Interface Guidelines for further discussion <https://developer.apple.com/library/ios/documentation/UserExperience/Conceptual/MobileHIG/LaunchImages.html>.

If your application supports earlier versions of iOS, it must also include launch images.

LAUNCH IMAGES:

Launch images are screen-sized images displayed during launch.  You supply a separate launch image for each device, iOS version, and possibly launch orientation.  If your application is an iPhone or Universal app, it must included a launch image specifically for devices with 4" screens (iPhone 5, iPhone 5s, iPod Touch 5).  If your application supports the native display size of the iPhone 6 and iPhone 6 Plus, it must include launch images for these devices as well.  Otherwise a compatibility mode is applied when your app is run on these devices.  See Launch Images in the iOS Human Interface Guidelines for further discussion <https://developer.apple.com/library/ios/documentation/UserExperience/Conceptual/MobileHIG/LaunchImages.html>.

Note: The iOS 7/8 specific launch images in this sample use the following convention, Default-iOS<version>-<usage_specific_modifiers><scale_modifier><device_modifier>.png.  This convention is arbitrary, you may name to your iOS 7/8 specific launch images as you see fit.  However, all of your app's iOS 7/8 specific launch images must be listed under the UILaunchImages key in your app's information property list.  Launch images for iOS 6, or launch images that will be shared between iOS 6 and iOS 7/8 must continue to name their launch images according to the legacy convention which may be found in the iOS App Programming Guide.


This sample is a universal binary that supports iPhone/iPod touch/iPad and includes support for high resolution displays.  It includes two targets, Icons, and IconsWithAssetCatalogs.  Icons demonstrates the older methods for configuring icons and launch artwork, including the images as resources and adding the CFBundleIconFiles key to its Info.plist.  IconsWithAssetCatalogs uses an asset catalog to store the icons and a launch file for the launch artwork.  Developers are encouraged to migrate their apps to use asset catalogs and launch files.

================================================================================
BUILD REQUIREMENTS:

iOS SDK 8.0 or later


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

Version 1.3
- Upgraded for the iOS 8.0 SDK and iPhone 6 Plus

Version 1.2
- Upgraded for iOS 7.0 SDK.
- Renamed to Application Icons and Launch Images for iOS.

Version 1.1
- Upgraded for iOS 6.0 SDK, now uses Storyboards.

Version 1.0
- First version.

================================================================================
Copyright (C) 2010-2014 Apple Inc. All rights reserved.