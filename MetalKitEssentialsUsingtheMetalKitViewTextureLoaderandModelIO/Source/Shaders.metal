/*
 Copyright (C) 2015 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 Main application delegate.
 */

#include <metal_stdlib>
#include <simd/simd.h>
#include <metal_texture>
#include <metal_matrix>
#include <metal_geometric>
#include <metal_math>
#include <metal_graphics>
#include "AAPLShaderTypes.h"

using namespace metal;

// Variables in constant address space.
constant float3 lightPosition = float3(0.0, 1.0, -1.0);

// Per-vertex input structure
struct VertexInput {
    float3 position [[attribute(AAPLVertexAttributePosition)]];
    float3 normal   [[attribute(AAPLVertexAttributeNormal)]];
    half2  texcoord [[attribute(AAPLVertexAttributeTexcoord)]];
};

// Per-vertex output and per-fragment input
typedef struct {
    float4 position [[position]];
    half2  texcoord;
    half4  color;
} ShaderInOut;

// Vertex shader function
vertex ShaderInOut vertexLight(VertexInput in [[stage_in]],
                               constant AAPLFrameUniforms& frameUniforms [[ buffer(AAPLFrameUniformBuffer) ]],
                               constant AAPLMaterialUniforms& materialUniforms [[ buffer(AAPLMaterialUniformBuffer) ]]) {
    ShaderInOut out;
    
    // Vertex projection and translation
    float4 in_position = float4(in.position, 1.0);
    out.position = frameUniforms.projectionView * in_position;
    
    // Per vertex lighting calculations
    float4 eye_normal = normalize(frameUniforms.normal * float4(in.normal, 0.0));
    float n_dot_l = dot(eye_normal.rgb, normalize(lightPosition));
    n_dot_l = fmax(0.0, n_dot_l);
    out.color = half4(materialUniforms.emissiveColor + n_dot_l);

    // Pass through texture coordinate
    out.texcoord = in.texcoord;
    
    return out;
}

// Fragment shader function
fragment half4 fragmentLight(ShaderInOut in [[stage_in]],
                             texture2d<half>  diffuseTexture [[ texture(AAPLDiffuseTextureIndex) ]]) {
    constexpr sampler defaultSampler;
    
    // Blend texture color with input color and output to framebuffer
    half4 color =  diffuseTexture.sample(defaultSampler, float2(in.texcoord)) * in.color;
    
    return color;
}