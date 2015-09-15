/*
 Copyright (C) 2015 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 Utility class for creating a quad.
 */

#import <QuartzCore/QuartzCore.h>
#import <Metal/Metal.h>

@interface AAPLQuad : NSObject

// Indices
@property (nonatomic, readwrite) NSUInteger  vertexIndex;
@property (nonatomic, readwrite) NSUInteger  texCoordIndex;
@property (nonatomic, readwrite) NSUInteger  samplerIndex;

// Dimensions
@property (nonatomic, readwrite) CGSize  size;
@property (nonatomic, readwrite) CGRect  bounds;
@property (nonatomic, readonly)  float   aspect;

// Designated initializer
- (instancetype) initWithDevice:(id <MTLDevice>)device;

// Encoder
- (void) encode:(id <MTLRenderCommandEncoder>)renderEncoder;

@end
