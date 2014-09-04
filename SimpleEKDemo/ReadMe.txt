### SimpleEKDemo ###

================================================================================
DESCRIPTION:

This sample shows how to use EventKit and EventKitUI frameworks to check and request access to the user’s Calendar database. It also shows how to access and edit calendar data in the Calendar database.

The application uses table views to display EKEvent objects retrieved from an EKEventStore object. It implements EKEventViewController for viewing and editing existing EKEvents, and uses EKEventEditViewController for creating new EKEvents.

Amongst the techniques shown are how to:
* Check and request access to the Calendar database.
* Create and initialize an event store object.
* Create a predicate, or a search query for the Calendar database.
* Override EKEventEditViewDelegate method to respond to editing events.
* Access event store, calendar and event properties. 

================================================================================
BUILD REQUIREMENTS:

iOS SDK 6.0 or later

================================================================================
RUNTIME REQUIREMENTS:

iOS 6.0 or later

================================================================================
PACKAGING LIST:

Application Configuration
-------------------------

SimpleEKDemoAppDelegate.{h,m}
MainWindow.xib
Application delegate that sets up a tab bar controller with a root view controller -- a navigation controller that in turn loads a table view controller to manage a list of calendars.


View Controllers
------------------------

RootViewController.{h,m}
RootViewController.xib
Table view controller that manages a table view displaying a list of events fetched from the default calendar.

===========================================================================
CHANGES FROM PREVIOUS VERSIONS:

 1.1 - Updated for iOS 6.0. Now uses ARC and storyboard. Shows how to check and request access to a user’s Calendar database. You may encounter a CADObjectGetRelatedObjects failed with error Error Domain=NSMachErrorDomain Code=268435459 "The operation couldn’t be completed. (Mach error 268435459 - (ipc/send) invalid destination port)" message when deleting an event. This is a known bug that does not affect running this sample.
 1.0 - First version.

================================================================================
Copyright (C) 2010-2013 Apple Inc. All rights reserved.