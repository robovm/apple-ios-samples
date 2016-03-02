/*
 Copyright (C) 2015 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 Utilities for managing metal buffers representing matrices.
 */

#import <Metal/Metal.h>

// A utility class to encapsulate instantiation of Metal matrix buffer.
// By the virtue of this encapsulation, and after the buffers are added
// to a mutable array of buffers, all buffers are kept alive in the
// matrix multipication object's life-cycle.
@interface MetalMatrixBuffer: NSObject

@property (nonatomic)           BOOL           resized;
@property (nonatomic)           size_t         size;
@property (nonatomic)           void*          baseAddr;
@property (nonatomic)           id<MTLBuffer>  buffer;
@property (nonatomic, readonly) id<MTLDevice>  device;

- (instancetype) initWithDevice:(id<MTLDevice>)device;

@end

// A utility class to encapsulate instantiation of Metal matrix buffer.
// By the virtue of this encapsulation, and after the buffers are added
// to a mutable array of buffers, all buffers are kept alive in the
// matrix multipication object's life-cycle.
@interface MetalMatrixBuffers: NSObject

@property (nonatomic)            NSMutableArray*  array;
@property (nonatomic, readonly) size_t            capacity;

- (instancetype) initWithDevice:(id<MTLDevice>)device
                       capacity:(size_t)capacity;

@end
