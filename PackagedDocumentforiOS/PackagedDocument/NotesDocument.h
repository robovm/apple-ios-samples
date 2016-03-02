/*
 Copyright (C) 2016 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 Class representing our document format.
 */

@import Foundation;

extern NSString *kFileExtension;

@class Note;

@interface NotesDocument : UIDocument 

@property (strong) Note *note;

@end



