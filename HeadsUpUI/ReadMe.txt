### HeadsUpUI ###

================================================================================
DESCRIPTION:

Demonstrates how to implement a Heads Up or HUD-like user interface over the app's primary view controller.  This essentially mimics the behavior of the MPMoviePlayerController's hovering controls for controlling movie playback.  Developers can refer to this sample for best practices in how to implement this translucent kind of interface complete with animation and timer support.

This sample implements a basic UIView for rendering the translucent appearance.  The app's primary UIViewController handles the control clicks on this UI as well as implements a NSTimer that automatically hides the controls after 3 seconds.  The sample uses block-based animation to achieve a fade-in and fade-out effect.

================================================================================
USING THE SAMPLE:

When launched tap anywhere on the screen.  The hover user interface will appear with a fade-in effect at your touch point.  You can then tap the forward or backward buttons.  If you do not tap them, the interface will automatically fade away after 5 seconds.

================================================================================
BUILD REQUIREMENTS:

iOS 6.0 SDK or later

================================================================================
RUNTIME REQUIREMENTS:

iOS 5.0 or later


================================================================================
PACKAGING LIST:

HeadsUpUIAppDelegate.{h,m}
    The application's delegate.
    
RootViewController.{h,m} 
    The main UIViewController. The parent view for the HoverView.
    
HoverView.{h,m} 
    The view hosting the translucent button tools: play/pause.

================================================================================
CHANGES FROM PREVIOUS VERSIONS:

Version 1.2
- Migrated to Storyboards and ARC.
- Upgraded to build with the iOS 6 SDK.

Version 1.1
- Upgraded project to build with the iOS 4.0 SDK.

Version 1.0
- First release.

================================================================================
Copyright (C) 2008-2013 Apple Inc. All rights reserved.