
DateSectionTitles
=================

This application shows how to create section information for NSFetchedResultsController using dates.

A single table view controller displays events sorted by date and grouped into sections by year and month. The Event entity has three attributes:
* timeStamp (persistent NSDate object).
  The time stamp represents the time the event occurred.
* title (persistent NSString object).
  The title of each event as it will be displayed on a row in the table view (this is not to be confused with section title). When the default data is created in the application delegate, the title is initialized to a string representation of the date.
* sectionIdentifier (transient NSString object).
  The sectionIdentifier is used to divide the events into sections in the table view. It is a string value representing the number ((year * 1000) + month). Using this value, events can be correctly ordered chronologically regardless of the actual name of the month. It is calculated and cached on demand in the custom accessor method.

The sorting is all done at fetch time by the fetched results controller. The section name transformations are UI level and have no effect on the order of data.

Main Classes
------------
APLAppDelegate
Application delegate that configures the Core Data stack.

APLMasterViewController
A table view controller that presents events by section.

APLEvent
A managed object class to represent an event in time.


===========================================================================
Copyright (C) 2009-2013 Apple Inc. All rights reserved.
