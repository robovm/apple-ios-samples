### GLImageProcessing ###

================================================================================
DESCRIPTION:

The GLImageProcessing sample application demonstrates how to implement simple image processing filters (Brightness, Contrast, Saturation, Hue rotation, Sharpness) using OpenGL ES1.1. The sample also shows how to create simple procedural button icons using CoreGraphics.

By looking at the code you'll see how to set up an OpenGL ES view and use it for applying a filter to a texture. The application creates a texture from an image loaded from disk. It pads the image to a power of two, if required by the GPU.

The Debug configuration in the Xcode project defines DEBUG and ASSERT preprocessor macros, to enable additional error checking.

To use this sample, open it in Xcode and click Build and Go. Use the slider to control the current filter. Only a single filter is applied at a time.

================================================================================
BUILD REQUIREMENTS:

iOS 4.0 SDK

================================================================================
RUNTIME REQUIREMENTS:

iPhone OS 3.2 or later

================================================================================
PACKAGING LIST:

ViewController.h
ViewController.m
Simple controller that redraws the view in response to UI events.
 
EAGLView.h
EAGLView.m
Convenience class that wraps the CAEAGLLayer from CoreAnimation into a UIView subclass.

Debug.h
Debug.c
Debug utilities to catch run-time GL errors and validate TexEnv state.

Imaging.h
Imaging.c
Simple 2D image processing using OpenGL ES1.1.

main.m
The main entry point for the GLImageProcessing application.

Texture.h
Texture.m
Simple image loader to create 2D OpenGL textures using CGImage.
 
Image.png
The screen-sized image loaded as a texture.

================================================================================
Copyright (C) 2008-2014 Apple Inc. All rights reserved.
