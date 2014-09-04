# Popovers

This sample demonstrates how to use popovers using UIPopoverController in iOS, including presentation, dismissal, and rotation.
The sample uses a UISplitViewController to show how to present popovers from bar button items. It also demonstrates how you can ensure that multiple popovers are not presented at the same time.

## Main classes

### APLMasterTableViewController
Acts as the master list view controller for the split view controller and adds rows of placeholder items to the table view.

### APLDetailViewController
Displays the detail view of the split view controller. This also contains buttons and a toolbar that all present popovers. The controller responds to orientation changes when popovers are visible and re-displays them in the new orientation; it is also responsible for ensuring that there are never multiple popovers visible at the same time.

### APLPopoverContentViewController
A view controller that manages the contents of the popovers in this sample. In this example, the view  only contains a label with text.


----
Copyright (C) 2010-2013 Apple Inc. All rights reserved.