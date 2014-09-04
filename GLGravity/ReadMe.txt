### GLGravity ###

===========================================================================
DESCRIPTION:

The GLGravity sample application demonstrates how to use the UIAccelerometer class in combination with OpenGL rendering. It shows how to extract the gravity vector from the accelerometer values using a basic low-pass filter, and how to build an OpenGL transformation matrix from it. Note that the result is not fully defined, as rotation of the device around the gravity vector cannot be detected by the accelerometer.

This application is designed to run on a device, not in the iPhone Simulator. Rotate the device and observe how the teapot always stays upright, independent of the device orientation.

===========================================================================
BUILD REQUIREMENTS:

iOS 4.0 SDK

===========================================================================
RUNTIME REQUIREMENTS:

iOS 3.2 or later

===========================================================================
PACKAGING LIST:

Classes/GLGravityAppDelegate.h
Classes/GLGravityAppDelegate.m
The GLGravityAppDelegate class is the app delegate that ties everything together. It updates the acceletometer values used to draw OpenGL content in the GLGravityView class.

Classes/GLGravityView.h
Classes/GLGravityView.m
The GLGravityView wraps the CAEAGLLayer from CoreAnimation into a convenient UIView subclass. The view content is basically an EAGL surface you render your OpenGL scene into. 

Models/teapot.h
Contains data necessary for rendering the teapot model.

main.m
Entry point for this application.

===========================================================================
CHANGES FROM PREVIOUS VERSIONS:

Version 2.2
- Upgraded project to build with the iOS 4.0 SDK.

Version 2.1
- Updated for iPhone OS 3.1. Use CADisplayLink as the preferred method for controlling animation timing, and fall back to NSTimer when running on a pre 3.1 device where CADisplayLink is not available.
- Made the sample xib-based.

Version 2.0
- First Public Release.

Version 1.4
- Updated for Beta 5

Version 1.3
- Updated for Beta 4
- Updated build settings
- Updated ReadMe file and converted it to plain text format for viewing on website

Version 1.2
- Updated for Beta 3
- Added an icon and a Default.png file

Version 1.1
- Updated for Beta 2	

===========================================================================
Copyright (C) 2009-2010 Apple Inc. All rights reserved.