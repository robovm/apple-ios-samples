/*
 Copyright (C) 2015 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 Displays details about a song.
 */

#import <UIKit/UIKit.h>

@class Song;

@interface SongDetailsController : UITableViewController

@property (nonatomic, strong) Song *song;

@end
