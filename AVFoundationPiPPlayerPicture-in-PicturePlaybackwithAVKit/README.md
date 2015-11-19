# AVFoundationPiPPlayer: Picture-in-picture playback with AVKit

This sample demonstrates the use of AVPictureInPictureController to get picture in picture playback of video content from an application. It shows the steps required to be able to start and stop picture in picture mode and also on how to setup a delegate to receive event callbacks. Clients of AVFoundation using AVPlayerLayer for media playback should use AVPictureInPictureController class, whereas clients of AVKit who use AVPlayerViewController get picture in picture mode without any additional setup.

The sample also demonstrates the configuration setup required by an application to be able to use picture in picture. This configuration involves:

1. Setting UIBackgroundMode to audio under the project settings.

2. Setting audio session category to AVAudioSessionCategoryPlayback or AVAudioSessionCategoryPlayAndRecord (as appropriate)

If an application is not configured correctly, AVPictureInPictureController.pictureInPicturePossible() returns false.

The AppDelegate class configures the application as described above.

The PlayerViewController class creates and manages an AVPictureInPictureController object. It also handles delegate callbacks to setup / restore UI when in picture in picture. This class also handles the playback setup and UI.

## Requirements

### Build

Xcode 7.0, iOS 9.0 SDK

### Runtime

iOS 9.0

Copyright (C) 2015 Apple Inc. All rights reserved.
