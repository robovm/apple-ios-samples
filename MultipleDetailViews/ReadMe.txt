### MultipleDetailViews ###

===========================================================================
DESCRIPTION:

This sample shows how you can use UISplitViewController to manage the presentation of multiple detail views in conjunction with a navigation hierarchy.

The application uses a split view controller with a custom object as its delegate.  When you make a selection in the table view, a new view controller is set as the split view controller's second view controller.

The custom split view delegate defines a protocol (SubstitutableDetailViewController) that detail view controllers must adopt. The protocol specifies a property to hide and show the bar button item controlling the popover.


===========================================================================
BUILD REQUIREMENTS:

iOS 5.0 SDK or later

===========================================================================
RUNTIME REQUIREMENTS:

iOS OS 5.0 or later

===========================================================================
PACKAGING LIST:

AppDelegate.{h,m}
The application delegate.  It configures the application window and split view controller.

DetailViewManager.{h,m}
The split view controller's delegate.  It coordinates the display of detail view controllers.

FirstTableViewController.{h,m}
A table view controller that manages three rows. Selecting the first row pushes SecondTableViewController onto the navigation stack.  Selecting one of the remaining two rows creates a new detail view controller that is added to the split view controller.

SecondTableViewController.{h,m}
A table view controller that manages two rows. Selecting a row creates a new detail view controller that is added to the split view controller.

FirstDetailViewController.{h,m}
SecondDetailViewController.{h,m}
Simple view controllers that adopt the SubstitutableDetailViewController protocol defined by DetailViewManager. They are responsible for adding and removing the popover button: FirstDetailViewController uses a toolbar; SecondDetailViewController uses a navigation bar.


===========================================================================
CHANGES FROM PREVIOUS VERSIONS:

Version 1.2
- Updated project to build with the iOS 5.0 SDK.
- Changed deployment target to iOS 5.0.
- Demonstrates managing the presentation of multiple detail view controllers with a navigation hierarchy that includes multiple levels.

Version 1.1
- Added localization support
- viewDidUnload now releases IBOutlets.

Version 1.0
- First version.

===========================================================================
Copyright (C) 2012 Apple Inc. All rights reserved.
