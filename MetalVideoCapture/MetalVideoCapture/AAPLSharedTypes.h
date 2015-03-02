/*
 Copyright (C) 2015 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 Shared data types between CPU code and metal shader code
 */

#ifndef _AAPL_SHARED_TYPES_H_
#define _AAPL_SHARED_TYPES_H_

#import <simd/simd.h>

#ifdef __cplusplus

#define QUAD_VERTEX_BUFFER 0
#define QUAD_VERTEX_CONSTANT_BUFFER 1
#define QUAD_FRAGMENT_CONSTANT_BUFFER 0

#define QUAD_ENVMAP_TEXTURE 0
#define QUAD_IMAGE_TEXTURE 1

#define SKYBOX_VERTEX_BUFFER 0
#define SKYBOX_TEXCOORD_BUFFER 1
#define SKYBOX_CONSTANT_BUFFER 2
#define SKYBOX_IMAGE_TEXTURE 0


namespace AAPL
{
    typedef enum : int
    {
        Unknown,
        Portrait,
        PortraitUpsideDown,
        LandscapeLeft,
        LandscapeRight
    } Orientation;
    
    typedef struct
    {
        simd::float4x4 modelview_matrix;
        simd::float4x4 modelview_projection_matrix;
        simd::float4x4 normal_matrix;
        simd::float4x4 inverted_view_matrix;
        simd::float4x4 skybox_modelview_projection_matrix;
        simd::float4x4 _reserved;
        simd::float4x4 _reserved1;
        Orientation orientation;
    } uniforms_t;
}

#endif // cplusplus

#endif // _AAPL_SHARED_TYPES_H_