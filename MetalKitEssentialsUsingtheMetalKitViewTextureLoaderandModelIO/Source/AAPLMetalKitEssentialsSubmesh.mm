/*
 Copyright (C) 2015 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 Wrapper for our MTKSubmesh objects with materials set up for Metal.
 */

#import "AAPLMetalKitEssentialsSubmesh.h"
#import "AAPLShaderTypes.h"

@implementation AAPLMetalKitEssentialsSubmesh {
    /*
        Using ivars instead of properties to avoid any performance penalities with
        the Objective-C runtime.
    */
    id<MTLBuffer> _materialUniforms;
    id<MTLTexture> _diffuseTexture;
    MTKSubmesh *_submesh;
}

- (instancetype)initWithSubmesh:(MTKSubmesh *)mtkSubmesh mdlSubmesh:(MDLSubmesh*)mdlSubmesh device:(id<MTLDevice>)device {
    self = [super init];
    
    if (self) {
        _materialUniforms = [device newBufferWithLength:sizeof(AAPLMaterialUniforms) options:0];
        
        AAPLMaterialUniforms *materialUniforms = (AAPLMaterialUniforms *)[_materialUniforms contents];
        
        _submesh = mtkSubmesh;
        
        // Iterate through the Material's properties...
        
        for (MDLMaterialProperty *property in mdlSubmesh.material) {
            if ([property.name isEqualToString:@"baseColorMap"]) {
                if (property.type == MDLMaterialPropertyTypeString) {
                    NSMutableString *URLString = [[NSMutableString alloc] initWithString:@"file://"];
                    [URLString appendString:property.stringValue];
                    
                    NSURL *textureURL = [NSURL URLWithString:URLString];
                    
                    MTKTextureLoader *textureLoader = [[MTKTextureLoader alloc] initWithDevice:device];
                    
                    NSError *error;
                    _diffuseTexture = [textureLoader newTextureWithContentsOfURL:textureURL options:nil error:&error];
                    
                    if (!_diffuseTexture) {
                        [NSException raise:@"diffuse texture load" format:@"%@", error.localizedDescription];
                    }
                }
            }
            else if ([property.name isEqualToString:@"specularColor"]) {
                if (property.type == MDLMaterialPropertyTypeFloat4) {
                    materialUniforms->specularColor = property.float4Value;
                }
                else if (property.type == MDLMaterialPropertyTypeFloat3) {
                    materialUniforms->specularColor.xyz = property.float3Value;
                    materialUniforms->specularColor.w = 1.0;
                }
            }
            else if ([property.name isEqualToString:@"emission"]) {
                if(property.type == MDLMaterialPropertyTypeFloat4) {
                    materialUniforms->emissiveColor = property.float4Value;
                }
                else if (property.type == MDLMaterialPropertyTypeFloat3) {
                    materialUniforms->emissiveColor.xyz = property.float3Value;
                    materialUniforms->emissiveColor.w = 1.0;
                }
            }
        }
    }
    return self;
}

- (void) renderWithEncoder:(id<MTLRenderCommandEncoder>)encoder {
    // Set material values and textures.
    
    if(_diffuseTexture) {
        [encoder setFragmentTexture:_diffuseTexture atIndex:AAPLDiffuseTextureIndex];
    }
    
    [encoder setFragmentBuffer:_materialUniforms offset:0 atIndex:AAPLMaterialUniformBuffer];
    [encoder setVertexBuffer:_materialUniforms offset:0 atIndex:AAPLMaterialUniformBuffer];
    
    // Draw the submesh.
    [encoder drawIndexedPrimitives:_submesh.primitiveType indexCount:_submesh.indexCount indexType:_submesh.indexType indexBuffer:_submesh.indexBuffer.buffer indexBufferOffset:_submesh.indexBuffer.offset];
}

@end