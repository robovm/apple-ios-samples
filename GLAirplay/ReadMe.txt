### GLAirplay ###

===================================================================================================
DESCRIPTION:

Demonstrates how to provide a richer experience to your users when they are using Airplay by 
displaying your UI on the iPhone/iPad and your app/game contents on the second display. 

When AirPlay Mirroring is enabled, by default the same image appears on the screen of the host 
device and the external display. This sample demonstrates how to use the second display 
independently by showing separate content on each display. The sample includes a simple OpenGL ES 
view which renders a rotating cube and lets you change the cube's rotating radius using a slider. 
When there is no second display, both the slider and the OpenGL ES object are displayed on the iOS 
device's display; when a second display is activated, only the UI appears on the host device's 
display while the external display is used to show the OpenGL ES content. The sample uses OpenAL 
for 3D sound playback.

To learn more about enabling AirPlay Mirroring see:

http://support.apple.com/kb/ht5209

===================================================================================================
BUILD REQUIREMENTS:

iOS 6.0 SDK or later

===================================================================================================
RUNTIME REQUIREMENTS:

iOS 6.0 or later

===================================================================================================
PACKAGING LIST:

main.m - Main entry point for this sample.

AppDelegate.h/.m - The application's delegate.

MainViewController.h/.m - The root view controller. Demonstrates detailed steps on how to show 
content on an external display.

UserInterfaceViewController.h/.m - This UIViewController configures the appearances of the UI 
when an external display is connected/disconnected.

GLViewController.h/.m - This UIViewController configures the OpenGL ES view and its UI when an 
external display is connected/disconnected.

GLView.h/.m - The OpenGL ES view which renders a rotating cube. Responsible for creating a 
CADisplayLink for the new target display when a connection/disconnection occurs.

UserControlDelegate.h/.m - The object that conforms to this UserControlDelegate protocol is 
responsible for setting the GL cube's rotating radius.

CubePlayback.h/.m - An Obj-C class which wraps an OpenAL playback environment.

MyOpenALSupport.h - OpenAL-related support functions.

===================================================================================================
CHANGES FROM PREVIOUS VERSIONS:

Version 1.0
- First version.

===================================================================================================
Copyright (C) 2013 Apple Inc. All rights reserved.


