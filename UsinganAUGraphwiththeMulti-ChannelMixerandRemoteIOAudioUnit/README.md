# Using an AUGraph with the Multi-Channel Mixer and Remote I/O Audio Unit 

Demonstrates how to build an Audio Unit Graph connecting a Multichannel Mixer instance to the RemoteIO unit. Two input busses are
created each with input volume controls. An overall mixer output volume control is also provided and each bus may be enabled or
disabled.

# Detailed Description

iOS MultichannelMixerTest demonstrates how to build an Audio Unit Graph connecting a MultiChannel Mixer instance
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

# Related Information

Audio Session Programming Guide
Core Audio Overview
Audio Unit Processing Graph Services Reference
Output Audio Unit Services Reference
System Audio Unit Access Guide
Audio Component Services Reference
Audio File Services Reference


AudioToolbox/AUGraph.h
AudioToolbox/ExtendedAudioFile.h

# Changes From Previous Versions:

Version 1.0, tested with iPhone OS 3.0. First public release.
Version 1.1, upgraded project to build with the iOS 4 SDK.
Version 1.1.1, upgraded project to build with the iOS 6.1 SDK. Migrated to AVAudioSession from AudioSession APIs.
Version 1.2, updated for iOS 8 and Xcode 6.3.1. Removed CAStreamBasicDescription in favour of new AVAudioFormat and Common 32bit float format.

## Requirements

### Build

iOS 8.3 SDK

### Runtime

iPhone OS 8.3 or later

Copyright (C) 2009-2015 Apple Inc. All rights reserved.
