# The CloudKit Catalog web app

This web app provides executable sample code for the core API methods provided by the CloudKit JS JavaScript library. 
Topics covered:

1. Authenticating users.
2. Retrieving users' discoverable information.
3. Querying records.
4. CRUD operations on zones.
5. CRUD operations on records within zones.
6. Fetching changed records within a zone using CloudKit's syncing capabilities.
7. CRUD operations on subscriptions.
8. Registering for notifications.

## Configuration

Before running the web app, modify the file *js/init.js*. Replace the container identifier with one that you own and insert an
API token generated through CloudKit Dashboard in the appropriate place. The web app assumes the existence of an **Items**
record type with the following fields.

* name : String
* location : Location
* asset : Asset

Create this record type through CloudKit Dashboard if it doesn't already exist.

## Runtime Requirements
 
For best results, use a recent version of Safari or Chrome.


Copyright (C) 2015 Apple Inc. All rights reserved.