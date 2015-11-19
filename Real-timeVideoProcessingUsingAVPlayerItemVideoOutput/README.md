AVBasicVideoOutput
==================

This sample shows how to perform real-time video processing using AVPlayerItemVideoOutput and how to optimally display processed video frames on screen using CAEAGLLayer and CADisplayLink. It uses simple math to adjust the luma and chroma values of pixels in every video frame in real time. 

An AVPlayerItemVideoOutput object vends CVPixelBuffers in real-time. To drive the AVPlayerItemVideoOutput we need to use a fixed rate, hardware synchronized service like CADisplayLink or GLKitViewController. These services send a callback to the application at the vertical sync frequency. Through these callbacks we can query AVPlayerItemVideoOutput for a new pixel buffer (if available) for the next vertical sync. This pixel buffer is then processed for any video effect we wish to apply and rendered to screen on a view backed by a CAEAGLLayer.


Main Files

ViewController.m/.h:
A ViewController instance handles the UI to load assets for playback and for adjusting the luma and chroma values. It also sets up the AVPlayerItemVideoOutput, from which CVPixelBuffers are pulled out and sent to the shaders for rendering. The EAGLView classes loads, compiles and links the fragment and vertex shader to be used during rendering. 

EAGLView.m/.h:
 A subclass of UIView which backed by a CAEAGLLayer. This setups vertex and fragment shaders for rendering.

Shader.fsh/.vsh:
 The fragment and vertex shader which change the pixel values based on the value of the two UI sliders.

================================================
Copyright © 2013 Apple Inc. All rights reserved.