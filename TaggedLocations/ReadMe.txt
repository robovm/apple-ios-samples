
Simple Core Data Relationships
==============================

The TaggedLocations application illustrates how you can manipulate Core Data attributes and relationships in an iOS application.

The first screen displays a table view of events, which encapsulate a time stamp, a geographical location expressed in latitude and longitude, and a name for the event. The user can add, remove, and edit events using the first screen.

Events have a to-many relationship to tags (which have an inverse to-many relationship to events). Tags have a name which describes a feature of an event. Tags are displayed in a second table view; when a tag is related to the selected event, a check mark is displayed in the corresponding row.



Main Components
===============

View Controllers
----------------
APLEventsTableViewController
The table view controller responsible for displaying the list of events, supporting additional functionality:
 * Addition of new events
 * Deletion of existing events using UITableView's tableView:commitEditingStyle:forRowAtIndexPath: method
 * Editing an event's name

APLTagSelectionController
The table view controller responsible for displaying and editing tags.
The rows show a check mark if the selected event is related to the corresponding tag. 

Model
-----
TaggedLocations.xcdatamodeld
The Core Data managed object model for the application.

APLEvent
A Core Data managed object class to represent an event containing geographical coordinates and a time stamp.

APLTag
A Core Data managed object class to represent a tag.

Table View Cells
----------------
APLEventTableViewCell
Table view cell to display information about an event.
The delegate is the RootViewController table view controller which acts as:
* The name text field's delegate to respond to editing operations
* The target of the tag button to initiate tag editing


APLEditableTableViewCell
Table view cell to present an editable text field.


Application configuration
-------------------------
APLAppDelegate
Configures the Core Data stack and passes a managed object context to the first view controller.

MainStoryboard.storyboard
Loaded automatically by the application.


===========================================================================
Copyright (C) 2009-2013 Apple Inc. All rights reserved.
