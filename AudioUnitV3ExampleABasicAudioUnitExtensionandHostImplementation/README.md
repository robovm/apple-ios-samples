# AudioUnitV3Example: A Basic Audio Unit Extension and Host Implementation

Demonstrates how to build fully-functioning examples of an Audio Unit extension and Audio Unit host
using the version 3 Audio Unit APIs. The Audio Unit Extensions API introduces a mechanism for
developers to deliver Audio Units to users on iOS. The same API is available on both iOS and OS X,
and provides a bridging mechanism for existing v2 Audio Units and hosts to work with new v3 Audio
Units and hosts.

The project includes an example Audio Unit extension embedded in an application, an example host,
and some reusable utility classes.

### SimplePlayEngine

Illustrates use of AVAudioUnitComponentManager, AVAudioEngine, AVAudioUnit and AUAudioUnit to play
an audio file through a selected Audio Unit effect.

### AUv3Host

Uses SimplePlayEngine. Lets the user select an Audio Unit and preset. Supports opening an
Audio Unit's custom view.

### FilterDemo

A version 3 Audio Unit is packaged as an app extension, which must be embedded in an application.
This app packages shared code in a framework, also embedded in the app, so that both the app and the
extension can use the Audio Unit and its view controller.

The app registers the Audio Unit dynamically so as to be able to load it in-process for faster
iteration during development. It too uses SimplePlayEngine.

__Note:__ There is a bug in the iOS 9 developer seed where, if you manipulate FilterDemo's parameters
during playback in AUHost, they do not take effect. This bug should be fixed in a later seed.


## Requirements

### Build

Xcode 7.0, iOS 9.0 SDK

### Runtime

iOS 9.0

Copyright (C) 2015 Apple Inc. All rights reserved.
