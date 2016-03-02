/*
 Copyright (C) 2015 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 Metal compute shader for matrix multipication
 */

#include <metal_stdlib>

using namespace metal;

// Note:
//
// (1) m is the number of rows in matrices A and C.
//
// (2) n is the number of columns in matrix A; number of rows in matrix B.
//
// (3) k is the number of columns in matrices B and C.
//
// (4) Matrix multiple computes C = A^T * B where A is m x n matrix (so
//     that, A^T is n x m), B is n x k .
//
// (5) pbytes is stride in bytes from row to another of matrix A.
//     pbytes should be multiple of 32, i.e. A is padded to be
//     M x k matrix where M > m and P is multiple of 8.
//
// (6) Similarly qbytes is stride in bytes from one row to another
//     of B, i.e. B is n x K matrix where K > k matrix where K is
//     multiple of 8.
//
// (7) The output matrix C is the M x K matrix.

typedef struct
{
    ushort m, k, n, pbytes, qbytes;
} MetalMatrixDim;


kernel void MatrixMultiply(const device float*       A    [[ buffer(0) ]],
                           const device float*       B    [[ buffer(1) ]],
                           device float*             C    [[ buffer(2) ]],
                           constant MetalMatrixDim&  dims [[ buffer(3) ]],
                           ushort2                   gid  [[ thread_position_in_grid ]])
{
    ushort m = dims.m;
    ushort k = dims.k;
    ushort n = dims.n;
    
    ushort pbytes = dims.pbytes;
    ushort qbytes = dims.qbytes;
    
    ushort2 gidIn = ushort2(gid.x << 3, gid.y << 3);
    
    if (gidIn.x >= m || gidIn.y >= k) return;
    
    const device float4* a = (const device float4*)(A + gidIn.x);
    const device float4* b = (const device float4*)(B + gidIn.y);
    
    C = (device float*)((device char*)C + gidIn.x*qbytes);
    
    device float4* c = (device float4*)(C + gidIn.y);
    
    const device float4* Bend = (const device float4*)((const device char*)B + qbytes*n);
    
    float4 s0  = 0.0f, s1  = 0.0f, s2  = 0.0f, s3  = 0.0f;
    float4 s4  = 0.0f, s5  = 0.0f, s6  = 0.0f, s7  = 0.0f;
    float4 s8  = 0.0f, s9  = 0.0f, s10 = 0.0f, s11 = 0.0f;
    float4 s12 = 0.0f, s13 = 0.0f, s14 = 0.0f, s15 = 0.0f;
    
    do
    {
        float4 aCurr0 = a[0];
        float4 aCurr1 = a[1];
        float4 bCurr0 = b[0];
        float4 bCurr1 = b[1];
        
        s0   += (aCurr0.x * bCurr0);
        s2   += (aCurr0.y * bCurr0);
        s4   += (aCurr0.z * bCurr0);
        s6   += (aCurr0.w * bCurr0);
        
        s1   += (aCurr0.x * bCurr1);
        s3   += (aCurr0.y * bCurr1);
        s5   += (aCurr0.z * bCurr1);
        s7   += (aCurr0.w * bCurr1);
        
        s8   += (aCurr1.x * bCurr0);
        s10  += (aCurr1.y * bCurr0);
        s12  += (aCurr1.z * bCurr0);
        s14  += (aCurr1.w * bCurr0);
        
        s9   += (aCurr1.x * bCurr1);
        s11  += (aCurr1.y * bCurr1);
        s13  += (aCurr1.z * bCurr1);
        s15  += (aCurr1.w * bCurr1);
        
        a = (device float4*)((device char*)a + pbytes);
        b = (device float4*)((device char*)b + qbytes);
        
    } while(b < Bend);
    
    c[0] = s0;  c[1] = s1;  c = (device float4*)((device char*)c + qbytes);
    c[0] = s2;  c[1] = s3;  c = (device float4*)((device char*)c + qbytes);
    c[0] = s4;  c[1] = s5;  c = (device float4*)((device char*)c + qbytes);
    c[0] = s6;  c[1] = s7;  c = (device float4*)((device char*)c + qbytes);
    c[0] = s8;  c[1] = s9;  c = (device float4*)((device char*)c + qbytes);
    c[0] = s10; c[1] = s11; c = (device float4*)((device char*)c + qbytes);
    c[0] = s12; c[1] = s13; c = (device float4*)((device char*)c + qbytes);
    c[0] = s14; c[1] = s15;
}
