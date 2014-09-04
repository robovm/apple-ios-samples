SysSound

===========================================================================
DESCRIPTION:

SysSound demonstrates basic use of System Sound Services (declared in AudioToolbox/AudioServices.h) for playing short sounds and invoking vibration.


     NOTE: System Sound Services is intended for user-interface 
	 sound effects and user alerts. It is not intended for sound 
	 effects in games. For game sound playback, or for any 
	 playback needs beyond user-interface sound effects and 
	 alerts, use OpenAL, the AVAudioPlayer class, Audio Queue 
	 Services, or audio units.
	 
	 NOTE: There are no built-in sounds or alerts available in 
	 iOS 4.0. When using System Sound Services, provide your own 
	 sound files.


The code in this sample project includes three playback methods.

* The -playSystemSound: method uses the AudioServicesPlaySystemSound function to play a system sound in response to a button tap.

* The -playAlertSound: method uses the AudioServicesPlayAlertSound function to play the same system sound, but as an alert. On devices that include a vibration element, this function simultaneously invokes vibration if the user has configured the "Ring" settings to include vibration. On other iOS devices, this function plays an alert melody in lieu of the specified sound file.

* The -vibrate: method uses the AudioServicesPlaySystemSound function to explicitly invoke vibration on the device in response to a button tap. It does this by passing the vibration constant rather than a system sound object. 

To create a system sound object for playback,  first create a CFURLRef object that points to the sound file you want to play. SysSound shows how to do this and also demonstrates where in the file system you should place sound files.

SysSound does not demonstrate using system sound object properties or how to use the sound completion callback.

 
===========================================================================
RELATED INFORMATION:

To learn about System Sound Services, including important information on its lack of participation with the audio session API, refer to the following documents:

Multimedia Programming Guide, May 2010
System Sound Services Reference, October 2009

For an example of how to play sounds other than user-interface sound effects and alerts, see the following sample code project:

avTouch


===========================================================================
SPECIAL CONSIDERATIONS:

iOS ignores the vibration constant when running on devices that do not have a vibration element. For example, calling the AudioServicesPlaySystemSound function with the vibration constant on an iPod touch does nothing.

In the Simulator, clicking the Vibrate button in the application's user interface does nothing.


===========================================================================
BUILD REQUIREMENTS:

Mac OS X v10.6.4, Xcode 3.2, iOS 4.0 or later


===========================================================================
RUNTIME REQUIREMENTS:

Simulator: Mac OS X v10.5.4 or later
Device:    iOS 4.0 or later


===========================================================================
PACKAGING LIST:

SysSoundAppDelegate.h
SysSoundAppDelegate.m

The SysSoundAppDelegate class defines the application delegate object, responsible for instantiating the controller object (defined in the SysSoundViewController class) and adding the application's view to the application window.

SysSoundViewController.h
SysSoundViewController.m

The SysSoundViewController class defines the controller object for the application. The object helps set up the user interface, responds to and manages user interaction, and implements sound playback and vibration.


===========================================================================
CHANGES FROM PREVIOUS VERSIONS:

Version 1.1, Upgraded project to build with the iOS 4.0 SDK. Other minor corrections and changes.

Version 1.0, tested with iOS 2.1. Minor changes to project files.


================================================================================
Copyright (C) 2010 Apple Inc. All rights reserved.