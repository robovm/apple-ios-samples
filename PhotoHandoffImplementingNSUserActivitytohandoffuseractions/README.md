# PhotoHandoff: Implementing NSUserActivity to hand off user actions

Demonstrates how to use Handoﬀ technology. Handoff uses NSUserActivity class which encapsulates the state of a user activity in an application on a particular device, in a way that allows the same activity to be continued on another device.

The sample is based on “CollectionView-Simple” sample, and is universal - running on both iPhone and iPad.

### Requirements

- Two iOS devices
- An iCloud account
- Bluetooth connection


### Setup For Both Sevices -

- Enable Handoff: go to Settings application, General section, Handoff and Suggested Apps - turn on Handoff
- Enable Bluetooth: go to Settings application, Bluetooth section - turn on Bluetooth
- Enable iCloud: go to Settings application, iCloud section - log in using the same iCloud account


### Instructions

This sample shows how to hand off the user activity of choosing a photo for editing. On device #1, open the sample and tap a photo. On device #2, from its lock screen you will notice the app’s icon appear to the lower left. Swipe that icon in an upward direction. As a result same photo chosen on device #1 then will open on the device #2 for editing.  The user may apply blur and sepia-intensity filtering which is also continued as part of the activity to the other device.  In addition, UIStateRestoration feature is implemented, remembering the last photos edited along with the filter values.


### Build

iOS 8.0 SDK


### Runtime

iOS 8.0 or later


Copyright (C) 2014 Apple Inc. All rights reserved.
