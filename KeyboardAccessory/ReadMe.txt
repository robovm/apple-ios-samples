### KeyboardAccessory ###

===========================================================================
DESCRIPTION:

This sample shows how to use a keyboard accessory view.

The application uses a single view controller. The view controller's view contains a UITextView. When you tap the text view, the view controller loads a nib file containing an accessory view that it assigns to the text view's inputAccessoryView property. The accessory view contains a button. When you tap the button, the text "You tapped me." is added to the text view. The sample also shows how you can use the keyboard-will-show and keyboard-will-hide notifications to animate resizing a view that is obscured by the keyboard.

===========================================================================
BUILD REQUIREMENTS:

iOS 6.0 SDK

===========================================================================
RUNTIME REQUIREMENTS:

iOS 7.0 or later

===========================================================================
PACKAGING LIST:

KeyboardAccessoryAppDelegate.{h,m}
A simple application delegate that displays the application's window. 

ViewController.{h,m}
A view controller that adds a keyboard accessory to a text view.

MainStoryboard
The storyboard file containing the main view controller and keyboard accessory view.

===========================================================================
CHANGES FROM PREVIOUS VERSIONS:

1.5 - Upgraded to use Auto Layout.
1.4 - Upgraded for iOS 6.0, now using Automatic Reference Counting (ARC) and storyboards, updated to adopt current best practices for Objective-C, sample is now Universal (supports iPhone/iPod touch and iPad).
1.3 - viewDidUnload now releases IBOutlets, added localization support.
1.2 - Updated to use new keyboard notification constants.
1.0 - First version.

===========================================================================
Copyright (C) 2010-2014 Apple Inc. All rights reserved.
