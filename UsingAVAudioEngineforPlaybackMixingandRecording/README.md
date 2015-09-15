# Using AVAudioEngine for Playback, Mixing and Recording

This sample uses the AVAudioEngine with two AVAudioPlayerNode and AVAudioPCMBuffer objects along with an AVAudioUnitDelay and AVAudioUnitReverb to playback two loops which can then be mixed, processed and recorded.

AVAudioEngine contains a group of connected AVAudioNodes ("nodes"), each of which performs an audio signal generation, processing, or input/output task.

For more information refer to AVAudioEngine in Practice WWDC 2014: https://developer.apple.com/videos/wwdc/2014/#502

## Requirements

### Build

iOS 8 SDK, Xcode Version 6.1.1 or greater

### Runtime

iOS 8 SDK
iPad only

## Version History
1.0 First public version

1.1 Minor updates:
* added audio to the UIBackgroundModes in the plist
* improved handling of audio interruptions
* changed the audio category to Playback, previous version used PlayAndRecord, but doesn't require audio input
* fixed a bug in handleMediaServicesReset: method
* corrected some old comments

Copyright (C) 2015 Apple Inc. All rights reserved.
