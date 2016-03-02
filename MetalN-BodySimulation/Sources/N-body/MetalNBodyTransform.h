/*
 Copyright (C) 2015 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 Utility class for managing N-body linear transformation matrix and buffer.
 */

#import <simd/simd.h>
#import <Metal/Metal.h>

@interface MetalNBodyTransform : NSObject

// Query to determine if a Metal buffer was generated successfully
@property (readonly) BOOL haveBuffer;

// Generate a Metal buffer and linear tranformations using a default system device
@property (nullable, nonatomic, setter=acquire:) id<MTLDevice> device;

// Metal buffer for linear transformation matrix
@property (nullable, readonly) id<MTLBuffer> buffer;

// Linear transformation matrix
@property (readonly) simd::float4x4 transform;

// Metal buffer size
@property (readonly) size_t size;

// Update the mvp linear transformation matrix
@property (nonatomic) BOOL update;

// Set the aspect ratio for the orthographic 2d projection
@property (nonatomic) float aspect;

// Orthographic projection configuration type
@property (nonatomic) uint32_t config;

// Orthographic 2d bounds
@property simd::float3 bounds;

// (x,y,z) centers
@property float center;
@property float zCenter;

@end
