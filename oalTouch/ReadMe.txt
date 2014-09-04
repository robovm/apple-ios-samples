oalTouch

===========================================================================
DESCRIPTION:

oalTouch demonstrates basic use of OpenAL, Audio File Services, Core Animation, and Core Graphics Services on the iPhone for manipulating sound in a spatial environment.

The code in oalTouch uses OpenAL to play an audio file containing uncompressed (PCM) audio data. The application uses Audio File Services to manage audio file data reading. The application also uses Audio Session Services to manage interruptions (as described in Core Audio Overview).

This application shows how to:

	* Set up the environment for OpenAL usage by creating oalDevice and oalContext objects.
	* Read data from an audio file using the ExtendedAudioFile API and attach into an OpenAL buffer object.
	* Create an OpenAL source object and attach a buffer object to it.
	* Manipulate various properties of OpenAL source and listener objects.
	* Use Core Animation layers to rotate and move image objects based on user input.
	* Use Audio Session Services to register an interruption callback.
	* Use Audio Session Services to set appropriate audio session categories for recording and playback.
	* Use Audio Session Services to pause playback upon receiving an interruption, and to then resume playback if the interruption ends.
	* Use UIAccelerometer Services to provide user input from device movement.
	* Use UISlider objects as switches.

oalTouch does not demonstrate how to play multiple source objects, nor does it provide more advanced OpenAL usage. 


===========================================================================
RELATED INFORMATION:

Core Audio Overview, June 2008


===========================================================================
SPECIAL CONSIDERATIONS:

oalTouch demonstrates use of the OpenAL framework for positional audio, and as such is best suited for a stereo listening environment (headphones, external speakers, etc.)


===========================================================================
BUILD REQUIREMENTS:

iOS 4.0 SDK


===========================================================================
RUNTIME REQUIREMENTS:

iPhone OS 3.2 and later


===========================================================================
PACKAGING LIST:

MyOpenALSupport.h

MyOpenALSupport.h provides helper functions for various common OpenAL-related tasks (opening files for data read, creating devices and context objects, etc.)

oalPlayback.h
oalPlayback.m

The oalPlayback class defines the audio playback object for the application. The object responds to and manages of the OpenAL environment


oalTouchAppDelegate.h
oalTouchAppDelegate.m

The oalTouchAppDelegate class defines the application delegate object, responsible for handling accelerometer input and adding the application's view to the application window.


oalSpatialView.h
oalSpatialView.m

The oalSpatialView class defines the view object, responsible for handling user interaction and displaying the representation of the OpenAL environment.

================================================================================
Copyright (C) 2008-2010 Apple Inc. All rights reserved.