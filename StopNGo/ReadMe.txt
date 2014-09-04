### StopNGo ###

===========================================================================
DESCRIPTION:

StopNGo is a simple stop-motion animation QuickTime movie recorder that uses AVFoundation.

It creates a AVCaptureSession, AVCaptureDevice, AVCaptureVideoPreviewLayer, and AVCaptureStillImageOutput to preview and capture still images from a video capture device, then re-times each sample buffer to a frame rate of 5 fps and writes frames to disk using AVAssetWriter.

A frame rate of 5 fps means that 5 still images will result in a 1 second long movie. This value is hard coded in the sample but may be changed as required by the developer.

===========================================================================
BUILD REQUIREMENTS:

Xcode 4.2 or later; iPhone iOS SDK 5.0 or later.

===========================================================================
RUNTIME REQUIREMENTS:

iOS 5.0 or later. This app will not produce camera output on the iOS simulator.

===========================================================================
CHANGES FROM PREVIOUS VERSIONS:

Version 1.0 First version.

===========================================================================
Copyright (C) 2011 Apple Inc. All rights reserved.