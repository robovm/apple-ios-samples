/*
 Copyright (C) 2014 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 
  Player view backed by an AVPlayerLayer.
  
 */

@import UIKit;

@class AVPlayer;

@interface AAPLPlayerView : UIView

@property (nonatomic, strong) AVPlayer *player;

@end
