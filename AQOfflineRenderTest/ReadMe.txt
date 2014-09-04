AQOfflineRenderTest

===========================================================================
DESCRIPTION:

AQOfflineRenderTest demonstrates the use of the AudioQueueOfflineRender API.

All the relevant code is in the file aqofflinerender.cpp.

Touching the "Start" button simply calls the function DoAQOfflineRender() producing LPCM output buffers from an ALAC encoded source file. These buffers are then written to a .caf file which is played back after rendering using AVAudioPlayer to confirm success.
 
===========================================================================
RELATED INFORMATION:

Core Audio Overview
Audio Queue Programming Guide
Audio Queue Services Reference

===========================================================================
SPECIAL CONSIDERATIONS:

See Technical Q&A QA1562 - Audio Queue - Offline Rendering

===========================================================================
BUILD REQUIREMENTS:

iOS 4.0 SDK


===========================================================================
RUNTIME REQUIREMENTS:

iPhone OS 3.2 or later


===========================================================================
PACKAGING LIST:

AQOfflineRenderTestAppDelegate.h
AQOfflineRenderTestAppDelegate.m

The AQOfflineRenderTestAppDelegate class defines the application delegate object, responsible for adding the navigation controllers view to the application window.

MyViewController.h
MyViewController.m

The MyViewController class defines the controller object for the application. The object helps set up the user interface, responds to and manages user interaction, and implements sound playback.

qofflinerender.cpp

This file implements the DoAQOfflineRender function which is called on a background thread from the MyViewController class.

All the code demonstrating how to perform offline render is contained in this one file, the rest of the sample can be thought of as a simple framework for the demonstration code in this file.

===========================================================================
CHANGES FROM PREVIOUS VERSIONS:

Version 1.2, added CFBundleIconFiles in Info.plist.
Version 1.1, upgraded project to build with the iOS 4.0 SDK.
Version 1.0, tested with iPhone OS 2.2.1. First public release.


================================================================================
Copyright (C) 2009-2010 Apple Inc. All rights reserved.