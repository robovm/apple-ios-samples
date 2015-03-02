/*
 Copyright (C) 2015 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 lighting shader for Metal Instanced Helix. Note the use of instance_id to access the correct instance's data.
 */

#include <metal_stdlib>
#include <simd/simd.h>
#include "AAPLSharedTypes.h"

using namespace metal;

// variables in constant address space
constant float3 light_position = float3(0.0, 1.0, -1.0);

typedef struct
{
	packed_float3 position;
	packed_float3 normal;
} vertex_t;

struct ColorInOut {
    float4 position [[position]];
    half4 color;
};

// vertex shader function
vertex ColorInOut lighting_vertex(device vertex_t* vertex_array [[ buffer(0) ]],
                                  constant AAPL::constants_t* constants [[ buffer(1) ]],
                                  unsigned int iid [[ instance_id ]],
                                  unsigned int vid [[ vertex_id ]])
{
    ColorInOut out;
    
	float4 in_position = float4(float3(vertex_array[vid].position), 1.0);
    out.position = constants[iid].modelview_projection_matrix * in_position;
    
    float3 normal = vertex_array[vid].normal;
    float4 eye_normal = normalize(constants[iid].normal_matrix * float4(normal, 0.0));
    float n_dot_l = dot(eye_normal.rgb, normalize(light_position));
    n_dot_l = fmax(0.0, n_dot_l);
    
    out.color = half4(constants[iid].ambient_color + constants[iid].diffuse_color * n_dot_l);
    
    return out;
}

// fragment shader function
fragment half4 lighting_fragment(ColorInOut in [[stage_in]])
{
    return in.color;
};

