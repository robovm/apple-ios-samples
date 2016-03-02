/*
 Copyright (C) 2016 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 Class representing each item in our table view controller.
 */

@import Foundation;

@interface FileRepresentation : NSObject 

@property (nonatomic, strong, readonly) NSURL *URL;

// typically just the NSURL would be enough as a backing object to our UITableView,
// but we choose to use a generic object to describe the file, offering possibilities for
// additional properties
//
- (instancetype)initWithURL:(NSURL *)URL NS_DESIGNATED_INITIALIZER;

@end