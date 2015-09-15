/*
 Copyright (C) 2015 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 Utility methods for linear transformations of projective geometry of the left  right handed coordinate systems.
 */

#pragma mark -
#pragma mark Private - Headers

#import <cmath>
#import <iostream>

#import <OpenGLES/ES3/gl.h>

#import "AAPLTransforms.h"

#pragma mark -
#pragma mark Private - Constants

static const float kPi_f      = float(M_PI);
static const float k1Div180_f = 1.0f / 180.0f;
static const float kRadians_f = k1Div180_f * kPi_f;

#pragma mark -
#pragma mark Private - Utilities

float AAPL::Math::radians(const float& degrees)
{
    return kRadians_f * degrees;
} // radians

#pragma mark -
#pragma mark Public - Transformations - Constructors

// Construct a float 2x2 matrix from an array
// of floats with 4 elements
simd::float2x2 AAPL::Math::float2x2(const bool& transpose,
                                    const float * const M)
{
    simd::float2x2 N = 0.0;
    
    if(M != nullptr)
    {
        simd::float2 v[2] = {0.0, 0.0};
        
        v[0] = { M[0], M[1] };
        v[1] = { M[2], M[3] };
        
        N = (transpose)
        ? matrix_from_rows(v[0], v[1])
        : matrix_from_columns(v[0], v[1]);
    }
    else
    {
        N = matrix_identity_float2x2;
    } // else
    
    return N;
} // float2x2

// Construct a float 3x3 matrix from an array
// of floats with 9 elements
simd::float3x3  AAPL::Math::float3x3(const bool& transpose,
                                     const float  * const M)
{
    simd::float3x3 N = 0.0;
    
    if(M != nullptr)
    {
        simd::float3 v[3] = {0.0, 0.0, 0.0};
        
        v[0] = { M[0], M[1], M[2] };
        v[1] = { M[3], M[4], M[5] };
        v[2] = { M[6], M[7], M[8] };
        
        N = (transpose)
        ? matrix_from_rows(v[0], v[1], v[2])
        : matrix_from_columns(v[0], v[1], v[2]);
    }
    else
    {
        N = matrix_identity_float3x3;
    } // else
    
    return N;
} // float3x3

// Construct a float 4x4 matrix from an array
// of floats with 16 elements
simd::float4x4 AAPL::Math::float4x4(const bool& transpose,
                                    const float * const M)
{
    simd::float4x4 N = 0.0;
    
    if(M != nullptr)
    {
        simd::float4 v[4] = {0.0, 0.0, 0.0, 0.0};
        
        v[0] = {  M[0],  M[1],  M[2],  M[3] };
        v[1] = {  M[4],  M[5],  M[6],  M[7] };
        v[2] = {  M[8],  M[9], M[10], M[11] };
        v[3] = { M[12], M[13], M[14], M[15] };
        
        N = (transpose)
        ? matrix_from_rows(v[0], v[1], v[2], v[3])
        : matrix_from_columns(v[0], v[1], v[2], v[3]);
    }
    else
    {
        N = matrix_identity_float4x4;
    } // else
    
    return N;
} // float4x4

// Construct a float 3x3 matrix from a 4x4 matrix
simd::float3x3 AAPL::Math::float3x3(const bool& transpose,
                                    const simd::float4x4& M)
{
    simd::float3 P = M.columns[0].xyz;
    simd::float3 Q = M.columns[1].xyz;
    simd::float3 R = M.columns[2].xyz;
    
    return (transpose) ? matrix_from_rows(P, Q, R) : matrix_from_columns(P, Q, R);
} // float3x3

// Construct a float 4x4 matrix from a 3x3 matrix
simd::float4x4 AAPL::Math::float4x4(const bool& transpose,
                                    const simd::float3x3& M)
{
    simd::float4 P = 0.0f;
    simd::float4 Q = 0.0f;
    simd::float4 R = 0.0f;
    simd::float4 S = {0.0f, 0.0f, 0.0f, 1.0f};
    
    P.xyz = M.columns[0];
    Q.xyz = M.columns[1];
    R.xyz = M.columns[2];
    
    return (transpose) ? matrix_from_rows(P, Q, R, S) : matrix_from_columns(P, Q, R, S);
} // float4x4

