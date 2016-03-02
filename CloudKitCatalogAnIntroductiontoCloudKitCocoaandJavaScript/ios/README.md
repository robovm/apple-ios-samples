# The CloudKit Catalog iOS app

This iOS app written in Swift provides code samples of some of the core API methods of the CloudKit Framework. Topics
covered:

1. Requesting discoverability permission and retrieving users' discoverable information.
2. Querying records.
3. CRUD operations on zones.
4. CRUD operations on records.
5. Fetching and paginating through changed records in a zone using CloudKit's syncing capabilities.
6. CRUD operations on subscriptions.
7. Registering for notifications and marking them as read.

## Configuration

Before running the sample app you must change the bundle identifier in the *General* tab of your project settings to a
container identifier that you own. The app requires a record type **Items** with the following fields.

* name : String
* location : Location
* asset : Asset

Create this record type through CloudKit Dashboard if it doesn't already exist. You can also create a couple of public
records through the dashboard and then view them in the Query section of the app.

## Running the app

Whether you are running the app on a simulator or a device, you must be signed in to iCloud to use the CloudKit API methods
other than the query sample which doesn't require authentication.

### Receiving notifications

You must run the app on a device to test CloudKit notifications. You will be prompted to give the app permission to receive 
remote notifications on startup. Then, to test notifications, create a zone-level (for instance) subscription and write
records to that zone using the javascript sample (pointing to the same container - see the corresponding instructions). You
will not be notified of record changes if those changes are made from the same device, so you must either use another device or
the javascript sample. When you have been notified of a change to a zone, you can run the **FetchRecordChanges** operation on 
that zone to get the changed records. This is covered by the **Sync** section of the app.


Copyright (C) 2015 Apple Inc. All rights reserved.