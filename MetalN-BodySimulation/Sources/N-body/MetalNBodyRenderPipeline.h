/*
 Copyright (C) 2015 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 Utility class for creating a render state pipeline.
 */

#import <Metal/Metal.h>

@interface MetalNBodyRenderPipeline : NSObject

// Query to determine if render pipeline state is instantiated
@property (readonly) BOOL haveDescriptor;

// Vertex function
@property (nullable) id<MTLFunction> vertex;

// Fragment function
@property (nullable) id<MTLFunction> fragment;

// Generate render pipeline state using a default system
// device, fragment and vertex stages
@property (nullable, nonatomic, setter=acquire:) id<MTLDevice> device;

// Render pipeline descriptor state
@property (nullable, readonly) id<MTLRenderPipelineState> render;

// Set blending
@property BOOL blend;

@end
