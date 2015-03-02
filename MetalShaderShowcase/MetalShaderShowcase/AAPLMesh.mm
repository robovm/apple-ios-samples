/*
 Copyright (C) 2014 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information

 */

#import "AAPLMesh.h"
#import "AAPLSharedTypes.h"

@implementation AAPLMesh

+ (instancetype)sharedInstance
{
    NSLog(@"Error: Should never enter AAPLMesh sharedInstance!");
    assert(0);
    return [[self alloc] init];
}

@end