/*
 Copyright (C) 2015 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 N-body controller object for visualizing the simulation.
 */

#import <simd/simd.h>
#import <QuartzCore/CAMetalLayer.h>
#import <Metal/Metal.h>

@interface NBodyVisualizer : NSObject

// Query to determine if all resources were instantiated
@property (readonly) BOOL haveVisualizer;

// Generate all the resources necessary for N-body simulation
@property (nullable, nonatomic, setter=acquire:) id<MTLDevice> device;

// Render a frame for N-body simaulation
@property (nullable, nonatomic, setter=render:) id<CAMetalDrawable> drawable;

// Orthographic projection configuration type
@property uint32_t config;

// Coordinate points on the Eunclidean axis of simulation
@property (nonatomic) simd::float3 axis;

// Aspect ratio
@property (nonatomic) float aspect;

// Total number of frames to be rendered for a N-body simulation type
@property (nonatomic) uint32_t frames;

// The number of point particels
@property (nonatomic) uint32_t particles;

// Texture resolution.  The default is 64x64.
@property (nonatomic) uint32_t texRes;

// Becomes true once all the frames for a simulation type are rendered
@property (readonly) BOOL isComplete;

// Current active simulation type
@property (readonly) uint32_t active;

// Current frame being rendered
@property (readonly) uint32_t frame;

@end
