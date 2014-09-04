### RosyWriter ###

===========================================================================
DESCRIPTION:

RosyWriter demonstrates the use of the AV Foundation framework to capture, process, preview, and save video on iOS devices. 

When RosyWriter launches, it creates an AVCaptureSession with audio and video device inputs, and outputs for audio and video data. These outputs continuously supply frames of audio and video to the app, via the captureOutput:didOutputSampleBuffer:fromConnection: delegate method.

The app applies a very simple processing step to each video frame. Specifically, it sets the green element of each pixel to zero, which gives the entire frame a purple tint. Audio frames are not processed.

After a frame of video is processed, RosyWriter uses OpenGL ES 2 to display it on the screen. This step uses the CVOpenGLESTextureCache API, new in iOS 5, for enhanced performance.

When the user chooses to record a movie, an AVAssetWriter is used to write the processed video and un-processed audio to a QuickTime movie file.

===========================================================================
BUILD REQUIREMENTS:

Xcode 4 or later; iPhone iOS SDK 5.0 or later.

===========================================================================
RUNTIME REQUIREMENTS:

iOS 5.0 or later. This app will not run on the iOS simulator.

===========================================================================
CHANGES FROM PREVIOUS VERSIONS:

Version 1.2
Corrected code for calculating the center of the preview view. Removed some unnecessary setNeedsDisplay calls.

Version 1.1
First public release.

===========================================================================
Copyright (C) 2011 Apple Inc. All rights reserved.
