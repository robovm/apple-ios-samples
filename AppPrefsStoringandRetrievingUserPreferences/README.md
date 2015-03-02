# AppPrefs: Storing and Retrieving User Preferences #

This sample demonstrates how to display your app's user configurable options (preferences) in the "Settings" system application.  A settings bundle, included in your application’s bundle directory, contains the information needed by the Settings application to display your preferences and make it possible for the user to modify them.  The Settings application saves any configured values in the defaults database so that your application can retrieve them at runtime. 

This sample also shows how to launch the Settings app from your application and how to dynamically update your application's UI when its settings are changed while the app is in the background.

### USING THE SAMPLE: ###

Launch the AppPrefs project using Xcode.
Make sure the project's current target is set to "AppPrefs".
Build and run the "AppPrefs" target.

When launched notice the text, and its color. Tap the "Settings" button to launch the Settings application.  At the end of the settings list you will find a section for "AppPrefs".  From there you can set the first and last name, and the text color. Switch back to AppPrefs and notice the settings have changed.

### FURTHER INFORMATION: ###

For more information on extending the Settings application, refer to the "Preferences and Settings Programming Guide" and the "Settings Application Schema Reference".


REQUIREMENTS
--------------------------------------------------------------------------------

### BUILD ###
iOS 8.0 SDK or later

### RUNTIME ###
iOS 6.0 or later


CHANGES FROM PREVIOUS VERSIONS:
--------------------------------------------------------------------------------

+ Version 1.7
  - Upgraded for iOS 8.
  - Demonstrates launching the Settings app from your application.

+ Version 1.6
  - Demonstrates extracting and registering the default values for all settings defined in the Settings bundle.
  - Adopted Storyboards and ARC.
  - Adopted the latest Objective-C conventions and best practices.
  - Upgraded to build against the iOS 6 SDK.
  - Deployment target set to iOS 5.

+ Version 1.5
  - Deployment target set to iPhone OS 3.2.

+ Version 1.4
  - Upgraded project to build with the iOS 4 SDK
  - Fixed static analyzer warning. 
  - Added support for "NSUserDefaultsDidChangeNotification".

+ Version 1.3 
  - More use of nibs
  - Upgraded for 3.0 SDK due to deprecated APIs
  - In "cellForRowAtIndexPath" it now uses UITableViewCell's initWithStyle
  - Settings.bundle no longer builds as a separate Xcode target.

+ Version 1.2 
  - Updated Read Me

+ Version 1.1 
  - Updated for and tested with iPhone OS 2.0. 
  - First public release.

+ Version 1.0 
  - First release


================================================================================
Copyright (C) 2008-2014 Apple Inc. All rights reserved.
