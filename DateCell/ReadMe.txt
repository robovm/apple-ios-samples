### DateCell ###

===========================================================================
DESCRIPTION:

Demonstrates formatted display of date objects in table cells and use of UIDatePicker to edit those values.

Using a grouped style UITableViewController, the sample has two UITableViewCells to draw the primary title and NSDate values.  This is accomplished using the built-in cell type "UITableViewCellStyleValue1" which supports left and right text.

As a delegate to this table, the sample uses the method "didSelectRowAtIndexPath" to open the UIDatePicker control.

For iOS 6.x and earlier, UIViewAnimation is used for sliding the UIDatePicker up on-screen and down off-screen.

For iOS 7.x, the UIDatePicker is added in-line to the table view.

The action method of the UIDatePicker will directly set the NSDate property of the custom table cell.

In addition, this sample shows how to use NSDateFormatter class to achieve the custom cell's date-formatted appearance.

===========================================================================
BUILD REQUIREMENTS:
Xcode 5.0, iOS SDK 7.0

===========================================================================

RUNTIME REQUIREMENTS: 
iOS 6.0 or later

===========================================================================
CHANGES FROM PREVIOUS VERSIONS:

1.6 - Fixed bug data source cell row detection in cellForRowAtIndexPath, now using CGRectGetHeight().
1.5 - Editorial change
1.4 - Added a screenshot for this sample.
1.3 - Updated to use in-line UIDatePicker for iOS 7.
1.2 - Upgraded for iOS 6.0, now using Automatic Reference Counting (ARC) and storyboards,
      updated to adopt current best practices for Objective-C.
1.1 - Upgraded project to build with the iOS 4 SDK.
1.0 - First release.


Copyright (C) 2009-2014 Apple Inc. All rights reserved.