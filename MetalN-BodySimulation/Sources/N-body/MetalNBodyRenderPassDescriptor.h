/*
 Copyright (C) 2015 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 Utility class for creating a render pass descriptor.
 */

#import <QuartzCore/CAMetalLayer.h>
#import <Metal/Metal.h>

@interface MetalNBodyRenderPassDescriptor : NSObject

// Set a drawable to set render pass descriptors texture
@property (nullable, nonatomic) id<CAMetalDrawable> drawable;

// Get the render pass descriptor object
@property (nullable, readonly) MTLRenderPassDescriptor* descriptor;

// Query to determine if a texture was acquired from a drawable
@property (readonly) BOOL haveTexture;

// Read the types for render pass descriptors load/store
@property (readonly) MTLLoadAction  load;
@property (readonly) MTLStoreAction store;

// Get or set the clear color for the render pass descriptor
@property (nonatomic) MTLClearColor color;

@end
