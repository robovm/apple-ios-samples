aurioTouch

===========================================================================
DESCRIPTION:

aurioTouch demonstrates use of the remote i/o audio unit for handling audio input and output. The application can display the input audio in one of the forms, a regular time domain waveform, a frequency domain waveform (computed by performing a fast fourier transform on the incoming signal), and a sonogram view (a view displaying the frequency content of a signal over time, with the color signaling relative power, the y axis being frequency and the x as time). Tap the sonogram button to switch to a sonogram view, tap anywhere on the screen to return to the oscilloscope. Tap the FFT button to perform and display the input data after an FFT transform. Pinch in the oscilloscope view to expand and contract the scale for the x axis.

The code in aurioTouch uses the remote i/o audio unit (AURemoteIO) for input and output of audio, and OpenGL for display of the input waveform. The application also uses AVAudioSession to manage route changes (as described in the Audio Session Programming Guide).

This application shows how to:

	* Set up the remote i/o audio unit for input and output.
	* Use OpenGL for graphical display of audio waveforms.
	* Use touch events such as tapping and pinching for user interaction
	* Use AVAudioSession Services to handle route changes and reconfigure the unit in response.
	* Use AVAudioSession Services to set an audio session category for concurrent input and output.
	* Use AudioServices to create and play system sounds
	

===========================================================================
RELATED INFORMATION:

===========================================================================
BUILD REQUIREMENTS:

OS X v10.9, Xcode 5.1, iOS 7.1, iOS SDK 7.1 or later


===========================================================================
RUNTIME REQUIREMENTS:

iPhone: iOS 7.0


===========================================================================
PACKAGING LIST:

EAGLView.h
EAGLView.m

This class wraps the CAEAGLLayer from CoreAnimation into a convenient UIView subclass. This class is also responsible for handling touch events and drawing.

AudioController.h
AudioController.mm

This class demonstrates the audio APIs used to capture audio data from the microphone and play it out to the speaker. It also demonstrates how to play system sounds.

aurioTouchAppDelegate.h
aurioTouchAppDelegate.mm

The application delegate for the aurioTouch app.

FFTHelper.h
FFTHelper.cpp

This class demonstrates how to use the Accelerate framework to take Fast Fourier Transforms (FFT) of the audio data. FFTs are used to perform analysis on the captured audio data

BufferManager.h
BufferManager.cpp

This class handles buffering of audio data that is shared between the view and audio controller

DCRejectionFilter.h
DCRejectionFilter.cpp

This class implements a DC offset filter

CAMath.h

CAMath is a helper class for various math functions.

CADebugMacros.h
CADebugMacros.cpp

A helper class for printing debug messages.

CAXException.h
CAXException.cpp

A helper class for exception handling.

CAStreamBasicDescription.cpp
CAStreamBasicDescription.h

A helper class for AudioStreamBasicDescription handling and manipulation.

================================================================================
Copyright (C) 2008-2014 Apple Inc. All rights reserved.