#pragma mark -
#pragma mark Public - Transformations - Scale

simd::float4x4 AAPL::Math::scale(const float& x,
                                 const float& y,
                                 const float& z)
{
    simd::float4 v = {x, y, z, 1.0f};
    
    return simd::float4x4(v);
} // scale

simd::float4x4 AAPL::Math::scale(const simd::float3& s)
{
    simd::float4 v = {s.x, s.y, s.z, 1.0f};
    
    return simd::float4x4(v);
} // scale

#pragma mark -
#pragma mark Public - Transformations - Translate

simd::float4x4 AAPL::Math::translate(const simd::float3& t)
{
    simd::float4x4 M = matrix_identity_float4x4;
    
    M.columns[3].xyz = t;
    
    return M;
} // translate

simd::float4x4 AAPL::Math::translate(const float& x,
                                     const float& y,
                                     const float& z)
{
    return AAPL::Math::translate((simd::float3){x,y,z});
} // translate

#pragma mark -
#pragma mark Public - Transformations - Left-Handed - Rotate

static float AAPLRadiansOverPi(const float& degrees)
{
    return (degrees * k1Div180_f);
} // AAPLRadiansOverPi

simd::float4x4 AAPL::Math::LHT::rotate(const float& angle,
                                       const simd::float3& r)
{
    float a = AAPLRadiansOverPi(angle);
    float c = 0.0f;
    float s = 0.0f;
    
    // Computes the sine and cosine of pi times angle (measured in radians)
    // faster and gives exact results for angle = 90, 180, 270, etc.
    __sincospif(a, &s, &c);
    
    float k = 1.0f - c;
    
    simd::float3 u = simd::normalize(r);
    simd::float3 v = s * u;
    simd::float3 w = k * u;
    
    simd::float4 P = 0.0f;
    simd::float4 Q = 0.0f;
    simd::float4 R = 0.0f;
    simd::float4 S = 0.0f;
    
    P.x = w.x * u.x + c;
    P.y = w.x * u.y + v.z;
    P.z = w.x * u.z - v.y;
    
    Q.x = w.x * u.y - v.z;
    Q.y = w.y * u.y + c;
    Q.z = w.y * u.z + v.x;
    
    R.x = w.x * u.z + v.y;
    R.y = w.y * u.z - v.x;
    R.z = w.z * u.z + c;
    
    S.w = 1.0f;
    
    return simd::float4x4(P, Q, R, S);
} // rotate

simd::float4x4 AAPL::Math::LHT::rotate(const float& angle,
                                       const float& x,
                                       const float& y,
                                       const float& z)
{
    simd::float3 r = {x, y, z};
    
    return AAPL::Math::LHT::rotate(angle, r);
} // rotate

#pragma mark -
#pragma mark Public - Transformations - Left-Handed - Perspective

simd::float4x4 AAPL::Math::LHT::perspective(const float& width,
                                            const float& height,
                                            const float& near,
                                            const float& far)
{
    float zNear = 2.0f * near;
    float zFar  = far / (far - near);
    
    simd::float4 P = 0.0f;
    simd::float4 Q = 0.0f;
    simd::float4 R = 0.0f;
    simd::float4 S = 0.0f;
    
    P.x =  zNear / width;
    Q.y =  zNear / height;
    R.z =  zFar;
    R.w =  1.0f;
    S.z = -near * zFar;
    
    return simd::float4x4(P, Q, R, S);
} // perspective

