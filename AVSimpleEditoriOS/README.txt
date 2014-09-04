### AVSimpleEditor ###

===========================================================================
DESCRIPTION:

A simple AV Foundation based movie editing application for iOS.
This sample is ARC-enabled.

===========================================================================
BUILD REQUIREMENTS:

iOS 6 SDK, ARC enabled. 

===========================================================================
RUNTIME REQUIREMENTS:

iOS 6.0 or later

===========================================================================
PACKAGING LIST:

AVSEViewController.m/h:
 The UIViewController subclass. This contains the view controller logic including playback.
AVSECommand.m/h:
 The abstract super class of all editing tools.
AVSETrimCommand/AVSERotateCommand/AVSECropCommand/AVSEAddMusicCommand/AVSEAddWatermarkCommand.m/h:
 The concrete subclasses of AVSECommand which implement different tools. 
AVSEViewController_iPad.xib:
 The viewController NIB. This contains the application UI.

===========================================================================
CHANGES FROM PREVIOUS VERSIONS:

Version 1.0
- First version.

===========================================================================
Copyright (C) 2012 Apple Inc. All rights reserved.
