/*
 Copyright (C) 2015 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 Utility methods for linear transformations of projective geometry of the left  right handed coordinate systems.
 */

#ifndef _AAPL_MATH_UTILITIES_H_
#define _AAPL_MATH_UTILITIES_H_

#import <simd/simd.h>

#ifdef __cplusplus

namespace AAPL
{
    namespace Math
    {
        // Convert from degree to radians
        float radians(const float& degrees);
        
        // Construct a float 2x2 matrix from an array
        // of floats with 4 elements
        simd::float2x2 float2x2(const bool& transpose,
                                const float * const M);
        
        // Construct a float 3x4 matrix from an array
        // of floats with 9 elements
        simd::float3x3  float3x3(const bool& transpose,
                                 const float  * const M);
        
        // Construct a float 4x4 matrix from an array
        // of floats with 16 elements
        simd::float4x4 float4x4(const bool& transpose,
                                const float * const M);
        
        // Construct a float 3x3 matrix from a 4x4 matrix
        simd::float3x3 float3x3(const bool& transpose,
                                const simd::float4x4& M);
        
        // Construct a float 4x4 matrix from a 3x3 matrix
        simd::float4x4 float4x4(const bool& transpose,
                                const simd::float3x3& M);
        
        // Return a scale linear transformation matrix
        simd::float4x4 scale(const float& x,
                             const float& y,
                             const float& z);
        
        // Return a scale linear transformation matrix
        simd::float4x4 scale(const simd::float3& s);
        
        // Return a translation linear transformation matrix
        simd::float4x4 translate(const float& x,
                                 const float& y,
                                 const float& z);
        
        // Return a translation linear transformation matrix
        simd::float4x4 translate(const simd::float3& t);
        
        // Left-handed [linear] transformations
        namespace LHT
        {
            simd::float4x4 rotate(const float& angle,
                                  const float& x,
                                  const float& y,
                                  const float& z);
            
            simd::float4x4 rotate(const float& angle,
                                  const simd::float3& u);
            
            simd::float4x4 frustum(const float& fovH,
                                   const float& fovV,
                                   const float& near,
                                   const float& far);
            
            simd::float4x4 frustum(const float& left,
                                   const float& right,
                                   const float& bottom,
                                   const float& top,
                                   const float& near,
                                   const float& far);
            
            simd::float4x4 frustum_oc(const float& left,
                                      const float& right,
                                      const float& bottom,
                                      const float& top,
                                      const float& near,
                                      const float& far);
            
            simd::float4x4 lookAt(const float * const pEye,
                                  const float * const pCenter,
                                  const float * const pUp);
            
            simd::float4x4 lookAt(const simd::float3& eye,
                                  const simd::float3& center,
                                  const simd::float3& up);
            
            simd::float4x4 perspective(const float& width,
                                       const float& height,
                                       const float& near,
                                       const float& far);
            
            simd::float4x4 perspective_fov(const float& fovy,
                                           const float& aspect,
                                           const float& near,
                                           const float& far);
            
            simd::float4x4 perspective_fov(const float& fovy,
                                           const float& width,
                                           const float& height,
                                           const float& near,
                                           const float& far);
            
            simd::float4x4 ortho2d_oc(const float& left,
                                      const float& right,
                                      const float& bottom,
                                      const float& top,
                                      const float& near,
                                      const float& far);
            
            simd::float4x4 ortho2d_oc(const simd::float3& origin,
                                      const simd::float3& size);
            
            simd::float4x4 ortho2d(const float& left,
                                   const float& right,
                                   const float& bottom,
                                   const float& top,
                                   const float& near,
                                   const float& far);
            
            simd::float4x4 ortho2d(const simd::float3& origin,
                                   const simd::float3& size);
        } // LHT
        
        // Right-handed [linear] transformations
        namespace RHT
        {
            simd::float4x4 rotate(const float& angle,
                                  const simd::float3& r);
            
            simd::float4x4 rotate(const float& angle,
                                  const float& x,
                                  const float& y,
                                  const float& z);
            
            simd::float4x4 frustum(const float& left,
                                   const float& right,
                                   const float& bottom,
                                   const float& top,
                                   const float& near,
                                   const float& far);
            
            simd::float4x4 frustum(const float& fovy,
                                   const float& width,
                                   const float& heigth,
                                   const float& near,
                                   const float& far);
            
            simd::float4x4 frustum(const float& fovy,
                                   const float& aspect,
                                   const float& near,
                                   const float& far);
            
            simd::float4x4 lookAt(const float * const pEye,
                                  const float * const pCenter,
                                  const float * const pUp);
            
            simd::float4x4 lookAt(const simd::float3& eye,
                                  const simd::float3& center,
                                  const simd::float3& up);
            
            simd::float4x4 perspective(const float& fovy,
                                       const float& aspect,
                                       const float& near,
                                       const float& far);
            
            simd::float4x4 perspective(const float& fovy,
                                       const float& width,
                                       const float& height,
                                       const float& near,
                                       const float& far);
            
            simd::float4x4 projection(const float& fovy,
                                      const float& aspect,
                                      const float& near,
                                      const float& far);
            
            simd::float4x4 projection(const float& fovy,
                                      const float& width,
                                      const float& height,
                                      const float& near,
                                      const float& far);
            
            simd::float4x4 ortho2d(const float& left,
                                   const float& right,
                                   const float& bottom,
                                   const float& top,
                                   const float& near,
                                   const float& far);
            
            simd::float4x4 ortho2d(const float& left,
                                   const float& right,
                                   const float& bottom,
                                   const float& top);
            
            simd::float4x4 ortho2d(const simd::float3& origin,
                                   const simd::float3& size);
        } // RHT
    } // Math
    
    // OpenGL Utilities
    namespace GLU
    {
        namespace uniform
        {
            // modifies the value of a 2x2 float matrix uniform variable
            void matrix2fv(const int& location,
                           const bool& transpose,
                           const simd::float2x2& M);
            
            // modifies the value of a 2x2 float matrix uniform variable
            void matrix2fv(const int& location,
                           const int& count,
                           const bool& transpose,
                           const simd::float2x2& M);
            
            // modifies the value of a 3x3 float matrix uniform variable
            void matrix3fv(const int& location,
                           const bool& transpose,
                           const simd::float3x3& M);
            
            // modifies the value of a 3x3 float matrix uniform variable
            void matrix3fv(const int& location,
                           const int& count,
                           const bool& transpose,
                           const simd::float3x3& M);
            
            // modifies the value of a 4x4 float matrix uniform variable
            void matrix4fv(const int& location,
                           const bool& transpose,
                           const simd::float4x4& M);
            
            // modifies the value of a 4x4 float matrix uniform variable
            void matrix4fv(const int& location,
                           const int& count,
                           const bool& transpose,
                           const simd::float4x4& M);
        } // uniform
    } // GLU
} // AAPL

#endif

#endif
