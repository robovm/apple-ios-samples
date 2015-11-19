# SimpleEKDemo


## DESCRIPTION:
+ This sample shows how to use EventKit and EventKitUI frameworks to check and request access to the user’s Calendar database. It also shows how to access and edit calendar data in the Calendar database.

+ The application uses table views to display EKEvent objects retrieved from an EKEventStore object. It implements EKEventViewController for viewing and editing existing EKEvents, and uses EKEventEditViewController for creating new EKEvents.

+ Amongst the techniques shown are how to:
* Check and request access to the Calendar database.
* Create and initialize an event store object.
* Create a predicate, or a search query for the Calendar database.
* Override EKEventEditViewDelegate method to respond to editing events.
* Access event store, calendar and event properties. 


## BUILD REQUIREMENTS:
+ iOS SDK 8.4 or later


## RUNTIME REQUIREMENTS:
+ iOS 8.0 or later


## PACKAGING LIST:

+ Application Configuration

SimpleEKDemoAppDelegate.{h,m}
Application delegate that sets up a tab bar controller with a root view controller -- a navigation controller that in turn loads a table view controller to manage a list of calendars.


+ View Controllers

RootViewController.{h,m}
Table view controller that manages a table view displaying a list of events fetched from the default calendar.



Copyright (C) 2010-2015 Apple Inc. All rights reserved.