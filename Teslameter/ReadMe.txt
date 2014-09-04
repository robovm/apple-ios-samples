### Teslameter ###

===========================================================================
DESCRIPTION:

This application implements a Teslameter, a magnetic field detector. It displays the raw x, y, and z magnetometer values, a plotted history of those values, and a computed magnitude (size or strength) of the magnetic field.

The use of the Core Location API for getting "heading" data is contained in the TeslameterViewController class. It creates a CLLocationManager object and uses it to get heading by invoking -[CLLocationManager startUpdatingHeading]. It implements the CLLocationManagerDelegate APIs for receiving heading and updates its user interface accordingly.

===========================================================================
BUILD REQUIREMENTS:

iOS SDK 7.0

===========================================================================
RUNTIME REQUIREMENTS:

iOS 6 or later.
Requires a device with a magnetometer.
This sample will run in the Simulator but only one magnetic measurement will be received.

===========================================================================
PACKAGING LIST:

AppDelegate:
The application delegate, adds the main view to the window and displays the window.

TeslameterViewController:
A view controller that manages the primary view within the application. It creates a CLLocationManager and turns on heading updates. As updates are received, it displays them in a graph, x, y, and z labels, and also computes the magnitude (size or strength) of the magnetic vector. The units for all values are microteslas.

GraphView:
A custom view for plotting history of x, y, and z magnetic values.

===========================================================================
CHANGES FROM PREVIOUS VERSIONS:

Version 1.3
- Upgraded for the iOS 7 SDK, adopts current best practices for Objective-C (including use of properties, autosynthesis, and literals), now uses Storyboards and ARC (Automatic Reference Counting).

Version 1.2
- Updated to work with iOS 4.0.

Version 1.1
- Minor post-WWDC clean-up

Version 1.0
- First version.

===========================================================================
Copyright (C) 2009-2014 Apple Inc. All rights reserved.