simd::float4x4 AAPL::Math::LHT::perspective_fov(const float& fovy,
                                                const float& aspect,
                                                const float& near,
                                                const float& far)
{
    float angle  = AAPL::Math::radians(0.5f * fovy);
    float yScale = 1.0f/ std::tan(angle);
    float xScale = yScale / aspect;
    float zScale = far / (far - near);
    
    simd::float4 P = 0.0f;
    simd::float4 Q = 0.0f;
    simd::float4 R = 0.0f;
    simd::float4 S = 0.0f;
    
    P.x =  xScale;
    Q.y =  yScale;
    R.z =  zScale;
    R.w =  1.0f;
    S.z = -near * zScale;
    
    return simd::float4x4(P, Q, R, S);
} // perspective_fov

simd::float4x4 AAPL::Math::LHT::perspective_fov(const float& fovy,
                                                const float& width,
                                                const float& height,
                                                const float& near,
                                                const float& far)
{
    float aspect = width / height;
    
    return AAPL::Math::LHT::perspective_fov(fovy, aspect, near, far);
} // perspective_fov

#pragma mark -
#pragma mark Public - Transformations - Left-Handed - LookAt

simd::float4x4 AAPL::Math::LHT::lookAt(const simd::float3& eye,
                                       const simd::float3& center,
                                       const simd::float3& up)
{
    simd::float3 E = -eye;
    simd::float3 N = simd::normalize(center + E);
    simd::float3 U = simd::normalize(simd::cross(up, N));
    simd::float3 V = simd::cross(N, U);
    
    simd::float4 P = 0.0f;
    simd::float4 Q = 0.0f;
    simd::float4 R = 0.0f;
    simd::float4 S = 0.0f;
    
    P.x = U.x;
    P.y = V.x;
    P.z = N.x;
    
    Q.x = U.y;
    Q.y = V.y;
    Q.z = N.y;
    
    R.x = U.z;
    R.y = V.z;
    R.z = N.z;
    
    S.x = simd::dot(U, E);
    S.y = simd::dot(V, E);
    S.z = simd::dot(N, E);
    S.w = 1.0f;
    
    return simd::float4x4(P, Q, R, S);
} // lookAt

simd::float4x4 AAPL::Math::LHT::lookAt(const float * const pEye,
                                       const float * const pCenter,
                                       const float * const pUp)
{
    simd::float3 eye    = {pEye[0], pEye[1], pEye[2]};
    simd::float3 center = {pCenter[0], pCenter[1], pCenter[2]};
    simd::float3 up     = {pUp[0], pUp[1], pUp[2]};
    
    return AAPL::Math::LHT::lookAt(eye, center, up);
} // lookAt

#pragma mark -
#pragma mark Public - Transformations - Left-Handed - Orthographic

simd::float4x4 AAPL::Math::LHT::ortho2d(const float& left,
                                        const float& right,
                                        const float& bottom,
                                        const float& top,
                                        const float& near,
                                        const float& far)
{
    float sLength = 1.0f / (right - left);
    float sHeight = 1.0f / (top   - bottom);
    float sDepth  = 1.0f / (far   - near);
    
    simd::float4 P = 0.0f;
    simd::float4 Q = 0.0f;
    simd::float4 R = 0.0f;
    simd::float4 S = 0.0f;
    
    P.x =  2.0f * sLength;
    Q.y =  2.0f * sHeight;
    R.z =  sDepth;
    S.z = -near  * sDepth;
    S.w =  1.0f;
    
    return simd::float4x4(P, Q, R, S);
} // ortho2d

simd::float4x4 AAPL::Math::LHT::ortho2d(const simd::float3& origin,
                                        const simd::float3& size)
{
    return AAPL::Math::LHT::ortho2d(origin.x, origin.y, origin.z, size.x, size.y, size.z);
} // ortho2d

#pragma mark -
#pragma mark Public - Transformations - Left-Handed - Off-Center Orthographic

