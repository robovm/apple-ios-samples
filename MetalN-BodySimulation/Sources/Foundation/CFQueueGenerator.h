/*
 Copyright (C) 2015 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 A functor for creating dispatch queue with a unique identifier.
 */

#import <Foundation/Foundation.h>

@interface CFQueueGenerator : NSObject

// Desired dispatch queue attribute.  Defaults to serial.
@property (nullable) dispatch_queue_attr_t attribute;

// Dispatch queue identifier
@property (nullable, nonatomic, readonly) const char* identifier;

// Dispatch queue label
@property (nullable, nonatomic) const char* label;

// A dispatch queue created with the set attribute.
// Defaults to a serial dispatch queue.
@property (nullable, nonatomic, readonly) dispatch_queue_t queue;

@end
