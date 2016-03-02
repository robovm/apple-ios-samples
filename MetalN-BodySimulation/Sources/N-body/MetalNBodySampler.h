/*
 Copyright (C) 2015 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 Utility class for creating a sampler.
 */

#import <Metal/Metal.h>

@interface MetalNBodySampler : NSObject

// Generate a Metal sampler state using a default system device
@property (nullable, nonatomic, setter=acquire:) id<MTLDevice> device;

// Sample state object for N-body simulation
@property (nullable, readonly) id<MTLSamplerState> sampler;

// Query to find if the sampler state object was generated
@property (readonly) BOOL haveSampler;

@end
