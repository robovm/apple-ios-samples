# Using AVFoundation APIs to write a movie with location timed metadata

This sample shows how to use AVAssetWriterInputMetadataAdaptor API to write timed location metadata, obtained from CoreLocation, during live video capture. The captured movie file has video, audio and metadata track. The metadata track contains location corresponding to where the video was recorded.

## Requirements

Xcode 5.0 or later, iOS 8 or later

### Build

Xcode 5.0 or later, iOS 8 SDK

### Runtime

iOS 8 or later

### Note

The recorded movie will contain metadata in a separate track. To visualize it you would have to use AVAssetReaderOutputMetadataAdaptor or AVPlayerItemMetadataOutput.

Copyright (C) 2014 Apple Inc. All rights reserved.
