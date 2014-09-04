iPhoneMultichannelMixerTest

===========================================================================
DESCRIPTION:

iPhoneMultichannelMixerTest demonstrates how to build an Audio Unit Graph connecting a MultiChannel Mixer instance
to the RemoteIO unit.
Two input busses are created each with input volume controls. An overall mixer output volume control is also provided
and each bus may be enabled or disabled.

All the relevant code is in the file MultichannelMixerController.mm while the supporting UI code is in MyViewController.m

Touching the "Play Audio" button simply calls AUGraphStart while "Stop Audio" calls AUGraphStop. Changing AU volume is
performed via AudioUnitSetParameter.

Audio data is provided from two single channel audio files. Each single channel of data
(a guitar riff and drum groove respectively) is rendered to a single channel of each input bus resulting in the guitar
on the left channel and the drums on the right channel at the output. This serves no specific purpose other than making
for an obvious sample where you can turn off and change the volume of each input and be very aware of the results.


===========================================================================
RELATED INFORMATION:

Audio Session Programming Guide
Core Audio Overview
Audio Unit Processing Graph Services Reference
Output Audio Unit Services Reference
System Audio Unit Access Guide
Audio Component Services Reference
Audio File Services Reference


AudioToolbox/AUGraph.h
AudioToolbox/ExtendedAudioFile.h


===========================================================================
SPECIAL CONSIDERATIONS:

None


===========================================================================
BUILD REQUIREMENTS:

iOS 6.1 SDK

===========================================================================
RUNTIME REQUIREMENTS:

iPhone OS 6.1 or later

===========================================================================
PACKAGING LIST:

MultichannelMixerTestDelegate.h
MultichannelMixerTestDelegate.m

The MultichannelMixerTestDelegate class defines the application delegate object, responsible for adding the navigation
controllers view to the application window, setting up the Audio Session and so on.

MyViewController.h
MyViewController.m

The MyViewController class defines the controller object for the application. The object helps set up the user interface,
responds to and manages user interaction, and communicates with the MultichannelMixerController.

MultichannelMixerController.h
MultichannelMixerController.mm

This file implements setting up the AUGraph, loading up the audio data using ExtAudioFile, the input render procedure and so on.

All the code demonstrating interacting with Core Audio is in this one file, the rest of the sample can be thought of as a simple
framework for the demonstration code in this file.

===========================================================================
CHANGES FROM PREVIOUS VERSIONS:

Version 1.0, tested with iPhone OS 3.0. First public release.
Version 1.1, upgraded project to build with the iOS 4 SDK.
Version 1.1.1, upgraded project to build with the iOS 6.1 SDK. Migrated to AVAudioSession from AudioSession APIs.


================================================================================
Copyright (C) 2009-2013 Apple Inc. All rights reserved.