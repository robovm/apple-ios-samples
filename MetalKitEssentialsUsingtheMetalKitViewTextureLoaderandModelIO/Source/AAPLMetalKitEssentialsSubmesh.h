/*
 Copyright (C) 2015 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 Wrapper for our MTKSubmesh objects with materials set up for Metal.
 */

#import <Foundation/Foundation.h>
#import <MetalKit/MetalKit.h>

@interface AAPLMetalKitEssentialsSubmesh : NSObject

- (instancetype)initWithSubmesh:(MTKSubmesh *)mtkSubmesh mdlSubmesh:(MDLSubmesh*)mdlSubmesh device:(id<MTLDevice>)device;

- (void)renderWithEncoder:(id<MTLRenderCommandEncoder>)encoder;
 
@end