simd::float4x4 AAPL::Math::LHT::ortho2d_oc(const float& left,
                                           const float& right,
                                           const float& bottom,
                                           const float& top,
                                           const float& near,
                                           const float& far)
{
    float sLength = 1.0f / (right - left);
    float sHeight = 1.0f / (top   - bottom);
    float sDepth  = 1.0f / (far   - near);
    
    simd::float4 P = 0.0f;
    simd::float4 Q = 0.0f;
    simd::float4 R = 0.0f;
    simd::float4 S = 0.0f;
    
    P.x =  2.0f * sLength;
    Q.y =  2.0f * sHeight;
    R.z =  sDepth;
    S.x = -sLength * (left + right);
    S.y = -sHeight * (top + bottom);
    S.z = -sDepth  * near;
    S.w =  1.0f;
    
    return simd::float4x4(P, Q, R, S);
} // ortho2d_oc

simd::float4x4 AAPL::Math::LHT::ortho2d_oc(const simd::float3& origin,
                                           const simd::float3& size)
{
    return AAPL::Math::LHT::ortho2d_oc(origin.x, origin.y, origin.z, size.x, size.y, size.z);
} // ortho2d_oc

#pragma mark -
#pragma mark Public - Transformations - Left-Handed - frustum

simd::float4x4 AAPL::Math::LHT::frustum(const float& fovH,
                                        const float& fovV,
                                        const float& near,
                                        const float& far)
{
    float width  = 1.0f / std::tan(AAPL::Math::radians(0.5f * fovH));
    float height = 1.0f / std::tan(AAPL::Math::radians(0.5f * fovV));
    float sDepth = far / ( far - near );
    
    simd::float4 P = 0.0f;
    simd::float4 Q = 0.0f;
    simd::float4 R = 0.0f;
    simd::float4 S = 0.0f;
    
    P.x =  width;
    Q.y =  height;
    R.z =  sDepth;
    R.w =  1.0f;
    S.z = -sDepth * near;
    
    return simd::float4x4(P, Q, R, S);
} // frustum

simd::float4x4 AAPL::Math::LHT::frustum(const float& left,
                                        const float& right,
                                        const float& bottom,
                                        const float& top,
                                        const float& near,
                                        const float& far)
{
    float width  = right - left;
    float height = top   - bottom;
    float depth  = far   - near;
    float sDepth = far / depth;
    
    simd::float4 P = 0.0f;
    simd::float4 Q = 0.0f;
    simd::float4 R = 0.0f;
    simd::float4 S = 0.0f;
    
    P.x =  width;
    Q.y =  height;
    R.z =  sDepth;
    R.w =  1.0f;
    S.z = -sDepth * near;
    
    return simd::float4x4(P, Q, R, S);
} // frustum

simd::float4x4 AAPL::Math::LHT::frustum_oc(const float& left,
                                           const float& right,
                                           const float& bottom,
                                           const float& top,
                                           const float& near,
                                           const float& far)
{
    float sWidth  = 1.0f / (right - left);
    float sHeight = 1.0f / (top   - bottom);
    float sDepth  = far  / (far   - near);
    float dNear   = 2.0f * near;
    
    simd::float4 P = 0.0f;
    simd::float4 Q = 0.0f;
    simd::float4 R = 0.0f;
    simd::float4 S = 0.0f;
    
    P.x =  dNear * sWidth;
    Q.y =  dNear * sHeight;
    R.x = -sWidth  * (right + left);
    R.y = -sHeight * (top   + bottom);
    R.z =  sDepth;
    R.w =  1.0f;
    S.z = -sDepth * near;
    
    return simd::float4x4(P, Q, R, S);
} // frustum_oc

#pragma mark -
#pragma mark Public - Transformations - Right-Handed - Rotate

