
### MoviePlayer ###

===========================================================================
DESCRIPTION:

Demonstrates how to use the Media Player Framework to play a movie in a custom view. The sample will play either a local movie file or a movie loaded from a network-based URL. The sample also contains code to configure the movie playback controls, scaling mode, background color, background view, application audio session and repeat mode when transitioning to and from movie playback.

The Media Player framework provides basic facilities for playing movie files. Within the Media Player framework, a MPMoviePlayerController object defines a movie player. You can use this class to play back movies stored in your application’s bundle directory or support directories. You can also use it to play movies loaded from a network-based URL. With iPhone OS version 3.0 or later, iPhone is capable of receiving streaming audio and video over HTTP from an ordinary web server.

Supported Formats

The MPMoviePlayerController class supports any movie or audio files that already play correctly on an iPod, iPhone or iPad. For movie files, this typically means files with the extensions .m4v, .mov, .mp4 and .3gp and using one of the supported compression standards. Here's a sampling of the supported formats for the iPhone 4, iPod Touch and iPad:

iPhone 4

H.264 video up to 720p, 30 frames per second, Main Profile level 3.1 with AAC-LC audio up to 160 Kbps, 48kHz, stereo audio in .m4v, .mp4, and .mov file formats; MPEG-4 video, up to 2.5 Mbps, 640 by 480 pixels, 30 frames per second, Simple Profile with AAC-LC audio up to 160 Kbps per channel, 48kHz, stereo audio in .m4v, .mp4, and .mov file formats; Motion JPEG (M-JPEG) up to 35 Mbps, 1280 by 720 pixels, 30 frames per second, audio in ulaw, PCM stereo audio in .avi file format

iPad

H.264 video up to 720p, 30 frames per second, Main Profile level 3.1 with AAC-LC audio up to 160 Kbps per channel, 48kHz, stereo audio in .m4v, .mp4, and .mov file formats; MPEG-4 video, up to 2.5 Mbps, 640 by 480 pixels, 30 frames per second, Simple Profile with AAC-LC audio up to 160 Kbps, 48kHz, stereo audio in .m4v, .mp4, and .mov file formats; Motion JPEG (M-JPEG) up to 35 Mbps, 1280 by 720 pixels, 30 frames per second, audio in ulaw, PCM stereo audio in .avi file format

iPod Touch (4th Generation)

H.264 video up to 720p, 30 frames per second, Main Profile level 3.1 with AAC-LC audio up to 160 Kbps, 48kHz, stereo audio in .m4v, .mp4, and .mov file formats

MPEG-4 video, up to 2.5 Mbps, 640 by 480 pixels, 30 frames per second, Simple Profile with AAC-LC audio up to 160 Kbps per channel, 48kHz, stereo audio in .m4v, .mp4, and .mov file formats

Motion JPEG (M-JPEG) up to 35 Mbps, 1280 by 720 pixels, 30 frames per second, audio in ulaw, PCM stereo audio in .avi file format

If you use the MPMoviePlayerController class to play audio files, it displays a QuickTime logo while the audio plays. For audio files, this class class supports AAC-LC audio at up to 48 kHz, and MP3 (MPEG-1 Audio Layer 3) up to 48 kHz, stereo audio.

Media Delivery

iPhone can display movie files delivered by any web server using HTTP protocols. Refer to your web server documentation to learn how to configure your web server for movie file delivery. This means movie files shared on a user's MobileMe iDisk can be displayed on iPhone.  See the Apple MobileMe website to learn how to share files with your MobileMe iDisk.

When a file is delivered over a network or downloaded over the Internet, the entire file is not available immediately, but a typical QuickTime movie can be played while it downloads. This is called progressive download, or Fast Start. It works because the movie atom is stored at the beginning of the file, so QuickTime knows how to interpret the movie sample data even before it arrives, and because the movie data is intelligently interleaved with respect to display time. 

It is also possible to create a movie file with the sample data stored first, followed by the movie data structure. This is not usually desirable, because the entire file must download before QuickTime can interpret the sample data. You can correct this kind of data inversion simply by opening the movie file in QuickTime and saving it as a new, self-contained file. QuickTime stores the movie data structure at the beginning of the file by default.

With iPhone 3.0 or later, iPhone is capable of receiving streaming audio and video over HTTP from an ordinary web server. Currently, the supported format is MPEG-2 transport streams containing H.264 video and HE-AAC audio. Audio-only streams can be either HE-AAC with ADTS headers, or MP3. In a typical configuration, a hardware encoder takes audio-video input and turns it into an MPEG-2 transport stream, which is then broken into a series of short media files by a software stream segmenter. The segmenter also creates and maintains an index file containing a list of the media files. 

The URL of the index file is published on the web server, which responds to file requests in the usual way. The client software reads the index, then requests the listed media files in order and displays them without any pauses or gaps between segments. Media segments are saved as .ts files (MPEG-2 streams) and index files are saved as .m3u8 files, an extension of the .m3u format used for MP3 playlists. For more information about streaming audio and video over HTTP for iPhone, see the "HTTP Live Streaming Overview" document which is available on the iPhone Developer Center.

