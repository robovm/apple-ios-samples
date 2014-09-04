### LazyTableImages ###

===========================================================================
DESCRIPTION:

This sample demonstrates a multi-stage approach to loading and displaying a 
UITableView.  It displays the top paid iPhone apps on Apple's App Store.

It begins by loading the relevant text from the RSS feed so the table can load
as quickly as possible, then downloads the app images for each row asynchronously
so the UI is more responsive.

===========================================================================
BUILD REQUIREMENTS:

iOS 6.0 SDK or later

===========================================================================
RUNTIME REQUIREMENTS:

iOS 5.0 or later

===========================================================================
PACKAGING LIST:

LazyTableAppDelegate.{h/m}
    The app delegate class that downloads in the background the
    "Top Paid iPhone Apps" RSS feed using NSURLConnection.

AppRecord.{h/m}
    Wrapper object for each data entry, corresponding to a row in the table.

RootViewController.{h/m}
    UITableViewController subclass that builds the table view in multiple stages,
    using feed data obtained from the LazyTableAppDelegate.

ParseOperation.{h/m}
    Helper NSOperation object used to parse the XML RSS feed loaded by LazyTableAppDelegate.

IconDownloader.{h/m}
    Helper object for managing the downloading of a particular app's icon.
    As a delegate "NSURLConnectionDelegate" is downloads the app icon in the background if it does not
    yet exist and works in conjunction with the RootViewController to manage which apps need their icon.

===========================================================================
CHANGES FROM PREVIOUS VERSIONS:

Version 1.4
- Migrated to Storyboards and ARC.
- Upgraded to build with the iOS 6 SDK.
- Added support for devices with 4" retina displays.
- Modified IconDownloader to use blocks for its callback instead of delegation.

Version 1.3
- Upgraded project to build with the iOS 5 SDK.
- Deployment target set to iOS 5.
- Fixed an analyzer warning in LazyTableAppDelegate.
- Fixed a subtle memory leak in RootViewController.
- Changed ParseOperation to use blocks for its callbacks instead of delegation.
- Updated initial nib loading and app window setup to reflect the most recent recommended practices.
- Renamed a defined constant in IconDownloader to be less confusing.
- Fixed a bug in IconDownloader that may cause a downloaded app icon to not be resized properly.

Version 1.2
- Deployment target set to iPhone OS 3.2.

Version 1.1
- Fixed crashing bug in didReceiveMemoryWarning, upgraded project to build with the iOS 4 SDK.

Version 1.0
- First version.

===========================================================================
Copyright (C) 2013 Apple Inc. All rights reserved.