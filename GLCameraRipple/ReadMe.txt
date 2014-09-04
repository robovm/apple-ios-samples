GLCameraRipple
 
================================================================================
DESCRIPTION:
 
This sample demonstrates how to use the AVFoundation framework to capture YUV
frames from the camera and process them using shaders in OpenGL ES 2.0.
CVOpenGLESTextureCache, which is new to iOS 5.0, is used to provide optimal
performance when using the AVCaptureOutput as an OpenGL texture. In addition, a
ripple effect is applied by modifying the texture coordinates of a densely
tessellated quad.

================================================================================
BUILD REQUIREMENTS:
 
iOS SDK 5.0 or later
 
================================================================================
RUNTIME REQUIREMENTS:
 
iOS 5.0 or later. This app will only work on device because of camera input
requirement. Due to the app's heavy use of CPU, performance may be sub-optimal
when running debug builds on certain devices.
 
================================================================================
Copyright (C) 2011-2013 Apple Inc. All rights reserved.