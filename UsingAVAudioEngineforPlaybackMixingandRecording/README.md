# Using AVAudioEngine for Playback, Mixing and Recording

This sample uses the AVAudioEngine with two AVAudioPlayerNode and AVAudioPCMBuffer objects along with an AVAudioUnitDelay and AVAudioUnitReverb to playback two loops which can then be mixed, processed and recorded.

AVAudioEngine contains a group of connected AVAudioNodes ("nodes"), each of which performs an audio signal generation, processing, or input/output task.

For more information refer to AVAudioEngine in Practice WWDC 2014: https://developer.apple.com/videos/wwdc/2014/#502

## Requirements

### Build

iOS 9 SDK, Xcode Version 7.1 or greater

### Runtime

iOS 9.x

## Version History
1.0 First public version

1.1 Minor updates:
* added audio to the UIBackgroundModes in the plist
* improved handling of audio interruptions
* changed the audio category to Playback, previous version used PlayAndRecord, but doesn't require audio input
* fixed a bug in handleMediaServicesReset: method
* corrected some old comments

2.0 Major update:
* (new) Demonstrates use of AVAudioSequencer, AVAudioMixing, AVAudioDestinationMixing
* (new) Added support for iPhone, iPad using Size Classes
* (modified) Useage of a single AVAudioPlayerNode that toggles between a recorded AVAudioFile and a AVAudioPCMBuffer

Copyright (C) 2015-2016 Apple Inc. All rights reserved.