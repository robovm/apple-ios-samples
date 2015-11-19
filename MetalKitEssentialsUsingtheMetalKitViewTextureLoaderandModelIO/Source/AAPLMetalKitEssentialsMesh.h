/*
 Copyright (C) 2015 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 Wrapper for our MTKMesh with our own submesh object wrappers with materials set up for Metal.
 */

#import <Foundation/Foundation.h>
#import <MetalKit/MetalKit.h>

@interface AAPLMetalKitEssentialsMesh : NSObject

- (instancetype)initWithMesh:(MTKMesh *)mtkMesh mdlMesh:(MDLMesh*)mdlMesh device:(id<MTLDevice>)device;

- (void)renderWithEncoder:(id<MTLRenderCommandEncoder>)encoder;

@end
