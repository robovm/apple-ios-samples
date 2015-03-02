/*
 Copyright (C) 2014 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 
    Shared data types between CPU code and metal shader code
  
 */


#ifndef _AAPL_SHARED_TYPES_H_
#define _AAPL_SHARED_TYPES_H_

#import <simd/simd.h>

#ifdef __cplusplus

namespace AAPL
{
    typedef struct
    {
        simd::float4x4 model_matrix;
        simd::float4x4 view_matrix;
        simd::float4x4 projection_matrix;
        float t;
        float lifespan;
    } uniforms_t;
}

#endif

#endif