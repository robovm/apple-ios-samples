/*
 Copyright (C) 2014 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 
  Player view controller which sets up playback of movie file with metadata and uses AVPlayerItemMetadataOutput to render circle and text annotation during playback.
  
 */

@import UIKit;
@import AVKit;

@interface AAPLPlayerViewController : AVPlayerViewController

- (void)setupPlaybackWithURL:(NSURL *)movieURL;

@end
