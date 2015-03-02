# Using AVFoundation to write and playback a movie with custom annotation as metadata

This sample shows how to use AVAssetWriterInputMetadataAdaptor API to write circle annotation metadata during video playback. The captured movie file has video, audio and metadata track. The metadata track contains circle annotation which is vended during playback using AVPlayerItemMetadataOutput.

## To use:
1. Use two finger tap to add a circle and text annotation
2. Use single finger tap to start playback
3. After playback begins, you can move the circle around and when done, hit export to save annotation metadata to a movie file via AVAssetWriterInputMetadataAdaptor
4. When export is completed, a player view controller display the output movie file with metadata which is received via AVPlayerItemMetadataOutput

### Build

Xcode 5.0 or later, iOS 8 or later

### Runtime

iOS 8 or later

Copyright (C) 2014 Apple Inc. All rights reserved.
