AddMusic

=========================================================================
DESCRIPTION:

AddMusic demonstrates basic use of iPod library access, part of the Media Player framework. Use iPod library access to play songs, audio books, and audio podcasts that are synced from a user's desktop iTunes library. This sample uses the Media Player framework's built-in user interface for choosing music.

AddMusic also demonstrates how to mix application audio with iPod library audio. The sample includes code that configures application audio behavior using the AVAudioSession class and Audio Session Services.

The sample's Settings bundle lets you configure one runtime option using the built-in Settings application. You can specify that AddMusic use the iPod music player, which shares state with the built-in iPod application; or the application music player, whose state is independent of the built-in iPod application.

The sample includes code to handle interruptions and audio hardware route changes for application audio. The system handles these things automatically for sounds played by the application using iPod library access.

To test interruption behavior, use the built-in Clock application. Set an alarm that will sound during playback. At the time the alarm will sound, ensure that iPod audio or application audio (or both) is playing, depending on which behavior you want to test. When the alarm sounds, dismiss it.

To test audio hardware route change behavior, plug in or unplug a headset during playback. There's an alert that appears only when application audio is playing and you unplug the headset. When only iPod audio is playing and you unplug the headset, the system pauses iPod playback.

The sample is internationalized. See the Localized.strings file in the project's Resources/en.lproj folder.

AddMusic shows how to:

	* Instantiate the iPod music player and the application music player.
	* Display and dismiss the media item picker.
	* Get media items chosen by the user.
	* Set a music player's playback queue.
	* Display metadata of music chosen by the user, including song title, artist name, and artwork.
	* Register for, and handle, music player notifications.

As part of showing how to mix application sound with iPod library sound, this sample application also shows how to:

	* Play audio using AV Foundation
	* Configure and use the application's audio session

AddMusic does not demonstrate how to perform media queries.


=========================================================================
RELATED INFORMATION:

iPod Library Access Guide, September 2009
Media Player Framework Reference, September 2009
Core Audio Overview, November 2008
Audio Session Programming Guide, September 2009
AV Foundation Framework Reference, September 2009


=========================================================================
BUILD REQUIREMENTS:

Mac OS X v10.5.7, Xcode 3.1, iPhone OS 3.0


=========================================================================
RUNTIME REQUIREMENTS:

iPhone: iPhone OS 3.0
iPod library access is not functional in the Simulator.


=========================================================================
PACKAGING LIST:

AddMusicAppDelegate.h
AddMusicAppDelegate.m

The AddMusicAppDelegate class defines the application delegate object, responsible for instantiating the main controller object (defined in the MainViewController class) and adding the application's main view to the application window.


MainViewController.h
MainViewController.m

The MainViewController class defines the controller object for the application. The object helps set up the user interface, responds to and manages user interaction, responds to changes in the state of the muaic player, handles interruptions to the application's audio session, and handles various housekeeping duties.


MusicTableViewController.h
MusicTableViewController.m

The MusicTableViewController class defines the controller object for a table that displays titles of media items chosen by the user. It provides no manipulation of the media items.


=========================================================================
CHANGES FROM PREVIOUS VERSIONS:

Version 1.1.1. Minor changes.

Version 1.1. Improved the audio hardware route change callback function. Improved text of ReadMe file.

Version 1.0. First version.

 
=========================================================================
Copyright (C) 2009 Apple Inc.  All rights reserved.