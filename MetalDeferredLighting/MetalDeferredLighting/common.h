/*
 Copyright (C) 2014 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 
     Common structures shared across shaders
  
 */

#ifndef MetalDeferredLighting_common_h
#define MetalDeferredLighting_common_h

#include <simd/simd.h>

#ifdef __cplusplus

namespace AAPL
{
    using namespace simd;
    
    typedef struct
    {
        float4 albedo [[color(0)]];
        float4 normal [[color(1)]];
        float  depth [[color(2)]];
        float4 light [[color(3)]];
    } FragOutput;
    
    typedef struct
    {
        float4 clear_color;
        float4 linear_depth_clear_color;
        float4 light_buffer_clear_color;
        float4 albedo_clear_color;
    } ClearColorBuffers;
    
    typedef struct
    {
        float4 sunDirection;
        float4 sunColor;
    } MaterialSunData;
    
    typedef struct
    {
        float4x4 mvpMatrix;
        float4x4 mvMatrix;
    } LightModelMatrices;
    
    typedef struct
    {
        float4   light_position;
        float4   view_light_position;
        float4   light_color_radius;
    } LightFragmentInputs;
    
    typedef struct
    {
        float4x4 normalMatrix;
        float4x4 mvMatrix;
        float4x4 mvpMatrix;
        float4x4 shadowMatrix;
    } ModelMatrices;
    
    typedef struct
    {
        float4   con_scale_intensity;
    } SpriteData;
}

#endif

#endif
