
ManagedAppConfig
================


This sample demonstrates how to add managed app configuration and feedback support to an iOS application. Managed app configuration allows a Mobile Device Management (MDM) server to set a dictionary in the managed app’s NSUserDefaults to configure the app. Feedback such as critical errors can also be written by the app into its NSUserDefaults, so that it can be queried by an MDM server. This powerful mechanism allows enterprises and educational institutions to better manage applications from an MDM server.

This sample app demonstrates how to write an app that supports configuration of two values:

* Server URL
* Cloud document switch

and provides feedback for two values:

* Success count
* Failure count


Special Considerations
----------------------

This project includes a configuration plist named "ManagedAppConfig.plist". This file contains a dictionary that an MDM server can send to the sample app to set the server URL and cloud document switch values. Use this as a reference when trying out the sample app with an MDM server.

This project also includes a feedback plist named "AppFeedback.plist". This file is an example of the feedback data returned from the ManagedAppConfig app running on the iOS device after a ManagedApplicationFeedback command is issued by an MDM server.

To test app configuration and feedback using this sample application, the following must be true:

* Testing must be done on an iOS device that is managed by an MDM server
* The application binary must be installed on the device by the MDM server
* The MDM server must support the ApplicationConfiguration setting and ManagedApplicationFeedback commands


Related Information
-------------------

See the WWDC 2013 Session 301 "Extending Your Apps for Enterprise and Education Use" for a demo of this application.


----
Copyright (C) 2010-2013 Apple Inc. All rights reserved.
