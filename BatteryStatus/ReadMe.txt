### BatteryStatus ###

================================================================================
DESCRIPTION:

Demonstrates the use of the battery status properties and notifications provided via the iOS OS SDK.

Testing:

The sample is only useful when run on a device. The simulator always returns unknown battery status.


================================================================================
BUILD REQUIREMENTS:

iOS 6.0 SDK or later

================================================================================
RUNTIME REQUIREMENTS:

iOS 6.0 or later

================================================================================
PACKAGING LIST:

BatStatAppDelegate
Delegate of the main application that presents the initial window.

BatStatViewController
Receives battery status change notifications. Queries the
battery status and presents it in a UITableView. Enables and disables battery status updates.

================================================================================
CHANGES FROM PREVIOUS VERSIONS:

Version 1.2
    Updated for Xcode 5 (iOS 6 and iOS 7) with storyboards and Auto Layout.

Version 1.1
	Updated for iOS 4.
	
Version 1.0
	First release.


Copyright (c) 2009-2013 Apple Inc. All rights reserved.