simd::float4x4 AAPL::Math::RHT::rotate(const float& angle,
                                       const simd::float3& r)
{
    float a = angle / 180.0f;
    float c = 0.0f;
    float s = 0.0f;
    
    // Computes the sine and cosine of pi times angle (measured in radians)
    // faster and gives exact results for angle = 90, 180, 270, etc.
    __sincospif(a, &s, &c);
    
    float k = 1.0f - c;
    
    simd::float3 u = simd::normalize(r);
    simd::float3 v = s * u;
    simd::float3 w = k * u;
    
    simd::float4 P = 0.0f;
    simd::float4 Q = 0.0f;
    simd::float4 R = 0.0f;
    simd::float4 S = 0.0f;
    
    P.x = w.x * u.x + c;
    P.y = w.x * u.y - v.z;
    P.z = w.x * u.z + v.y;
    
    Q.x = w.y * u.x + v.z;
    Q.y = w.y * u.y + c;
    Q.z = w.y * u.z - v.x;
    
    R.x = w.z * u.x - v.y;
    R.y = w.z * u.y + v.x;
    R.z = w.z * u.z + c;
    
    S.w = 1.0f;
    
    return simd::float4x4(P, Q, R, S);
} // Rotate

simd::float4x4 AAPL::Math::RHT::rotate(const float& angle,
                                       const float& x,
                                       const float& y,
                                       const float& z)
{
    simd::float3 r = {x, y, z};
    
    return AAPL::Math::RHT::rotate(angle, r);
} // Rotate

#pragma mark -
#pragma mark Public - Transformations - Right-Handed - Perspective

simd::float4x4 AAPL::Math::RHT::perspective(const float& fovy,
                                            const float& aspect,
                                            const float& near,
                                            const float& far)
{
    
    float a = AAPL::Math::radians(0.5f * fovy);
    float f = 1.0f / std::tan(a);
    
    float sNear  = 2.0f * near;
    float sDepth = 1.0f / (near - far);
    
    simd::float4 P = 0.0f;
    simd::float4 Q = 0.0f;
    simd::float4 R = 0.0f;
    simd::float4 S = 0.0f;
    
    P.x =  f / aspect;
    Q.y =  f;
    R.z =  sDepth * (far + near);
    R.w = -1.0f;
    S.z =  sNear * sDepth * far;
    
    return simd::float4x4(P, Q, R, S);
} // perspective

simd::float4x4 AAPL::Math::RHT::perspective(const float& fovy,
                                            const float& width,
                                            const float& height,
                                            const float& near,
                                            const float& far)
{
    float aspect = width / height;
    
    return AAPL::Math::RHT::perspective(fovy, aspect, near, far);
} // perspective

#pragma mark -
#pragma mark Public - Transformations - Right-Handed - Projection

simd::float4x4 AAPL::Math::RHT::projection(const float& fovy,
                                           const float& aspect,
                                           const float& near,
                                           const float& far)
{
    float sNear = 2.0f * near;
    
    float a = AAPL::Math::radians(0.5f * fovy);
    float f = near * std::tan(a);
    
    float left   = -f * aspect;
    float right  =  f * aspect;
    float bottom = -f;
    float top    =  f;
    
    float sWidth  = 1.0f / (right - left);
    float sHeight = 1.0f / (top - bottom);
    float sDepth  = 1.0f / (near - far);
    
    simd::float4 P = 0.0f;
    simd::float4 Q = 0.0f;
    simd::float4 R = 0.0f;
    simd::float4 S = 0.0f;
    
    P.x =  sNear * sWidth;
    Q.y =  sNear * sHeight;
    R.z =  sDepth * (far + near);
    R.w = -1.0f;
    S.z =  sNear * sDepth * far;
    
    return simd::float4x4(P, Q, R, S);
} // projection

simd::float4x4 AAPL::Math::RHT::projection(const float& fovy,
                                           const float& width,
                                           const float& height,
                                           const float& near,
                                           const float& far)
{
    float aspect = width / height;
    
    return AAPL::Math::RHT::projection(fovy, aspect, near, far);
} // projection

#pragma mark -
#pragma mark Public - Transformations - Right-Handed - LookAt

