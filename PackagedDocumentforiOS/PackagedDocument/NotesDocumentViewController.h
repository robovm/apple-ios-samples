/*
 Copyright (C) 2016 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 The view controller used for editing "NotesDocument".
 */

@import UIKit;

@protocol NotesDocumentDelegate;

@interface NotesDocumentViewController : UITableViewController

@property (nonatomic, assign) id <NotesDocumentDelegate> delegate;

- (void)setDocumentURL:(NSURL *)url createNewFile:(BOOL)createNewFile;

@end


#pragma mark -

// used to notify when a document was renamed, so we can update our parent's table
@protocol NotesDocumentDelegate <NSObject>

@optional
- (void)directoryDidChange;

@end