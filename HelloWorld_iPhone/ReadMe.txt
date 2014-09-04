### HelloWorld ###

================================================================================
DESCRIPTION:

HelloWorld is a sample application that demonstrates the use of a text field to enter text using a keyboard, and a text label to display text.

HelloWorld presents a simple interface. When the application launches, it displays a navigation bar containing a text field. Tap on the text field to enter your name. Tap the Done button on the keyboard to dismiss the keyboard. The application then displays in a label what you typed in the text field.

The basic features of the application are discussed in more detail in "Your First iPhone Application" in the Reference Library <http://developer.apple.com/iphone/library/documentation/iPhone/Conceptual/iPhone101/>.

================================================================================
BUILD REQUIREMENTS:

iOS 4.0 SDK

================================================================================
RUNTIME REQUIREMENTS:

iPhone OS 3.2 or later

================================================================================

PACKAGING LIST
HelloWorldAppDelegate.m
HelloWorldAppDelegate.h
The UIApplication object's delegate. On start up, this object receives the applicationDidFinishLaunching: delegate message; this creates a view controller and sets the window's view to the view controller's view.

MyViewController.m
MyViewController.h
A view controller that loads the HelloWorld nib file that contains its view.

MainWindow.xib
The nib file containing the main window.

HelloWorld.xib
The view controller's nib file.


================================================================================
CHANGES FROM PREVIOUS VERSIONS:

Version 1.8
- Upgraded project to build with the iOS 4.0 SDK.

Version 1.7
- Updated for and tested with iPhone OS 2.0. First public release.

Version 1.6
- Updated for Beta 7.

Version 1.5
- Updated for Beta 6.
- Updated the user interface to match Human Interface Guidelines.
- Tapping on the view outside the text field dismisses the keyboard.

Version 1.4
- Updated for Beta 5.
- Made minor changes to project file -- added ReadMe, removed project-level override for ALWAYS_SEARCH_USER_PATHS, added override at target level.
- Renamed -sayHello: to changeGreeting: to clarify effect.
- Removed Visible At Launch flag from window in MainWindow.xib; added [window makeKeyAndVisible] in application delegate.

Version 1.3
- Updated for Beta 4.
- Uses a nib file to create the user interface -- most of the application code is replaced.
- Uses a view controller to set up the view.

Version 1.2
	Replaced the background default.png images with ones that do not have a custom text field drawn on them.
Version 1.1
	Added pointer to the iPhone Reference Library.
	Return key on keyboard now functions.

Copyright (c) 2008-2010 Apple Inc. All rights reserved.