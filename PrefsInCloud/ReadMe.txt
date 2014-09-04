### PrefsInCloud ###

===========================================================================
DESCRIPTION:

A simple iOS iPhone application that demonstrates how to use iCloud key-value store to share a single piece of data, its background color, with the same app on other iOS devices. It uses NSUbiquitousKeyValueStore to achieve this by storing a simple NSInteger representing a chosen color index.

The user changes the background color of the app by choosing between 4 known colors. Tap the 'i' button and pick the color you want. After tapping "Done", this key-value store (number 0 to 3) is uploaded to iCloud. Any device running the same app will be notified to match that specific background color.

It then uses NSNotificationCenter and iCloud's NSUbiquitousKeyValueStoreDidChangeExternallyNotification to detect for value changes in the cloud.

Important:
Using iCloud's NSUbiquitousKeyValueStore with this sample will not work in the simulator.

Note:
Each application that uses iCloud key-value store is limited to 64KB of total space.  So do not use it to store large amounts of data.

For more detailed information in iCloud key-value store, refer to the "Preferences and Settings Programming Guide".

===========================================================================
SETTING UP YOUR PROJECT AND DEVICES:

Configuring your Xcode project and devices require a few steps in the iOS Provisioning Portal and in Xcode:

Note: If you are unfamiliar with device provisioning or entitlements, please refer to the "iOS Development Workflow Guide" found at <http://developer.apple.com/library/ios/#documentation/Xcode/Conceptual/ios_development_workflow/>

1) Configure your devices:
Each device you plan to test needs to have an iCloud account. This is done by creating or using an existing Apple ID account that supports iCloud.  You can do this directly on the device by opening the Settings app, selecting iCloud option. Each device needs to be configured with this account.

2) Configure your Provisioning Profile:
You will need to visit the iOS Provisioning Portal to create a new development provisioning profile <https://developer.apple.com/ios/my/overview/index.action>. This involves creating a new App ID to include iCloud support. iCloud requires an Explicit App ID (non-wildcard). After creating the App ID verify iCloud shows as Enabled on the Manage Tab, and click 'Configure' to enable iCloud if necessary.

After creating a new development provisioning profile in the iOS Provisioning Portal "Provisioning" section > "Development" tab, download and install the iCloud development provisioning profile by dragging it to the Xcode icon on the Dock. 

3) Xcode project Entitlements:
An entitlements file in this sample project includes the key "com.apple.developer.ubiquity-kvstore-identifier", where $(TeamIdentifierPrefix) is the Team ID found in the Provisioning Portal, and the rest is followed by your app's bundle identifier.

4) The bundle identifier defined on your Xcode project's Target > Info tab needs to match the App ID in the iCloud provisioning profile. This will allow you to assign the new profile to your Debug > Code Signing Identities in your Xcode project Target > Build Settings. 

So if your provisioning profile's App ID is "<your TeamID>.com.yourcompany.yourAppName", then the bundle identifier of your app must be "com.yourcompany.yourAppName".

5) Set your "Code Signing" identity in your Xcode project to match your particular App ID.


===========================================================================
TESTING YOUR DEVICES:

Once you have the application installed and running on the each device you intend to test, as you change the app's background color of one device, shortly after you will see the other device reflect that color change.

===========================================================================
BUILD REQUIREMENTS:

- Xcode 5.0, iOS 6.0 SDK or later.
- An explicit iCloud App ID setup in the iOS Provisioning Portal.
- A development provisioning profile using this iCloud App ID, installed into your Xcode Provisioning Profile Library.
- An entitlements file containing for your key-value store.

===========================================================================
RUNTIME REQUIREMENTS:

iOS 6.0 or later, an iCloud account, Automatic Reference Counting (ARC)

===========================================================================
CHANGES FROM PREVIOUS VERSIONS:

1.2 - Now uses Storyboard and AutoLayout, fixed resizing issues with front and back views.
1.1 - Upgraded for iOS 6.0, simplified view flipping (using transitionFromView), now using Automatic Reference Counting (ARC), updated to adopt current best practices for Objective-C.
1.0 - First version.

===========================================================================
Copyright (C) 2011-2013 Apple Inc. All rights reserved.
