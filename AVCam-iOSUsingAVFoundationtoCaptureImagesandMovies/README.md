# AVCam-iOS: Using AVFoundation to Capture Images and Movies

AVCam demonstrates how to use the  AVFoundation capture API to record movies and capture still images. The sample has a record button for recording movies, a camera button for switching between front and back cameras (on supported devices), and a still button for capturing still images. AVCam runs only on an actual device, either an iPad or iPhone, and cannot be run in Simulator.

## Requirements

### Build

Xcode 7.0, iOS 9.0 SDK

### Runtime

iOS 8.0 or later

## Changes from Previous Version

- Use the Photos framework to save captured images and videos.
- Adopt the interface rotation APIs introduced in iOS 8.
- Adopt size classes and use one storyboard for all devices.
- Opt-out of multi-app layout support by requiring full screen.
- Handle session interruptions, see AVCaptureSessionInterruptionReason.
- More explicit authorization flow.
- Update usage of deprecated APIs.
- Bug fixes.

Copyright (C) 2015 Apple Inc. All rights reserved.
