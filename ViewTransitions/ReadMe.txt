### ViewTransitions ###

================================================================================
DESCRIPTION:
The ViewTransitions sample application demonstrates how to perform transitions between two views using UIView's animation API.

To try out the sample, build it using Xcode and run it in the simulator or on the device. Click the 'Dissolve', 'Flip' or 'bounce' buttons to perform a transition from one image to another.

================================================================================
BUILD REQUIREMENTS:

Xcode 5.0, iOS 7.0 SDK

================================================================================
RUNTIME REQUIREMENTS:

iOS 6.x or later, Automatic Reference Counting (ARC)

================================================================================
CHANGES FROM PREVIOUS VERSIONS:

Version 1.12
- Upgraded for iOS 7.0, now shows how to use animateWithDuration API using a timing curve described by the motion of a spring.

Version 1.11
- Upgraded to use UIView's "transitionFromView" API, now uses Storyboards and ARC.

Version 1.9
- Added CFBundleIconFiles in Info.plist.

Version 1.8
- Upgraded project to build with the iOS 4.0 SDK.

Version 1.7
- Eliminated the TransitionView class. The code for creating and adding the transition is now in -performTransition in the ViewTransitionsAppDelegate. Now requires the iPhone 3.0 SDK.

Version 1.6
- Updated for and tested with iPhone OS 2.0. First public release.

Version 1.5
- Updated for Beta 6.
- Added LSRequiresIPhoneOS key to Info.plist

Version 1.4
- Updated for Beta 5.
- Added a button to start the transition.
- Updated to use a nib file.

Version 1.3
- Updated for Beta 4.
- Added code signing.

Version 1.2
- Updated for Beta 3.
- Added icon.

Version 1.1
- Updated for Beta 2.

================================================================================
Copyright (C) 2008-2013 Apple Inc. All rights reserved.