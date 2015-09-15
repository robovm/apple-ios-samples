# CloudSearch

## Description

Demonstrates how to find documents in iCloud, using NSMetaDataQuery.

Included as part of this sample is a class called "CloudDocumentsController" which runs Spotlight queries, using NSMetaDataQuery, to discover files found in iCloud.  You can use this class to quickly gain access to those available files.

## Setup

Configuring your Xcode project for OS X and iOS require a few steps in the OS X Provisioning Portal and in Xcode:

1) Configure your OS X/iOS device:
Each device you plan to test needs to have an iCloud account.  This is done by creating or using an existing Apple ID account that supports iCloud.  You can do this directly on the device by opening System Preferences on OS X or Settings app on iOS, and selecting iCloud.  Each device needs to be configured with this account.
 
2) Configure your Provisioning Profile:
You will need to visit the Developer Certificate Utility page to create a new development provisioning profile <https://developer.apple.com/certificates/index.action>.  This involves creating a new App ID to include iCloud support capability. iCloud requires an Explicit App ID (non-wildcard). After creating the App ID verify that iCloud shows as Enabled on the Manage Tab, and click 'Edit' button to enable iCloud if necessary.
 
After creating a new development provisioning profile, return to Xcode, open its Preferences -> Accounts tab, click "View Details..." button, and click refresh button in lower left.

3) The bundle identifier defined on your Xcode project's Target > Info tab needs to match the App ID in the iCloud provisioning profile.

4) Xcode Target Cababilities
Select your target, then select "Capabilities".  From there make sure:

    "iCloud Documents" service is checked.
    "Containers" make sure "Use default container" is checked and the actual container to be used is checked (i.e. iCloud.$CFBudnleIdentifier)".
 
You can include more than one container if you wish. For example this sample currently has for its container identifier:
 
    iCloud.com.yourcompany.cloudsearch

    If you encounter any code signing errors, chances are your provisioning profile does not match between Xcode and the Developer Portal.  This can be fixed by turning off iCloud cabability switch and turning it on again.

5) Xcode Target's General pane, select the appropriate "Team".

## Requirements

### Build

Xcode 6.x - OS X 10.10 SDK or later, iOS 8.0 SDK or later

### Runtime

OS X 10.9 or later, iOS 8.0 or later.

Copyright (C) 2013-2015 Apple Inc. All rights reserved.
