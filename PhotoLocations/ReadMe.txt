
PhotoLocations
==============

This sample illustrates a Core Data application that uses more than one entity and uses transformable attributes. It also shows inferred migration of the persistent store.

The first screen displays a table view of events, which encapsulate a time stamp, a geographical location expressed in latitude and longitude, and the thumbnail of a picture for the event. The user can add and remove events using the first screen.

Event has an optional to-one relationship to Photo (which has an inverse to-one relationship back to Event) that contains the data for a full-sized image. By selecting a row on the first screen, the user displays a detail view that shows the photo (or allows the user to choose a photo for the event).

The photo data is not stored with the event object itself because it's not always needed.  When the list of events is first displayed, only the thumbnails are shown. The events' photos are initially represented by faults. The full picture is required only if the user inspects the detail of an event. At the point at which the application asks for a given event's photo object, the fault fires and the photo object is retrieved automatically. This "lazy loading" of data means your application's memory consumption is kept as low as possible.

Although the application's data model is different from the original application's, the original data store is opened by specifying that inferred migration should be used in the application delegate's persistentStoreCoordinator method. (You must ensure that the applications' bundle identifiers are the same.)


View Controllers
----------------

APLRootViewController.{h,m}
The table view controller responsible for displaying the list of events, supporting additional functionality:
 * Addition of new new events;
 * Deletion of existing events using UITableView's tableView:commitEditingStyle:forRowAtIndexPath: method.


APLEventDetailViewController.{h,m}
The table view controller responsible for displaying the time, coordinates, and photo of an event, and allowing the user to select a photo for the event, or delete the existing photo.


Model
-----

Locations.xcdatamodel
The Core Data managed object model for the application.
This model contains two versions:
* The version from the original Locations application
* The version for the new application.
The application delegate specifies inferred migration in the persistentStoreCoordinator method.


APLEvent.{h,m}
A Core Data managed object class to represent an event containing geographical coordinates, a time stamp, and a thumbnail image. Event also has a to-one relationship to Photograph.


APLPhoto.{h,m}
A Core Data managed object class to represent a photograph. Photograph has a to-one relationship to Event.


APLImageToDataTransformer.{h,m}
A value transformer which transforms a UIImage object into an NSData object.
Both Event and Photograph contain image data stored as a transformable attribute.



Application configuration
-------------------------

APLAppDelegate.{h,m}
Configures the Core Data stack and the first view controller.



===========================================================================
Copyright (C) 2009-13 Apple Inc. All rights reserved.
