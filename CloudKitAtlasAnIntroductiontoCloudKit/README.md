# CloudKitAtlas: An Introduction to CloudKit
=======

CloudKitAtlas is a sample intended as a quick introduction to CloudKit. It teaches you how to use Discoverability to get the first name and last name of the user logged into iCloud. It can add a CKRecord with a location and query for CKRecords near a location. You can upload and retrieve images as CKAssets. It also shows how to use CKReferences with CKReferenceActionDeleteSelf so the child records are deleted when the parent record is deleted. Finally, it also shows how to use CKSubscription to get push notifications when a new item is added for a record type.


## Instructions

1. In the project editor, change the bundle identifier under Identity on the General pane or by editing Info.plist. The bundle identifier is used to create the app’s default container.
2. In the Capabilities pane, enable iCloud and check the CloudKit option.
3. Make sure you are signed into your iCloud account in the simulator before running the app.


## Build Requirements

- iOS 8.0 SDK and Xcode 6


### Runtime Requirements

- iOS 8.0
- You need an Apple Developer account with the iOS or Mac OS Developer Program to use CloudKit.



Copyright (C) 2014 Apple Inc. All rights reserved.
