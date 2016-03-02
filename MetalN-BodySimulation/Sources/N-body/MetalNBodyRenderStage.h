/*
 Copyright (C) 2015 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 Utility class for instantiating and encoding of vertex and fragment stages.
 */

#import <simd/simd.h>

#import <QuartzCore/CAMetalLayer.h>
#import <Metal/Metal.h>

@interface MetalNBodyRenderStage : NSObject

// Default library for creating vertexa nd fragment stages
@property (nullable) id<MTLLibrary> library;

// Command buffer for render command encoder
@property (nullable) id<MTLCommandBuffer> cmdBuffer;

// Buffer for point particle positions
@property (nullable) id<MTLBuffer>  positions;

// Orthographic projection configuration type
@property (nonatomic) uint32_t config;

// N-body simulation global parameters
@property (nullable, nonatomic) NSDictionary* globals;

// N-body parameters for simulation types
@property (nullable, nonatomic) NSDictionary* parameters;

// Query to determine if all the resources are instantiated for the render stage object
@property (readonly) BOOL isStaged;

// Query to determine if all stages are encoded
@property (readonly) BOOL isEncoded;

// Color host pointer
@property (nullable, nonatomic, readonly) simd::float4* colors;

// Aspect ratio
@property (nonatomic) float aspect;

// Update the linear transformation mvp matrix
@property (nonatomic) BOOL update;

// Generate all the fragment, vertex and stages
@property (nullable, nonatomic, setter=acquire:) id<MTLDevice> device;

// Encode vertex and fragment stages
@property (nullable, nonatomic, setter=encode:) id<CAMetalDrawable> drawable;

@end
