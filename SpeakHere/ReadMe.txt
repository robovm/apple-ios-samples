SpeakHere

===========================================================================
DESCRIPTION:

SpeakHere demonstrates basic use of Audio Queue Services, Audio File Services, and Audio Session Services on the iPhone and iPod touch for recording and playing back audio.

The code in SpeakHere uses Audio File Services to create, record into, and read from a CAF (Core Audio Format) audio file containing uncompressed (PCM) audio data. The application uses Audio Queue Services to manage recording and playback. The application also uses Audio Session Services to manage interruptions and audio hardware route changes (as described in Core Audio Overview).

SpeakHere can record using any audio recording format supported on the iPhone or iPod touch. To set the recording format, modify the argument to the SetupAudioFormat call in AQRecorder.mm.

To test the application's interruption behavior, place a phone call to the device during recording or playback; then choose to ignore the phone call.

To test the application's audio hardware route change behavior, plug in or unplug a headset while playing back or recording.

This application shows how to:

	* Set up a linear PCM audio format.
	* Set up a compressed audio format.
	* Create a Core Audio Format (CAF) audio file and save it to an application's Documents directory.
	* Reuse an existing CAF file by overwriting it.
	* Read from a CAF file for playback.
	* Create and use recording (input) and playback (output) audio queue objects.
	* Define and use audio data and property data callbacks with audio queue objects.
	* Set playback gain for an audio queue object.
	* Stop recording in a way ensures that all audio data gets written to disk.
	* Stop playback when a sound file has finished playing.
	* Stop playback immediately when a user invokes a Stop method.
	* Enable audio level metering in an audio queue object.
	* Get average and peak audio levels from a running audio queue object.
	* Use audio format magic cookies with an audio queue object.
	* Use OpenGL to indicate average and peak recording and playback level.
	* Use Audio Session Services to register an interruption callback.
	* Use Audio Session Services to register property listener callback.
	* Use Audio Session Services to set appropriate audio session categories for recording and playback.
	* Use Audio Session Services to pause playback upon receiving an interruption, and to then resume playback if the interruption ends.
	* Use UIBarButtonItem objects as toggle buttons.

SpeakHere does not demonstrate how to record multiple files, nor does it provide a file picker. It always records into the same file, and plays back only that file.

===========================================================================
RELATED INFORMATION:

Core Audio Overview, June 2008
Audio Session Programming Guide, November 2008


===========================================================================
BUILD REQUIREMENTS:

iOS 4.0 SDK


===========================================================================
RUNTIME REQUIREMENTS:

iPhone OS 3.2 or later

===========================================================================
PACKAGING LIST:

SpeakHereAppDelegate.h
SpeakHereAppDelegate.m

The SpeakHereAppDelegate class defines the application delegate object, responsible for instantiating the application's view.

SpeakHereController.h
SpeakHereController.m

The SpeakHereController class manages the application state and handles notifications from the audio system

SpeakHereViewController.h
SpeakHereViewController.m

The SpeakHereViewController class acts as the applcation's view controller

AQLevelMeter.h
AQLevelMeter.mm

The AQLevelMeter class defines the level meter view for the applcation, displaying the metering data from an AudioQueue object

LevelMeter.h
LevelMeter.m

LevelMeter is a base metering class, providing simple functionality for displaying level data

GLLevelMeter.h
GLLevelMeter.m

GLLevelMeter is a subclass of LevelMeter that uses OpenGL for drawing

AQRecorder.h
AQRecorder.m

The AudioRecorder class defines a recording object for the application. The AudioRecorder object manages recording, calling Audio File Services to interact with the file system. 

AQPlayer.h
AQPlayer.m

The AudioPlayer class defines a playback object for the application. The AudioPlayer object manages playback, calling Audio File Services to interact with the file system. Also controls looping of file playback

===========================================================================
CHANGES FROM PREVIOUS VERSIONS:

Version 2.5. Upgraded project to build with the iOS 5.1 SDK, fixed minor bugs.

Version 2.0. Overhauled to use audio queue play and record code from the WWDC aqTouch sample. Metering view now uses OpenGL for graphics.

Version 1.2. Updated for and tested with iPhone OS 2.2.

This version supports recording using all supported iPhone OS audio formats, including:

	linear PCM
	ALAC (Apple Lossless)
	IMA4 (IMA/ADPCM)
	iLBC
	µLaw
	aLaw

This version can play all audio playback formats supported in iPhone OS.

This version also fixes a crashing bug that appeared when guard malloc was enabled. The crash happened because, when tapping Stop during playback, a message was being sent to the playback audio queue object after it had been deallocated. The solution involved the following changes:

AudioPlayer.m
----------------
	Changed propertyListenerCallback to delay the message that triggers destruction of the AudioPlayer object until the run loop has completed.

AudioViewController.m
--------------------------
	Changed updateUserInterfaceOnAudioQueueStateChange (a delegation method) to release the AudioPlayer only in the case of the sound file having reached the end.
	Changed playOrStop:, which responds to the user tapping Stop to stop playback, to release the AudioPlayer after it has finished stopping.

 
================================================================================
Copyright (C) 2008-2012 Apple Inc. All rights reserved.