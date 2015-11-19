# The CloudKit Catalog iOS app

This app teaches you how to use *Discoverability* to get the first name and last name of the user logged into iCloud. 
It can add a CKRecord with a location and query for CKRecords near a location. You can upload and retrieve images as 
CKAssets. It also shows how to use CKReferences with CKReferenceActionDeleteSelf so the child records are deleted when 
the parent record is deleted. Finally, it also shows how to use CKSubscription to get push notifications when a new 
item is added for a record type.

## Instructions

1. In the project editor, change the bundle identifier under Identity on the General pane or by editing Info.plist. 
   The bundle identifier is used to create the app’s default container.
2. In the Capabilities pane, enable iCloud and check the CloudKit option.
3. Make sure you are signed into your iCloud account in the simulator before running the app.


## CloudKit Schema

Please create the schema using CloudKit Dashboard.

- Record Type: Items
 - Fields: name (String), location (Location)


- Record Type: Photos
 - Fields: photo (Asset)


- Record Type: ReferenceItems
 - Fields: name (String)


- Record Type: ReferenceSubitems
 - Fields: name (String), parent (Reference)


NOTE: When you add record, you can use custom CloudKit zones. Custom zones can be created using CloudKit Dashboard.

## Build Requirements

- iOS 8.0 or newer SDK and Xcode 6 or later


## Runtime Requirements

- iOS 8.0 or later
- You need an Apple Developer account with the iOS or Mac OS Developer Program to use CloudKit.


Copyright (C) 2015 Apple Inc. All rights reserved.