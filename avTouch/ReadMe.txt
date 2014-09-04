avTouch

===========================================================================
DESCRIPTION:

The avTouch sample demonstrates use of the AV Foundation framework for basic playback of an audio file.

The code in avTouch uses AVFoundation to play an audio file containing AAC audio data. The application uses CoreGraphics and OpenGL to display volume meters for the audio being played.

This application shows how to:

	* Create an AVAudioPlayer object from an input audio file.
	* Use OpenGL and CoreGraphics to display metering levels.
	* Use Audio Session Services to set an appropriate audio session category for playback.
	* Use AVFoundation's interruption delegate to pause playback upon receiving an interruption, and to then resume playback if the interruption ends.

avTouch does not demonstrate how to play multiple files, nor does it provide more advanced AVFoundation usage. 


===========================================================================
RELATED INFORMATION:

AV Foundation Framework Reference, April 2010
Multimedia Programming Guide, April 2010

===========================================================================
SPECIAL CONSIDERATIONS:

none

===========================================================================
BUILD REQUIREMENTS:

Mac OS X v10.9, Xcode 5, iOS 7.0 and later


===========================================================================
RUNTIME REQUIREMENTS:

Simulator: Mac OS X v10.9, iOS SDK 7.0 and later
iPhone: iOS 7.0


===========================================================================
PACKAGING LIST:

avTouchController.h
avTouchController.mm

The avTouchController defines the main controller class, responsible for managing the AVAudioPlayer object and handling user input

CALevelMeter.h
CALevelMeter.mm

The CALevelMeter class defines the level meter view for the applcation, displaying the metering data from an AVAudioPlayer object

LevelMeter.h
LevelMeter.m

LevelMeter is a base metering class, providing simple functionality for displaying level data

GLLevelMeter.h
GLLevelMeter.m

GLLevelMeter is a subclass of LevelMeter that uses OpenGL for drawing

avTouchAppDelegate.h
avTouchAppDelegate.m

The avTouchAppDelegate class defines the application delegate object, responsible for adding the application's view to the application window.

avTouchViewController.h
avTouchViewController.m

The avTouchViewController class defines the view controller, responsible for handling rotations

================================================================================
Copyright (C) 2010-2014 Apple Inc. All rights reserved.