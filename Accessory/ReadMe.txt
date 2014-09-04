### TableViewCell Accessory ###

===========================================================================
DESCRIPTION:

This sample demonstrates two methods that can be used to implement a custom accessory view in your UITableViewCell's.  In both examples, a custom control that implements a toggle-able checkbox is used.

The first method shows you how to override the appearance or control of the accessory view, much like that of "UITableViewCellAccessoryDetailDisclosureButton". It implements the custom accessory view by setting the table's "accessoryView" property with a custom control which draws a checkbox. It can be toggled by selecting the entire table row by implementing UITableView's "didSelectRowAtIndexPath". The checkbox is trackable (checked/unchecked), and can be toggled independent of table selection.

The second method shows how to implement a trackable-settable UIControl embedded in a UITableViewCell. This approach is handy if an application already uses its accessory view to the right of the table cell, but still wants a checkbox view that supports toggling states of individual row items. The checkbox on the left provides fulfills this need and is trackable (checked/unchecked) independent of table selection. This is a similar user interface to that of Mail's Inbox table where mail items can be individually checked and unchecked for deletion.  The checkbox is trackable (checked/unchecked), and can be toggled independent of table selection.


===========================================================================
BUILD REQUIREMENTS:

iOS 7.0 SDK or later


===========================================================================
RUNTIME REQUIREMENTS:

iOS 6.0 or later


===========================================================================
PACKAGING LIST:

AppDelegate.{h,m}
    - The application delegate class.

AccessoryViewController.{h,m}
    - The table view controller for the Accessory View tab.  It Manages a table view where each cell contains a checkbox control in the accessoryView.
    
CustomAccessoryViewController.{h,m}
    - The table view controller for the Custom Accessory tab.  It Manages a table view where each cell contains a checkbox control on the left side of a custom table view cell.

DetailViewController.{h,m}
    - A view controller for showing information about a single item.
    
CustomCell.{h,m}
    - A custom UITableViewCell that contains a Checkbox control in addition to its accessory control.
    
Checkbox.{h,m}
    - A UIControl subclass that implements a checkbox.


===========================================================================
CHANGES FROM PREVIOUS VERSIONS:

Version 1.4
- Updated for iOS 7.
- Merged in content from the 'TouchCells' sample.
- The checkbox is now implemented as a custom control.

Version 1.3
- Upgraded for iOS 6.0, now using Automatic Reference Counting (ARC) and storyboards.
- Updated to adopt current best practices for Objective-C.

Version 1.2
- Upgraded project to build with the iOS 4.0 SDK.

Version 1.1
- Upgraded for 3.0 SDK due to deprecated APIs.
- In "cellForRowAtIndexPath" it now uses UITableViewCell's initWithStyle.

Version 1.0 
- First release.

===========================================================================
Copyright (C) 2008-2014 Apple Inc. All rights reserved.