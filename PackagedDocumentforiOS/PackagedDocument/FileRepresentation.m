/*
 Copyright (C) 2016 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 Class representing each item in our table view controller.
 */

#import "FileRepresentation.h"

@implementation FileRepresentation

- (instancetype)init
{
    self = [self initWithURL:nil];
    return self;
}

- (instancetype)initWithURL:(NSURL *)URL
{
    self = [super init];
    if (self != nil)
    {
        _URL = URL;
    }
    return self;
}

@end
