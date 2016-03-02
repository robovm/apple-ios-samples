/*
 Copyright (C) 2016 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 Class describing the "NotesDocument" format.
 */

@import Foundation;

@interface Note : NSObject

@property (strong, nonatomic) NSString *notes;
@property (strong, nonatomic) UIImage *image;

@end