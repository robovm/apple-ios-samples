/*
 Copyright (C) 2015 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 Controller for the main table view of the LazyTable sample.
  This table view controller works off the AppDelege's data model.
  produce a three-stage lazy load:
  1. No data (i.e. an empty table)
  2. Text-only data from the model's RSS feed
  3. Images loaded over the network asynchronously
  
  This process allows for asynchronous loading of the table to keep the UI responsive.
  Stage 3 is managed by the AppRecord corresponding to each row/cell.
  
  Images are scaled to the desired height.
  If rapid scrolling is in progress, downloads do not begin until scrolling has ended.
 */

@import UIKit;

@interface RootViewController : UITableViewController

// the main data model for our UITableView
@property (nonatomic, strong) NSArray *entries;

@end