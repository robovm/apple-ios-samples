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

namespace AAPL
{
    struct constants_t
    {
        simd::float4x4 modelview_projection_matrix;
        simd::float4x4 normal_matrix;
        simd::float4   ambient_color;
        simd::float4   diffuse_color;
        int            multiplier;
    } __attribute__ ((aligned (256)));
}

#endif

#endif