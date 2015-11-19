/*
 Copyright (C) 2015 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 Wrapper for our MTKMesh with our own submesh object wrappers with materials set up for Metal.
 */

#import "AAPLMetalKitEssentialsMesh.h"
#import "AAPLMetalKitEssentialsSubmesh.h"
#import <Foundation/Foundation.h>
#import "AAPLShaderTypes.h"

@implementation AAPLMetalKitEssentialsMesh {
    /*
        Using ivars instead of properties to avoid any performance penalities with
        the Objective-C runtime.
    */
    
    MTKMesh *_mesh;
    NSMutableArray<AAPLMetalKitEssentialsSubmesh *> *_submeshes;
}

- (instancetype)initWithMesh:(MTKMesh *)mtkMesh mdlMesh:(MDLMesh*)mdlMesh device:(id<MTLDevice>)device {
    self = [super init];

    if (self) {
        _mesh = mtkMesh;
        
        // Create an array to hold this mesh's submeshes.
        _submeshes = [[NSMutableArray alloc] initWithCapacity:mtkMesh.submeshes.count];

        assert(mtkMesh.submeshes.count == mdlMesh.submeshes.count);

        for(NSUInteger index = 0; index < mtkMesh.submeshes.count; index++) {
            // Create our own app specifc submesh to hold the MetalKit submesh.
            AAPLMetalKitEssentialsSubmesh *submesh =
            [[AAPLMetalKitEssentialsSubmesh alloc] initWithSubmesh:mtkMesh.submeshes[index]
                                                        mdlSubmesh:mdlMesh.submeshes[index]
                                                            device:device];

            [_submeshes addObject:submesh];
        }

    }
    
    return self;
}

- (void)renderWithEncoder:(id<MTLRenderCommandEncoder>)encoder {
    NSUInteger bufferIndex = 0;

    for (MTKMeshBuffer *vertexBuffer in _mesh.vertexBuffers) {
        // Set mesh's vertex buffers.
        if(vertexBuffer.buffer != nil) {
            [encoder setVertexBuffer:vertexBuffer.buffer offset:vertexBuffer.offset atIndex:bufferIndex];
        }

        bufferIndex++;
    }
    
    for(AAPLMetalKitEssentialsSubmesh *submesh in _submeshes) {
        // Render each submesh.
        [submesh renderWithEncoder:encoder];
    }
}
@end

