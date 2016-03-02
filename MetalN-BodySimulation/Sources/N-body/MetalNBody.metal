/*
 Copyright (C) 2015 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 Fragment and vertex shaders, and the compute kernel for N-body simulation.
 */

#import <metal_stdlib>

#import "NBodyComputePrefs.h"

using namespace metal;

//--------------------------------------------------
//
// Vertex and fragment shaders for n-body simulation
//
//--------------------------------------------------

typedef struct
{
    float4 position  [[position]];
    half4  color;
    float  pointSize [[point_size]];
} FragColor;

vertex FragColor NBodyLightingVertex(device float4*     positionRead        [[ buffer(0) ]],
                                     device float4*     color               [[ buffer(1) ]],
                                     constant float4x4& modelViewProjection [[ buffer(2) ]],
                                     constant float&    pointSize           [[ buffer(3) ]],
                                     uint               vid                 [[ vertex_id ]])
{
    FragColor outColor;
    
    outColor.pointSize = pointSize;
    outColor.color     = half4(color[vid]);
    
    float4 inPosition = float4(float3(positionRead[vid]), 1.0);
    
    outColor.position = float4(modelViewProjection * inPosition);
    
    return outColor;
} // NBodyLightingVertex

fragment half4 NBodyLightingFragment(FragColor        inColor      [[ stage_in    ]],
                                     texture2d<half>  splatTexture [[ texture(0)  ]],
                                     sampler          sam          [[ sampler(0)  ]],
                                     float2           texcoord     [[ point_coord ]])
{
    half4 c = splatTexture.sample(sam, texcoord);
    
    half4 fragColor = (0.6h + 0.4h * inColor.color) * c;
    
    half4 x = half4(0.1h, 0.0h, 0.0h, fragColor.w);
    half4 y = half4(1.0h, 0.7h, 0.3h, fragColor.w);
    half  a = fragColor.w;
    
    return fragColor * mix(x, y, a);
} // NBodyLightingFragment

//--------------------------------------
//
// Compute Kernel for n-body simulation
//
//--------------------------------------

typedef NBody::Compute::Prefs NBodyPrefs;

static float3 NBodyComputeForce(const float4 pos_1,
                                const float4 pos_0,
                                const float  softeningSqr)
{
    float3 r = pos_1.xyz - pos_0.xyz;
    
    float distSqr = distance_squared(pos_1.xyz, pos_0.xyz);
    
    distSqr += softeningSqr;
    
    float invDist  = rsqrt(distSqr);
    float invDist3 = invDist * invDist * invDist;
    
    float s = pos_1.w * invDist3;
    
    return r * s;
} // NBodyComputeForce

kernel void NBodyIntegrateSystem(device float4* const   pos_1 [[ buffer(0)                      ]],   // new position
                                 device float4* const   vel_1 [[ buffer(1)                      ]],   // new velocity
                                 constant float4* const pos_0 [[ buffer(2)                      ]],   // old position
                                 constant float4* const vel_0 [[ buffer(3)                      ]],   // old velocity
                                 constant NBodyPrefs&   prefs [[ buffer(4)                      ]],
                                 threadgroup float4*    pos_s [[ threadgroup(0)                 ]],   // shared position
                                 const ushort           gid   [[ thread_position_in_grid        ]],
                                 const ushort           lid   [[ thread_position_in_threadgroup ]],
                                 const ushort           lsize [[ threads_per_threadgroup        ]])
{
    ushort tile = 0;
    ushort k    = lid;
    
    float4 pos  = pos_0[gid];
    float4 vel  = 0.0f;
    float3 acc  = 0.0f;
    
    ushort i, j;
    
    const ushort particles    = prefs.particles;
    const float  softeningSqr = prefs.softeningSqr;
    
    for(i = 0; i < particles ; i += lsize, ++tile)
    {
        pos_s[lid] = pos_0[k];
        
        j = 0;
        
        while(j < lsize)
        {
            acc += NBodyComputeForce(pos_s[j++], pos, softeningSqr);
            acc += NBodyComputeForce(pos_s[j++], pos, softeningSqr);
            acc += NBodyComputeForce(pos_s[j++], pos, softeningSqr);
            acc += NBodyComputeForce(pos_s[j++], pos, softeningSqr);
            acc += NBodyComputeForce(pos_s[j++], pos, softeningSqr);
            acc += NBodyComputeForce(pos_s[j++], pos, softeningSqr);
            acc += NBodyComputeForce(pos_s[j++], pos, softeningSqr);
            acc += NBodyComputeForce(pos_s[j++], pos, softeningSqr);
        } // for
        
        k += lsize;
    } // for
    
    vel = vel_0[gid];
    
    vel.xyz += acc * prefs.timestep;
    vel.xyz *= prefs.damping;
    pos.xyz += vel.xyz * prefs.timestep;
    
    pos_1[gid] = pos;
    vel_1[gid] = vel;
} // NBodyIntegrateSystem
