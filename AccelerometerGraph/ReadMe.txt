
### AccelerometerGraph ###

===========================================================================
DESCRIPTION:

AccelerometerGraph sample application graphs the motion of the device. It demonstrates how to use the UIAccelerometer class and how to use Quartz2D and Core Animation to provide a high performance graph view. It also demonstrates a low-pass filter that you can use to isolate the effects of gravity, and a high-pass filter that you can use to remove the effects of gravity.

Run this sample on the device to learn how the accelerometer behaves when moving the device. The simulator does not simulate the accelerometer hardware, so you will not see any updates to the graph there. Use the controls provided to pause and resume updates, and to select a low pass or high pass filter, and to enable or disable adaptive filtering.

===========================================================================
BUILD REQUIREMENTS:

iOS 6.0 SDK or later

===========================================================================
RUNTIME REQUIREMENTS:

iOS 5.0 or later

===========================================================================
PACKAGING LIST:

AppDelegate.h/m
The application delegate class, responsible for application events and for bringing up the user interface.

AccelerometerFilter.h/m
Implements a low and high pass filter with optional adaptive filtering.

GraphView.h/m
This class is responsible for updating and drawing the accelerometer history of values. This class uses Core Animation directly to control what parts of the graph are updated by drawing and what parts can be updated strictly by animation.

MainViewController.h/m
The view controller loaded by the application delegate that is responsible for handling user events, selecting the correct filter, and passing accelerometer data through the filter and into the GraphView.

main.m
Entry point for the application. Creates the application object, sets its delegate, and causes the event loop to start.

===========================================================================
CHANGES FROM PREVIOUS VERSIONS:

Version 2.6
- Upgraded for iOS 6.0, now using Automatic Reference Counting (ARC), updated to adopt current best practices for Objective-C.

Version 2.5
- Added CFBundleIconFiles in Info.plist.

Version 2.4
- Upgraded project to build with the iOS 4.0 SDK.

Version 2.1
- Enhanced the accessibility of the app by effectively using the iPhone Accessibility API.

Version 2.0
- Rewrote the GraphView class to drastically improve performance. Implementation is considerably different from previous versions.
- Refactored to use a view controller rather than doing similar work in the AppDelegate.
- Refactored to separate filters from display.
- Can now select either a low-pass or high-pass filter.
- Can now set the filter for an adaptive mode that causes the filter to converge to the new output value much faster

Version 1.7
- Updated for and tested with iPhone OS 2.0. First public release.
- Simplified updating of drawing by eliminating the NSTimer previously used to mark the view as needing to be redrawn. In this new version, the view is marked whenever new data arrives from the accelerometer.

Version 1.6
- Now use fixed-width buttons in UI.
- Modified update frequency to smooth animations. 

Version 1.5
- Removed underscore prefixes on ivars to match sample code guidelines.
- Updated for Beta 6. 

Version 1.4 
- Updated for Beta 5. 

Version 1.3 
- Updated build settings.
- Updated ReadMe file and converted it to plain text format for viewing on website. 

Version 1.2 
- Updated ReadMe file. 
- Added an icon and a default.png file.

===========================================================================
Copyright (C) 2008-2013 Apple Inc. All rights reserved.
