### GLPaint ###

================================================================================
DESCRIPTION:

The GLPaint sample application demonstrates how to support single finger painting using OpenGL ES. This sample also shows how to detect a "shake" motion of the device.

By looking at the code you'll see how to set up an OpenGL ES view and use it for rendering painting strokes. The application creates a brush texture from an image by first drawing the image into a Core Graphics bitmap context. It then uses the bitmap data for the texture.

To use this sample, open it in Xcode and click Build and Go. After the application paints "Shake Me", shake the device to erase the words. Touch a color to choose it. Paint by dragging a finger.

NOTE: When you run the application in the simulator, you can use the Shake Gesture key under Hardware to simulate the shake motion.

================================================================================
BUILD REQUIREMENTS:

iOS 7.0 SDK

================================================================================
RUNTIME REQUIREMENTS:

iOS 5.0 or later

================================================================================
PACKAGING LIST:

AppController.h
AppController.m
UIApplication's delegate class.

PaintingViewController.h
PaintingViewController.m
The central controller of the application. Handles shake and other motion events.

PaintingView.h
PaintingView.m
The class responsible for the finger painting. The class wraps the CAEAGLLayer from CoreAnimation into a convenient UIView subclass. The view content is basically an EAGL surface you render your OpenGL scene into.

SoundEffect.h
SoundEffect.m
A simple Objective-C wrapper around Audio Services functions that allow the loading and playing of sound files.

main.m
The main entry point for the GLPaint application.

Recording.data
Contains the path used to display "Shake Me" after the application launches.

Particle.png
The texture used for the paint brush.

================================================================================
CHANGES FROM PREVIOUS VERSIONS:

Version 1.13
Updated for iOS 7 and 64-bit.

Version 1.12
Updated with OpenGL ES 2.0. Added a root view controller. Moved main controls from the UIApplication delegate to the new PaintingViewController class. Replaced the HSL2RGB() function with UIColor's +colorWithHue:saturation:brightness:alpha:.

Version 1.11
Updated to take into account the view's contentScaleFactor.
Updated to draw strictly with premultiplied alpha pixel data.

Version 1.9
Upgraded project to build with the iOS 4.0 SDK.
Fixed minor bugs.

Version 1.8
Removed duplicate lines in setting up OpenGL blending.

Version 1.7
Updated for iPhone OS 3.1. Set texture parameters before creating the texture. This will save texture memory and texture loading time.
Use the shake API available in iPhone OS 3.0 and later.
Made the sample xib-based.

Version 1.6
Updated for and tested with iPhone OS 2.0. First public release.

Version 1.5
Minor changes to the comments.
There are no code changes in this version.

Version 1.4
Updated for Beta 6.
Updated code to use revised EAGL API.
Removed TouchView and Texture2D classes.
Replaced the views used to choose brush color with a segmented control.
Replace the Texture2D class with code that creates a texture using a Core Graphic bitmap graphics context.
Speeded up the "Shake Me" instructions that appear at the start of the application.
Revised touch handling to use the begin, moved, end, and cancelled methods instead of touchesChanged:withEvent;

Version 1.3
Updated for Beta 4. 
Changed project setting related to code signing.
Replaced pixel buffer objects with framebuffer objects.

Version 1.2
Added an icon and a default.png file.

Version 1.1 
Updated for Beta 2.

================================================================================
Copyright (C) 2009-2014 Apple Inc. All rights reserved.