Using the Application

After the application launches, press the Tab Bar labeled "Local" to go to the application screen to play the local movie file that is stored in the application bundle. Press the Play Movie button (or touch anywhere in the movie preview image) and the local movie file will play full-screen. When launched, notice the background color, playback controls and scaling mode. Touch anywhere on the movie during playback and the playback controls will show (unless you've turned them off via the "Settings" application). Also notice the custom overlay controls that are drawn on top of the movie. Touches anywhere on the overlay controls are handled specifically by the application, not by the movie player. 

Press the Tab Bar labeled "Streaming" go to the application view to play movies loaded from a network-based URL.  Enter a valid movie URL and press the Play Movie button to begin playback (Note: for MPEG-2 transport streams this would be the URL of the index file, for example http://media.example.com/mymedia/index.m3u8). Touch anywhere on the screen during playback to display the movie playback controls. Touch the screen again to make them go away.

Quit the application and go to the Springboard to launch the built-in "Settings" application. Scroll down and you will find a section for "MoviePlayer". Open it and from there you can set the background color, background image, playback controls, repeat mode, application audio setting and scaling mode. Quit Settings and return to MoviePlayer. Press the Play Movie button again and notice the above settings have changed. 

This sample offers an Xcode project already pre-configured to build your Settings bundle as a target. To customize your settings UI, change the Root.plist file.

===========================================================================
BUILD REQUIREMENTS:

Xcode 5.1, iOS SDK 7.1 or better

===========================================================================
RUNTIME REQUIREMENTS:

iPhone, iPad or iPod Touch running iOS 4.0 or better

===========================================================================
PACKAGING LIST:

MoviePlayerAppDelegate.h
MoviePlayerAppDelegate.m
A simple UIApplication delegate class that adds the MyMovieViewController view to the window as a subview. Instantiates a MPMoviePlayerController object and begins movie playback. 

MyMovieViewController.h
MyMovieViewController.m
A UIViewController controller subclass that implements a movie playback view. Uses a MyMovieController object to control playback of a movie.
Adds and removes an overlay view to the view hierarchy. Handles button presses to the 'Close Movie' button in the overlay view.
Adds and removes a background view to hide any underlying user interface controls when playing a movie. Gets user movie settings preferences by calling the MoviePlayerUserPref methods. Apply these settings to the movie with the MyMovieController movie object.
</abstract>

MyLocalMovieViewController.h
MyLocalMovieViewController.m
Subclass of MyMovieViewController. Gives a URL to a local movie stored in the app bundle. Implements a 'Play Movie' button for playback of a local movie. Also plays the local movie on touches to the UIImageView. 

MyStreamingMovieViewController.h
MyStreamingMovieViewController.m
A UIViewController controller subclass that loads the SecondView nib file that contains its view. Contains an action method that is called when the Play Movie button is tapped to play the movie. Provides a text edit control for the user to enter a movie URL. Overrides the inherited shouldAutorotateToInterfaceOrientation: method so that the view can respond to device rotation.

MyImageView.h
MyImageView.m
A UIImageView subclass that implements the UIResponder event-handling method touchesBegan: withEvent: in order to receive finger touch event messages. Any finger touch events in this view will start the movie playing.

MyOverlayViewController.h
MyOverlayViewController.m
A UIViewController controller subclass that implements an overlay view to display movie load state and playback state and a button to close the active movie. Contains an action method that is called when the 'Close Movie' button is pressed to close the movie.

MoviePlayerUserPrefs.h
MoviePlayerUserPrefs.m
Contains methods to get the application user preferences settings for the movie scaling mode, control style, background color, repeat mode, application audio session and background image.

MainWindow.xib
Interface Builder 'nib' file that defines the iPhone interface for the application: the main window, the view and other user interface items. Also contains the movie file used for playback, and the plist files defining the application movie playback settings.

SecondView.xib
Interface Builder 'nib' file that defines the iPhone interface for the streaming movie window, view, movie URL text edit control and other user interface items.

MainWindow-iPad.xib
Interface Builder 'nib' file that defines the iPad interface for the application: the main window, the view and other user interface items. Also contains the movie file used for playback, and the plist files defining the application movie playback settings.

SecondView-iPad.xib
Interface Builder 'nib' file that defines the iPad interface for the streaming movie window, view, movie URL text edit control and other user interface items.

main.m
Entry point for the application. Creates the application object and causes the event loop to start.

Root.plist
The scheme file for the settings bundle.

Movie.m4v
The movie file to be played.

===========================================================================
CHANGES FROM PREVIOUS VERSIONS:

1.0 - First Release
1.1 - Updated for and tested with iPhone OS 2.0. First public release.
1.2 - Added custom overlay controls that draw on top of the movie.
1.2.1 - Fixed dealloc method in MyMovieViewController.m 
1.3 - Added support for receiving streaming audio and video over HTTP.
1.4 - Update for Xcode 4, iOS 4.3.
1.5 - Update for Xcode 5.1, iOS 7.1, ARC, modern Objective-C syntax, and bug fix for missing root view controller.

===========================================================================
Copyright (C) 2008-2014 Apple Inc. All rights reserved.