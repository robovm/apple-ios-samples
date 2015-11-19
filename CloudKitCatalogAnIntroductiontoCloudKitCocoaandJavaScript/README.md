# CloudKit Catalog: An Introduction to CloudKit

CloudKit Catalog consists of a native iOS application and a web application which demonstrate use of 
Objective C and JavaScript CloudKit APIs respectively.

# Schema

The two apps share an *Items* record type which has fields

* name : String
* location : Location
* asset : Asset

# Records, Notifications and Sync

Both apps allow an authenticated user to write *Items* records to a zone in his/her private database. The native app
allows you to subscribe to changes to Items. So if you create or delete Items in the web app you will get notifications
of these changes in the native app. The web app supports subscribing to changes to a specific zone in addition to the
*query-level* subscriptions of the native app. You can register for notifications in the web app by 
opening a connection with the notification backend. You will then receive notifications for created Items in the native 
app. In the case of zone-level changes, you can use the sync API in the web app to retrieve all changed/created records 
upon receipt of a notification.

# Discoverability

The web app allows you to fetch the names of users that have made themselves discoverable but
does not provide the functionality for a user to set their discoverability. However, the native app does provide
this functionality and you can therefore set yourself to be discoverable in the native app and see your name in the web
app. You will hereby also make yourself discoverable to other users of the app.


Copyright (C) 2015 Apple Inc. All rights reserved.
