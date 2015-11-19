/*
 Copyright (C) 2015 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 Displays details of a single parsed song.
*/

@import UIKit;

@class Song;

@interface DetailController : UITableViewController

@property (nonatomic, strong) Song *song;

@end
