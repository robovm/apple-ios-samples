/*
 Copyright (C) 2015 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 Primary NSWindowController for this sample, used to display search results.
 */

#import <Cocoa/Cocoa.h>

// NSWindowController for showing iCloud documents
//
@interface AAPLWindowController : NSWindowController <NSTableViewDelegate, NSTableViewDataSource>

- (void)clearDocuments;
- (void)addDocument:(NSURL *)url withName:itemName modificationDate:(NSDate *)modificationDate icon:(NSImage *)icon;

@property (nonatomic, strong) IBOutlet NSProgressIndicator *progIndicator;

@end
