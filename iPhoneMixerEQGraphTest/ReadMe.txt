iPhoneMixerEQGraphTest

===========================================================================
DESCRIPTION:

iPhoneMixerEQGraphTest demonstrates how to build an Audio Unit Graph connecting a MultiChannel Mixer to the iPodEQ unit then to the RemoteIO unit.

Two input busses are created each with input volume controls. An overall mixer output volume control is also provided and each bus may be enabled or disabled.

The iPodEQ may be enabled or disabled and a preset EQ curve may be chosen via a picker in the iPod Equalizer view. iPhoneMixerEQGraphTest uses 44.1kHz source and sets the hardware sample rate to 44.1kHz to avoid any extraneous sample rate conversions.

All the relevant code is in the file AUGraphController.mm while the supporting UI code is in MyViewController.m

Touching the "Play Audio" button simply calls AUGraphStart while "Stop Audio" calls AUGraphStop. Changing AU volume is performed via AudioUnitSetParameter.

The EQ presets are returned by using AudioUnitGetProperty asking for the kAudioUnitProperty_FactoryPresets CFArrayRef. A current preset is then selected calling AudioUnitSetProperty using the kAudioUnitProperty_PresentPreset property and passing in the appropriate AUPreset. Note that the AU Host owns the returned CFArray and should release it when done.

Audio data is provided from two stereo audio files. The audio data is AAC compressed and ExtAudioFile is used to convert this data to the Core Audio Canonical uncompressed LPCM client format for input to the multichannel mixer.

A lot of information about what's going on in the sample is dumped out to the console and can be used to understand how everything is being configured. Methods such as CAShow and the Print() method of the CAStreamBasicDescription helper class are invaluable if you're confused about how stream formats and the AUGraph are being configured.

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

iOS 7.0 SDK

===========================================================================
RUNTIME REQUIREMENTS:

iOS 7.0 or later


===========================================================================
PACKAGING LIST:

MixerEQGraphTestDelegate.h
MixerEQGraphTestDelegate.m

The MixerEQGraphTestDelegate class defines the application delegate object, responsible for adding the navigation
controllers view to the application window, setting up the Audio Session and so on.

MyViewController.h
MyViewController.m

The MyViewController class defines the controller object for the application. The object helps set up the user interface,
responds to and manages user interaction, and communicates with the AUGraphController.

AUGraphController.h
AUGraphController.mm

This file implements setting up the AUGraph, loading up the audio data using ExtAudioFile, the input render procedure and so on. All the code demonstrating interacting with Core Audio is in this one file, the rest of the sample can be thought of as a simple framework for the demonstration code in this file.

===========================================================================
CHANGES FROM PREVIOUS VERSIONS:

Version 1.0, Tested with iPhone OS 3.1.3. First public release.
Version 1.1, Upgraded project to build with the iOS 4 SDK.
Version 1.2, Changed deployment target back to iPhone OS 3.2 and added CFBundleIconFiles in Info.plist.
Version 1.2.1, Updated for iOS 6.1 SDK. Migrated to AVAudioSession from AudioSession APIs.
Version 1.2.2, Updated for iOS 7.0 SDK. Added SetProperty call setting output stream format for iPodAU.


===========================================================================
Copyright (C) 2010-2014 Apple Inc. All rights reserved.