simd::float4x4 AAPL::Math::RHT::lookAt(const simd::float3& eye,
                                       const simd::float3& center,
                                       const simd::float3& up)
{
    simd::float3 E = -eye;
    simd::float3 N = simd::normalize(eye - center);
    simd::float3 U = simd::normalize(simd::cross(up, N));
    simd::float3 V = simd::cross(N, U);
    
    simd::float4 P = 0.0f;
    simd::float4 Q = 0.0f;
    simd::float4 R = 0.0f;
    simd::float4 S = 0.0f;
    
    P.x = U.x;
    P.y = U.y;
    P.z = U.z;
    P.w = simd::dot(U, E);
    
    Q.x = V.x;
    Q.y = V.y;
    Q.z = V.z;
    Q.w = simd::dot(V, E);
    
    R.x = N.x;
    R.y = N.y;
    R.z = N.z;
    R.w = simd::dot(N, E);
    
    S.w = 1.0f;
    
    return simd::float4x4(P, Q, R, S);
} // lookAt

simd::float4x4 AAPL::Math::RHT::lookAt(const float * const pEye,
                                       const float * const pCenter,
                                       const float * const pUp)
{
    simd::float3 eye    = {pEye[0], pEye[1], pEye[2]};
    simd::float3 center = {pCenter[0], pCenter[1], pCenter[2]};
    simd::float3 up     = {pUp[0], pUp[1], pUp[2]};
    
    return AAPL::Math::RHT::lookAt(eye, center, up);
} // lookAt

#pragma mark -
#pragma mark Public - Transformations - Right-Handed - Orthographic

simd::float4x4 AAPL::Math::RHT::ortho2d(const float& left,
                                        const float& right,
                                        const float& bottom,
                                        const float& top,
                                        const float& near,
                                        const float& far)
{
    float sWidth  = 1.0f / (right - left);
    float sHeight = 1.0f / (top   - bottom);
    float sDepth  = 1.0f / (far   - near);
    
    simd::float4 P = 0.0f;
    simd::float4 Q = 0.0f;
    simd::float4 R = 0.0f;
    simd::float4 S = 0.0f;
    
    P.x =  2.0f * sWidth;
    Q.y =  2.0f * sHeight;
    R.z = -2.0f * sDepth;
    S.x = -sWidth  * (right + left);
    S.y = -sHeight * (top   + bottom);
    S.z = -sDepth  * (far   + near);
    S.w =  1.0f;
    
    return simd::float4x4(P, Q, R, S);
} // ortho2d

simd::float4x4 AAPL::Math::RHT::ortho2d(const float& left,
                                        const float& right,
                                        const float& bottom,
                                        const float& top)
{
    return AAPL::Math::RHT::ortho2d(left, right, bottom, top, 0.0f, 1.0f);
} // ortho2d

simd::float4x4 AAPL::Math::RHT::ortho2d(const simd::float3& origin,
                                        const simd::float3& size)
{
    return AAPL::Math::RHT::ortho2d(origin.x, origin.y, origin.z, size.x, size.y, size.z);
} // ortho2d

#pragma mark -
#pragma mark Public - Transformations - Right-Handed - Frustum

simd::float4x4 AAPL::Math::RHT::frustum(const float& left,
                                        const float& right,
                                        const float& bottom,
                                        const float& top,
                                        const float& near,
                                        const float& far)
{
    float sWidth  = 1.0f / (right - left);
    float sHeight = 1.0f / (top - bottom);
    float sDepth  = 1.0f / (near - far);
    float sNear   = 2.0f * near;
    
    simd::float4 P = 0.0f;
    simd::float4 Q = 0.0f;
    simd::float4 R = 0.0f;
    simd::float4 S = 0.0f;
    
    P.x =  sWidth  * sNear;
    Q.y =  sHeight * sNear;
    R.x =  sWidth  * (right + left);
    R.y =  sHeight * (top + bottom);
    R.z =  sDepth  * (far + near);
    R.w = -1.0f;
    S.z =  sDepth  * sNear * far;
    
    return simd::float4x4(P, Q, R, S);
} // frustum

