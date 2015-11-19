# CloudPhotos

## Description

CloudPhotos is a clear and concise CloudKit sample showing how to share photos among other users.  Photos are represented as CKRecords, holding the photo (CKAsset), its title (NSString), creation date (NSDate) and the location (CLLocation) it was created.  The sample will display all photos found in the public CloudKit container.  Users can view photo records, but only the owner of photo records can change or delete them.  The attributes that can be edited are the photo itself and it’s title, the creation date and location data are read-only.  Users add photo records from their photo library or camera role.

CloudPhotos covers a good range of CloudKit APIs in a clear, concise way. The sample offers code and strategies in handling real world situations when using CloudKit.  One important feature is the proper handling of user log in and out, and turning on or off the network.  The sample deals with these kinds of situations and updates its user interface accordingly.  No network means no access to the Cloud, and no login means users can’t add or change photos, yet they can still view them as read only.

It makes sense for developers who choose to start writing CloudKit code to use CloudPhotos as a guide.

Filtering -
The primary view controller is a UITableViewController showing all photos found in the public database.  You can filter that list by using UISearchController, typing the photo name or partial name.  You can also filter photos that were taken near your current location, photos only taken by you, or recently taken photos in the last 5 days.  It uses UIRefreshControl to allow the list of photos to be refreshed or updated.  Users can edit that list by deleting one or more photo records.

Subscriptions -
The sample uses CKSubscriptions to detect when a photo is added, deleted or modified.  It will handle appropriately these remote actions and assist the user in deciding what do to next.  If a photo was added, changed or deleted, the primary table view will simply update those changes.  If you are viewing a photo, and the owner removes it, the user will be notified that photo has been removed.

Discoverability - 
The sample uses the discoverability APIs to identify the logged in user for proper write access (who created a photo and blocking others from removing it).

Editing -
The secondary view controller is another UITableViewController showing the detail of a particular photo record.  From there you can change the photo and its title.

Maps - 
The location of that photo is displayed using MKMapView with a single pin annotation.  That annotation callout displays the physical address using CLGeocoder.

### Schema

The CKRecord schema is as follows:

"PhotoRecord";    // the CKRecord type
"PhotoAsset";        // CKAsset attribute
"PhotoTitle";        // NSString attribute
"PhotoDate";         // NSDate attribute
"PhotoLocation";     // CLLocation attribute

Note: When defining your own record schema, if you want attributes searchable - make sure its "Query" checkbox is checked in CloudKit Dashboard


### The APIs used in this sample

1. CKQuery/CKQueryOperation - to find photo records, and photo records near your current user location.  The sample shows how to populate its table view of photos while making the least number of queries possible, 10 at a time.  That is, query only the records that are necessary.  It also use CKQueryCursor object that marks the stopping point for a query and the starting point for retrieving the remaining results.

2. CKDatabase/deleteRecordWithID - to show how to delete photo records.

3. CKDatabase/saveRecord - to show how to save/update photo records.

4. CKModifyRecordsOperation - to show how to delete multiple photo records in one operation (delete all action)

5. CKContainer/accountStatusWithCompletionHandler - Reports whether the current user’s iCloud account can be accessed.  The sample uses this to determine if the app can add or edit photo records.  If a user is logged out, the photo records become read only.

6. CKContainer/requestApplicationPermission - Used to find out the currently logged in CloudKit account’s user name.

7. CKQueryNotification - Used to analyze an incoming push notification, helps the sample decide how to react to changes to photo records.

8. CKSubscriptions to listen or changes in its record type (photos added, deleted or modified).  This gives you free push notification service support and the sample shows how to properly respond to these notifications.  

9. CKFetchSubscriptionsOperation - Used to provide a strategy to avoid re-registering for the same kind of CKSubscription already residing in the CloudKit server.

10. CKFetchNotificationChangesOperation - Used to mark CKSubscription notifications as “Read”, so they don’t repeatedly notify your app.

11. UIStateRestoration - I believe all samples that show data should properly restore it’s state.  This sample provides complete state restoration of its two view controllers.  Since fetching CloudKit records can take an unknown amount of time, this sample shows how to offer state restoration along with asynchronous network connections.


## Setup

1. In the project editor, change the bundle identifier under Identity on the General pane or by editing Info.plist. The bundle identifier is used to create the app’s default container.
2. In the Capabilities pane, enable iCloud and check the CloudKit option.
3. If you choose to use the iOS Simulator, make sure you are signed into your iCloud account in the simulator before running the app.

This sample does not cover the topic of offline caching if there is no network or the user it logged out of iCloud.

The CloudKit Framework Reference says this:

"CloudKit is not a replacement for your app’s existing data objects. Instead, CloudKit provides complementary services for managing the transfer of data to and from iCloud servers. Because it provides minimal offline caching support, CloudKit relies on the presence of the network and optionally a valid iCloud account. (A valid iCloud account is required only when you want to save data that is specific to a single user.) Apps can always store data in a public area that is readable by all users.”

So CloudPhotos accesses the public container without having to log into iCloud.  The data in that container will be read only, however.  So this sample can continue to function, but changes cannot be made to those CKRecords.

To make your app 100% functional when logged out or with no network, refer to the WWDC 2014, Advanced CloudKit, Session 231, which talks about offline caching, and tracking changes yourself while logged out then when logging back in you upload those changes.


## Requirements

### Build

Xcode 6.x - OS X 10.10 SDK or later, iOS 8.0 SDK or later

### Runtime

iOS 8.0 or later.


Copyright (C) 2015 Apple Inc. All rights reserved.
