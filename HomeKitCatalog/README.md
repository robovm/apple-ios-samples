Read Me - HomeKit Catalog
=========================
1.0

HomeKit Catalog demonstrates how to use the HomeKit API, to create homes, to associate accessories with homes, to associate accessories with homes, to group the accessories into rooms and zones, to create actions sets to tie together multiple actions, to create timer triggers to fire actions sets at specific times, and to create service groups to group services into contexts.

HomeKit Catalog requires Xcode 6.1.1 with the iOS 8.1 SDK to build the application. You can either run the sample code within the iOS Simulator or on a device with iOS 8.1 installed. You can use the HomeKit Accessory Simulator on OS X to simulate accessories on your local Wi-Fi network. For the Xcode 6.1.1 timeframe, the HomeKit Accessory Simulator is available from the Apple Developer site as part of the Hardware IO Tools disk image: <https://developer.apple.com/downloads/index.action>.

Using the Sample
----------------
To use the sample, you should have HomeKit accessories already associated with the current Wi-Fi network that your device is associated to. Alternatively, you can use the HomeKit Accessory Simulator running on your Mac to simulate the presence of a variety of HomeKit Accessories. When you launch the app, switch to the Configure tab to add new homes.

You may then select a home and perform the following actions:

1. Define the names of the rooms (Bedroom, Living Room, etc) in the home, define zones as a collection of rooms in the home (first floor), 
2. Define Action Sets (turn off Kitchen lights), 
3. Define Timer Triggers (turn off lights at 10PM),
4. Define Service Groups (subset of accessories in a room), and
5. Define other users who can control the accessories in your home.

Note: For information on using the HomeKit Accessory Simulator, please refer to the HomeKit Accessory Simulator Help under the Help menu.

Use the Configure tab to set up the home, associate accessories with each room, and to perform the actions described above. Use the Control button to control the accessories in the home.

Considerations
==============
HomeKit operates asynchronously. Frequently, you will have to defer some UI response until all operations associated with a particular action are finished. For example, when this sample wants to save a trigger, it must:

1. Create the trigger using
`-[HMTrigger initWithName:fireDate:timeZone:recurrence:recurrenceCalendar]`
2. Add the trigger to the home using `-[HMHome addTrigger:completionHandler:]`
3. Add all of the specified Action Sets individually using
`-[HMTrigger addActionSet:completionHandler]`
4. Update its name using `-[HMTrigger updateName:completionHandler]`
5. Enable it using `-[HMTrigger enable:completionHandler]`

This sample makes heavy use of `dispatch_group`s to ensure all actions are completed before confirming with UI.

This sample also includes many convenience functions implemented as categories on HomeKit classes, and provides a very basic, flexible UI that adapts based on HMCharacteristic metadata.

## Requirements

### Build

iOS 8.1 SDK

### Runtime

iOS 8.1 or later.

Building the sample
-------------------
The sample was built using Xcode 6.1.1 on OS X 10.10.1 using the iOS 8.1 SDK. Configuring the Xcode project requires a few additional steps in Xcode to get the application running with HomeKit capabilities.

1) Open the project in the Project navigator within Xcode and select the HMCatalog target. Set the Team on the General tab to the team associated with your developer account.

2) Change the Bundle Identifier.
 
With the project's General tab still open, update the Bundle Identifier value. The project's HMCatalog target ships with the value:
 
com.example.apple-samplecode.HMCatalog
 
You should modify the reverse DNS portion to match the format that you use:
 
com.yourdomain.HMCatalog

3) Below the Team setting, there will be a warning "No matching provisioning profiles found". Click on the "Fix Issues" button.

You will now be able to launch HMCatalog on the iOS Simulator, or on a device registered to the Team.


Credits and Version History
---------------------------
If you find any problems with this sample, please file a bug against it.

<http://developer.apple.com/bugreporter/>

1.0 (Dec 2014) First shipping version of this sample.

Apple Developer Technical Support
Core OS/Hardware