simd::float4x4 AAPL::Math::RHT::frustum(const float& fovy,
                                        const float& aspect,
                                        const float& near,
                                        const float& far)
{
    const float a = AAPL::Math::radians(0.5f * fovy);
    const float t = near * std::tan(a);       // tan(fovy/2) = top/near
    
    float left   = 0.0f;
    float right  = 0.0f;
    float top    = 0.0f;
    float bottom = 0.0f;
    
    if(aspect >= 1.0f)
    {
        right  =  aspect * t;
        left   = -right;
        top    =  t;
        bottom = -top;
    }
    else
    {
        right  =  t;
        left   = -right;
        top    =  t / aspect;
        bottom = -top;
    }
    
    return AAPL::Math::RHT::frustum(left, right, bottom, top, near, far);
} // frustum

simd::float4x4 AAPL::Math::RHT::frustum(const float& fovy,
                                        const float& width,
                                        const float& heigth,
                                        const float& near,
                                        const float& far)
{
    const float aspect = width / heigth;
    
    return AAPL::Math::RHT::frustum(fovy, aspect, near, far);
} // frustum

#pragma mark -
#pragma mark Public - Utilities - OpenGL - Uniforms

void AAPL::GLU::uniform::matrix2fv(const int& location,
                                   const int& count,
                                   const bool& transpose,
                                   const simd::float2x2& M)
{
    float m[4];
    
    m[0] = M.columns[0].x;
    m[1] = M.columns[0].y;
    
    m[2] = M.columns[1].x;
    m[3] = M.columns[1].y;
    
    glUniformMatrix2fv(location, (count < 0) ? 1 : count, GLboolean(transpose), m);
} // matrix2fv

void AAPL::GLU::uniform::matrix2fv(const int& location,
                                   const bool& transpose,
                                   const simd::float2x2& M)
{
    AAPL::GLU::uniform::matrix2fv(location, 1, transpose, M);
} // matrix2fv

void AAPL::GLU::uniform::matrix3fv(const int& location,
                                   const int& count,
                                   const bool& transpose,
                                   const simd::float3x3& M)
{
    float m[9];
    
    m[0] = M.columns[0].x;
    m[1] = M.columns[0].y;
    m[2] = M.columns[0].z;
    
    m[3] = M.columns[1].x;
    m[4] = M.columns[1].y;
    m[5] = M.columns[1].z;
    
    m[6] = M.columns[2].x;
    m[7] = M.columns[2].y;
    m[8] = M.columns[2].z;
    
    glUniformMatrix3fv(location, (count < 0) ? 1 : count, GLboolean(transpose), m);
} // matrix3fv

void AAPL::GLU::uniform::matrix3fv(const int& location,
                                   const bool& transpose,
                                   const simd::float3x3& M)
{
    AAPL::GLU::uniform::matrix3fv(location, 1, transpose, M);
} // matrix3fv

// modifies the value of a 4x4 float matrix uniform variable
void AAPL::GLU::uniform::matrix4fv(const int& location,
                                   const int& count,
                                   const bool& transpose,
                                   const simd::float4x4& M)
{
    float m[16];
    
    m[0] = M.columns[0].x;
    m[1] = M.columns[0].y;
    m[2] = M.columns[0].z;
    m[3] = M.columns[0].w;
    
    m[4] = M.columns[1].x;
    m[5] = M.columns[1].y;
    m[6] = M.columns[1].z;
    m[7] = M.columns[1].w;
    
    m[8]  = M.columns[2].x;
    m[9]  = M.columns[2].y;
    m[10] = M.columns[2].z;
    m[11] = M.columns[2].w;
    
    m[12] = M.columns[3].x;
    m[13] = M.columns[3].y;
    m[14] = M.columns[3].z;
    m[15] = M.columns[3].w;
    
    glUniformMatrix4fv(location, (count < 0) ? 1 : count, GLboolean(transpose), m);
} // matrix4fv

void AAPL::GLU::uniform::matrix4fv(const int& location,
                                   const bool& transpose,
                                   const simd::float4x4& M)
{
    AAPL::GLU::uniform::matrix4fv(location, 1, transpose, M);
} // matrix4fv
