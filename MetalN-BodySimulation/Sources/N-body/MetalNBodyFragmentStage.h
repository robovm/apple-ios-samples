/*
 Copyright (C) 2015 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 Utility class for creating N-body simulation fragment stage.
 */

#import <Metal/Metal.h>

@interface MetalNBodyFragmentStage : NSObject

// Query to determine if all the resource were instantiated.
@property (readonly) BOOL isStaged;

// N-body simulation global parameters
@property (nullable, nonatomic) NSDictionary* globals;

// Fragment function name
@property (nullable) NSString* name;

// Metal library to use for instantiating a fragment stage
@property (nullable) id<MTLLibrary> library;

// Fragment stage function
@property (nullable, readonly) id<MTLFunction> function;

// Generate all the necessary fragment stage resources using a default system device
@property (nullable, nonatomic, setter=acquire:) id<MTLDevice> device;

// Encode texture and sampler for the fragment stage
@property (nullable, nonatomic, setter=encode:) id<MTLRenderCommandEncoder> cmdEncoder;

@end
