/*
 Copyright (C) 2015 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 Functions for performing matrix math.
 */

#include "matrixUtil.h"
#include "vectorUtil.h"
#include <math.h>
#include <memory.h>

void mtxMultiply(float* ret, const float* lhs, const float* rhs)
{
	// [ 0 4  8 12 ]   [ 0 4  8 12 ]
	// [ 1 5  9 13 ] x [ 1 5  9 13 ]
	// [ 2 6 10 14 ]   [ 2 6 10 14 ]
	// [ 3 7 11 15 ]   [ 3 7 11 15 ]
	ret[ 0] = lhs[ 0]*rhs[ 0] + lhs[ 4]*rhs[ 1] + lhs[ 8]*rhs[ 2] + lhs[12]*rhs[ 3];
	ret[ 1] = lhs[ 1]*rhs[ 0] + lhs[ 5]*rhs[ 1] + lhs[ 9]*rhs[ 2] + lhs[13]*rhs[ 3];
	ret[ 2] = lhs[ 2]*rhs[ 0] + lhs[ 6]*rhs[ 1] + lhs[10]*rhs[ 2] + lhs[14]*rhs[ 3];
	ret[ 3] = lhs[ 3]*rhs[ 0] + lhs[ 7]*rhs[ 1] + lhs[11]*rhs[ 2] + lhs[15]*rhs[ 3];

	ret[ 4] = lhs[ 0]*rhs[ 4] + lhs[ 4]*rhs[ 5] + lhs[ 8]*rhs[ 6] + lhs[12]*rhs[ 7];
	ret[ 5] = lhs[ 1]*rhs[ 4] + lhs[ 5]*rhs[ 5] + lhs[ 9]*rhs[ 6] + lhs[13]*rhs[ 7];
	ret[ 6] = lhs[ 2]*rhs[ 4] + lhs[ 6]*rhs[ 5] + lhs[10]*rhs[ 6] + lhs[14]*rhs[ 7];
	ret[ 7] = lhs[ 3]*rhs[ 4] + lhs[ 7]*rhs[ 5] + lhs[11]*rhs[ 6] + lhs[15]*rhs[ 7];

	ret[ 8] = lhs[ 0]*rhs[ 8] + lhs[ 4]*rhs[ 9] + lhs[ 8]*rhs[10] + lhs[12]*rhs[11];
	ret[ 9] = lhs[ 1]*rhs[ 8] + lhs[ 5]*rhs[ 9] + lhs[ 9]*rhs[10] + lhs[13]*rhs[11];
	ret[10] = lhs[ 2]*rhs[ 8] + lhs[ 6]*rhs[ 9] + lhs[10]*rhs[10] + lhs[14]*rhs[11];
	ret[11] = lhs[ 3]*rhs[ 8] + lhs[ 7]*rhs[ 9] + lhs[11]*rhs[10] + lhs[15]*rhs[11];

	ret[12] = lhs[ 0]*rhs[12] + lhs[ 4]*rhs[13] + lhs[ 8]*rhs[14] + lhs[12]*rhs[15];
	ret[13] = lhs[ 1]*rhs[12] + lhs[ 5]*rhs[13] + lhs[ 9]*rhs[14] + lhs[13]*rhs[15];
	ret[14] = lhs[ 2]*rhs[12] + lhs[ 6]*rhs[13] + lhs[10]*rhs[14] + lhs[14]*rhs[15];
	ret[15] = lhs[ 3]*rhs[12] + lhs[ 7]*rhs[13] + lhs[11]*rhs[14] + lhs[15]*rhs[15];}


void mtxLoadPerspective(float* mtx, float fov, float aspect, float nearZ, float farZ)
{
	float f = 1.0f / tanf( (fov * (M_PI/180)) / 2.0f);
	
	mtx[0] = f / aspect;
	mtx[1] = 0.0f;
	mtx[2] = 0.0f;
	mtx[3] = 0.0f;
	
	mtx[4] = 0.0f;
	mtx[5] = f;
	mtx[6] = 0.0f;
	mtx[7] = 0.0f;
	
	mtx[8] = 0.0f;
	mtx[9] = 0.0f;
	mtx[10] = (farZ+nearZ) / (nearZ-farZ);
	mtx[11] = -1.0f;
	
	mtx[12] = 0.0f;
	mtx[13] = 0.0f;
	mtx[14] = 2 * farZ * nearZ /  (nearZ-farZ);
	mtx[15] = 0.0f;
}


void mtxLoadOrthographic(float* mtx,
							float left, float right, 
							float bottom, float top, 
							float nearZ, float farZ)
{
	//See appendix G of OpenGL Red Book
	
	mtx[ 0] = 2.0f / (right - left);
	mtx[ 1] = 0.0;
	mtx[ 2] = 0.0;
	mtx[ 3] = 0.0;
	
	mtx[ 4] = 0.0;
	mtx[ 5] = 2.0f / (top - bottom);
	mtx[ 6] = 0.0;
	mtx[ 7] = 0.0;
	
	mtx[ 8] = 0.0;
	mtx[ 9] = 0.0;
	mtx[10] = -2.0f / (farZ - nearZ);
	mtx[11] = 0.0;
	
	mtx[12] = -(right + left) / (right - left);
	mtx[13] = -(top + bottom) / (top - bottom);
	mtx[14] = -(farZ + nearZ) / (farZ - nearZ);
	mtx[15] = 1.0f;
}

static inline float sgn(float val)
{
	return (val > 0.0f) ? 1.0f : ((val < 0.0f) ? -1.0f : 0.0f);
}

void mtxModifyObliqueProjection(float* mtx, const float* src, const float* plane)
{
	float vec[4];
	
	memcpy(mtx, src, 16 * sizeof(float));

    vec[0] = (sgn(plane[0]) + mtx[8]) / mtx[0];
    vec[1] = (sgn(plane[1]) + mtx[9]) / mtx[5];
    vec[2] = -1.0f;
    vec[3] = (1.0f + mtx[10]) / mtx[14];
    
	float dot = vec4DotProduct(plane, vec);
	
    vec[0] = plane[0] * (2.0f / dot);
    vec[1] = plane[1] * (2.0f / dot);
    vec[2] = plane[2] * (2.0f / dot);
    vec[3] = plane[3] * (2.0f / dot);
    
    // Replace the third row of the projection matrix
    mtx[ 2] = vec[0];
    mtx[ 6] = vec[1];
    mtx[10] = vec[2];
    mtx[14] = vec[3];
}

void mtxTranspose(float* mtx, const float* src)
{
	//Use a temp to swap in case mtx == src
	
	float tmp;
	mtx[0]  = src[0];
	mtx[5]  = src[5];
	mtx[10] = src[10];
	mtx[15] = src[15];
	
	tmp = src[4];
	mtx[4]  = src[1];
	mtx[1]  = tmp;
	
	tmp = src[8];
	mtx[8]  = src[2];
	mtx[2] = tmp;
	
	tmp = src[12];
	mtx[12] = src[3];
	mtx[3]  = tmp;
	
	tmp = src[9];
	mtx[9]  = src[6];
	mtx[6]  = tmp;
	
	tmp = src[13];
	mtx[13] = src[7];
	mtx[ 7] = tmp;
	
	tmp = src[14];
	mtx[14] = src[11];
	mtx[11] = tmp;
	
}

void mtxInvert(float* mtx, const float* src)
{
	float tmp[16];
	float val, val2, val_inv;
	int i, j, i4, i8, i12, ind;
	
	mtxTranspose(tmp, src);
	
	mtxLoadIdentity(mtx);
	
	
	for(i = 0; i != 4; i++)
	{
		val = tmp[(i << 2) + i];
		ind = i;
		
		i4  = i + 4;
		i8  = i + 8;
		i12 = i + 12;
		
		for (j = i + 1; j != 4; j++)
		{
			if(fabsf(tmp[(i << 2) + j]) > fabsf(val))
			{
				ind = j;
				val = tmp[(i << 2) + j];
			}
		}
		
		if(ind != i)
		{
			val2      = mtx[i];
			mtx[i]    = mtx[ind];
			mtx[ind]  = val2;
			
			val2      = tmp[i];
			tmp[i]    = tmp[ind];
			tmp[ind]  = val2;
			
			ind += 4;
			
			val2      = mtx[i4];
			mtx[i4]   = mtx[ind];
			mtx[ind]  = val2;
			
			val2      = tmp[i4];
			tmp[i4]   = tmp[ind];
			tmp[ind]  = val2;
			
			ind += 4;
			
			val2      = mtx[i8];
			mtx[i8]   = mtx[ind];
			mtx[ind]  = val2;
			
			val2      = tmp[i8];
			tmp[i8]   = tmp[ind];
			tmp[ind]  = val2;
			
			ind += 4;
			
			val2      = mtx[i12];
			mtx[i12]  = mtx[ind];
			mtx[ind]  = val2;
			
			val2      = tmp[i12];
			tmp[i12]  = tmp[ind];
			tmp[ind]  = val2;
		}
		
		if(val == 0)
		{
			mtxLoadIdentity(mtx);
			return;
		}
		
		val_inv = 1.0f / val;
		
		tmp[i]   *= val_inv;
		mtx[i]   *= val_inv;
		
		tmp[i4]  *= val_inv;
		mtx[i4]  *= val_inv;
		
		tmp[i8]  *= val_inv;
		mtx[i8]  *= val_inv;
		
		tmp[i12] *= val_inv;
		mtx[i12] *= val_inv;
		
		if(i != 0)
		{
			val = tmp[i << 2];
			
			tmp[0]  -= tmp[i]   * val;
			mtx[0]  -= mtx[i]   * val;
			
			tmp[4]  -= tmp[i4]  * val;
			mtx[4]  -= mtx[i4]  * val;
			
			tmp[8]  -= tmp[i8]  * val;
			mtx[8]  -= mtx[i8]  * val;
			
			tmp[12] -= tmp[i12] * val;
			mtx[12] -= mtx[i12] * val;
		}
		
		if(i != 1)
		{
			val = tmp[(i << 2) + 1];
			
			tmp[1]  -= tmp[i]   * val;
			mtx[1]  -= mtx[i]   * val;
			
			tmp[5]  -= tmp[i4]  * val;
			mtx[5]  -= mtx[i4]  * val;
			
			tmp[9]  -= tmp[i8]  * val;
			mtx[9]  -= mtx[i8]  * val;
			
			tmp[13] -= tmp[i12] * val;
			mtx[13] -= mtx[i12] * val;
		}
		
		if(i != 2)
		{
			val = tmp[(i << 2) + 2];
			
			tmp[2]  -= tmp[i]   * val;
			mtx[2]  -= mtx[i]   * val;
			
			tmp[6]  -= tmp[i4]  * val;
			mtx[6]  -= mtx[i4]  * val;
			
			tmp[10] -= tmp[i8]  * val;
			mtx[10] -= mtx[i8]  * val;
			
			tmp[14] -= tmp[i12] * val;
			mtx[14] -= mtx[i12] * val;
		}
		
		if(i != 3)
		{
			val = tmp[(i << 2) + 3];
			
			tmp[3]  -= tmp[i]   * val;
			mtx[3]  -= mtx[i]   * val;
			
			tmp[7]  -= tmp[i4]  * val;
			mtx[7]  -= mtx[i4]  * val;
			
			tmp[11] -= tmp[i8]  * val;
			mtx[11] -= mtx[i8]  * val;
			
			tmp[15] -= tmp[i12] * val;
			mtx[15] -= mtx[i12] * val;
		}
	}
}

void mtxLoadIdentity(float* mtx)
{
	// [ 0 4  8 12 ]
	// [ 1 5  9 13 ]
	// [ 2 6 10 14 ]
    // [ 3 7 11 15 ]
	mtx[ 0] = mtx[ 5] = mtx[10] = mtx[15] = 1.0f;
	
	mtx[ 1] = mtx[ 2] = mtx[ 3] = mtx[ 4] =    
	mtx[ 6] = mtx[ 7] = mtx[ 8] = mtx[ 9] =    
	mtx[11] = mtx[12] = mtx[13] = mtx[14] = 0.0;
}


void mtxLoadTranslate(float* mtx, float xTrans, float yTrans, float zTrans)
{
	
	// [ 0 4  8  x ]
	// [ 1 5  9  y ]
	// [ 2 6 10  z ]
	// [ 3 7 11 15 ]
	mtx[ 0] = mtx[ 5] = mtx[10] = mtx[15] = 1.0f;
	
	mtx[ 1] = mtx[ 2] = mtx[ 3] = mtx[ 4] =    
	mtx[ 6] = mtx[ 7] = mtx[ 8] = mtx[ 9] =    
	mtx[11] = 0.0;
	
	mtx[12] = xTrans;
	mtx[13] = yTrans;
	mtx[14] = zTrans;   
}


void mtxLoadScale(float* mtx, float xScale, float yScale, float zScale)
{
	// [ x 4  8 12 ]
	// [ 1 y  9 13 ]
	// [ 2 6  z 14 ]
	// [ 3 7 11 15 ]
	mtx[ 0] = xScale;
	mtx[ 5] = yScale;
	mtx[10] = zScale;
	mtx[15] = 1.0f;
	
	mtx[ 1] = mtx[ 2] = mtx[ 3] = mtx[ 4] =    
	mtx[ 6] = mtx[ 7] = mtx[ 8] = mtx[ 9] =    
	mtx[11] = mtx[12] = mtx[13] = mtx[14] = 0.0;		
}


void mtxLoadRotateX(float* mtx, float rad)
{
	// [ 0 4      8 12 ]
	// [ 1 cos -sin 13 ]
	// [ 2 sin cos  14 ]
	// [ 3 7     11 15 ]
	
	mtx[10] = mtx[ 5] = cosf(rad);
	mtx[ 6] = sinf(rad);
	mtx[ 9] = -mtx[ 6];
	
	mtx[ 0] = mtx[15] = 1.0f;
	
	mtx[ 1] = mtx[ 2] = mtx[ 3] = mtx[ 4] =    
	mtx[ 7] = mtx[ 8] = mtx[11] = mtx[12] =
	mtx[13] = mtx[14] = 0.0;		
}


void mtxLoadRotateY(float* mtx, float rad)
{
	// [ cos 4  -sin 12 ]
	// [ 1   5   9   13 ]
	// [ sin 6  cos  14 ]
	// [ 3   7  11   15 ]
	
	mtx[ 0] = mtx[10] = cosf(rad); 
	mtx[ 2] = sinf(rad);
	mtx[ 8] = -mtx[2];
	
	mtx[ 5] = mtx[15] = 1.0;
	
	mtx[ 1] = mtx[ 3] = mtx[ 4] = mtx[ 6] =    
	mtx[ 7] = mtx[ 9] = mtx[11] = mtx[12] =
	mtx[13] = mtx[14] = 0.0;
}


void mtxLoadRotateZ(float* mtx, float rad)
{
	// [ cos -sin 8 12 ]
	// [ sin cos  9 13 ]
	// [ 2   6   10 14 ]
	// [ 3   7   11 15 ]
	
	mtx[ 0] = mtx[ 5] = cosf(rad); 
	mtx[ 1] = sinf(rad);
	mtx[ 4] = -mtx[1];
	
	mtx[10] = mtx[15] = 1.0;
	
	mtx[ 2] = mtx[ 3] = mtx[ 6] = mtx[ 7] =    
	mtx[ 8] = mtx[ 9] = mtx[11] = mtx[12] =
	mtx[13] = mtx[14] = 0.0;
}


void mtxLoadRotate(float* mtx, float deg, float xAxis, float yAxis, float zAxis)
{
	float rad = deg * M_PI/180.0f;
	
	float sin_a = sinf(rad);
	float cos_a = cosf(rad);
	
	// Calculate coeffs.  No need to check for zero magnitude because we wouldn't be here.
	float magnitude = sqrtf(xAxis * xAxis + yAxis * yAxis + zAxis * zAxis);
	
	float p = 1.0f / magnitude;
	float cos_am = 1.0f - cos_a;
	
	float xp = xAxis * p;
	float yp = yAxis * p;
	float zp = zAxis * p;
	
	float xx = xp * xp;
	float yy = yp * yp;
	float zz = zp * zp;
	
	float xy = xp * yp * cos_am;
	float yz = yp * zp * cos_am;
	float zx = zp * xp * cos_am;
	
	xp *= sin_a;
	yp *= sin_a;
	zp *= sin_a;
	
	// Load coefs
	float m0  = xx + cos_a * (1.0f - xx);
	float m1  = xy + zp;
	float m2  = zx - yp;
	float m4  = xy - zp;
	float m5  = yy + cos_a * (1.0f - yy);
	float m6  = yz + xp;
	float m8  = zx + yp;
	float m9  = yz - xp;
	float m10 = zz + cos_a * (1.0f - zz);
	
	// Apply rotation 
	float c1 = mtx[0];
	float c2 = mtx[4];
	float c3 = mtx[8];
	mtx[0]  = c1 * m0 + c2 * m1 + c3 * m2;
	mtx[4]  = c1 * m4 + c2 * m5 + c3 * m6;
	mtx[8]  = c1 * m8 + c2 * m9 + c3 * m10;
	
	c1 = mtx[1];
	c2 = mtx[5];
	c3 = mtx[9];
	mtx[1]  = c1 * m0 + c2 * m1 + c3 * m2;
	mtx[5]  = c1 * m4 + c2 * m5 + c3 * m6;
	mtx[9]  = c1 * m8 + c2 * m9 + c3 * m10;
	
	c1 = mtx[2];
	c2 = mtx[6];
	c3 = mtx[10];
	mtx[2]  = c1 * m0 + c2 * m1 + c3 * m2;
	mtx[6]  = c1 * m4 + c2 * m5 + c3 * m6;
	mtx[10] = c1 * m8 + c2 * m9 + c3 * m10;
	
	c1 = mtx[3];
	c2 = mtx[7];
	c3 = mtx[11];
	mtx[3]  = c1 * m0 + c2 * m1 + c3 * m2;
	mtx[7]  = c1 * m4 + c2 * m5 + c3 * m6;
	mtx[11] = c1 * m8 + c2 * m9 + c3 * m10;
	
	mtx[12] = mtx[13] = mtx[14] = 0.0;
	mtx[15] = 1.0f;
}


void mtxTranslateApply(float* mtx, float xTrans, float yTrans, float zTrans)
{
	// [ 0 4  8 12 ]   [ 1 0 0 x ]
	// [ 1 5  9 13 ] x [ 0 1 0 y ]
	// [ 2 6 10 14 ]   [ 0 0 1 z ]
	// [ 3 7 11 15 ]   [ 0 0 0 1 ]
	
	mtx[12] += mtx[0]*xTrans + mtx[4]*yTrans + mtx[ 8]*zTrans;
	mtx[13] += mtx[1]*xTrans + mtx[5]*yTrans + mtx[ 9]*zTrans;
	mtx[14] += mtx[2]*xTrans + mtx[6]*yTrans + mtx[10]*zTrans;	
}


void mtxScaleApply(float* mtx, float xScale, float yScale, float zScale)
{ 
    // [ 0 4  8 12 ]   [ x 0 0 0 ]
    // [ 1 5  9 13 ] x [ 0 y 0 0 ] 
    // [ 2 6 10 14 ]   [ 0 0 z 0 ]
    // [ 3 7 11 15 ]   [ 0 0 0 1 ]   
	
	mtx[ 0] *= xScale;
	mtx[ 4] *= yScale;
	mtx[ 8] *= zScale;
	
	mtx[ 1] *= xScale;
	mtx[ 5] *= yScale;
	mtx[ 9] *= zScale;
	
	mtx[ 2] *= xScale;
	mtx[ 6] *= yScale;
	mtx[10] *= zScale;
	
	mtx[ 3] *= xScale;
	mtx[ 7] *= yScale;
	mtx[11] *= xScale;
}


void mtxTranslateMatrix(float* mtx, float xTrans, float yTrans, float zTrans)
{
	// [ 1 0 0 x ]   [ 0 4  8 12 ]
	// [ 0 1 0 y ] x [ 1 5  9 13 ]
	// [ 0 0 1 z ]   [ 2 6 10 14 ]
	// [ 0 0 0 1 ]   [ 3 7 11 15 ]
	
	mtx[ 0] += xTrans * mtx[ 3];
	mtx[ 1] += yTrans * mtx[ 3];
	mtx[ 2] += zTrans * mtx[ 3];
	
	mtx[ 4] += xTrans * mtx[ 7];
	mtx[ 5] += yTrans * mtx[ 7];
	mtx[ 6] += zTrans * mtx[ 7];
	
	mtx[ 8] += xTrans * mtx[11];
	mtx[ 9] += yTrans * mtx[11];
	mtx[10] += zTrans * mtx[11];
	
	mtx[12] += xTrans * mtx[15];
	mtx[13] += yTrans * mtx[15];
	mtx[14] += zTrans * mtx[15];
}


void mtxRotateXApply(float* mtx, float deg)
{
	// [ 0 4  8 12 ]   [ 1  0    0  0 ]
	// [ 1 5  9 13 ] x [ 0 cos -sin 0 ]
	// [ 2 6 10 14 ]   [ 0 sin  cos 0 ]
	// [ 3 7 11 15 ]   [ 0  0    0  1 ]
	
	float rad = deg * (M_PI/180.0f);
	
	float cosrad = cosf(rad);
	float sinrad = sinf(rad);
	
	float mtx04 = mtx[4];
	float mtx05 = mtx[5];
	float mtx06 = mtx[6];
	float mtx07 = mtx[7];
	
	mtx[ 4] = mtx[ 8]*sinrad + mtx04*cosrad;
	mtx[ 8] = mtx[ 8]*cosrad - mtx04*sinrad;
	
	mtx[ 5] = mtx[ 9]*sinrad + mtx05*cosrad;
	mtx[ 9] = mtx[ 9]*cosrad - mtx05*sinrad;
	
	mtx[ 6] = mtx[10]*sinrad + mtx06*cosrad;
	mtx[10] = mtx[10]*cosrad - mtx06*sinrad;
	
	mtx[ 7] = mtx[11]*sinrad + mtx07*cosrad;
	mtx[11] = mtx[11]*cosrad - mtx07*sinrad;
}


void mtxRotateYApply(float* mtx, float deg)
{
	// [ 0 4  8 12 ]   [ cos 0  -sin 0 ]
	// [ 1 5  9 13 ] x [ 0   1  0    0 ]
	// [ 2 6 10 14 ]   [ sin 0  cos  0 ]
	// [ 3 7 11 15 ]   [ 0   0  0    1 ]
	
	float rad = deg * (M_PI/180.0f);
	
	float cosrad = cosf(rad);
	float sinrad = sinf(rad);
	
	float mtx00 = mtx[0];
	float mtx01 = mtx[1];
	float mtx02 = mtx[2];
	float mtx03 = mtx[3];
	
	mtx[ 0] = mtx[ 8]*sinrad + mtx00*cosrad;
	mtx[ 8] = mtx[ 8]*cosrad - mtx00*sinrad;
	
	mtx[ 1] = mtx[ 9]*sinrad + mtx01*cosrad;
	mtx[ 9] = mtx[ 9]*cosrad - mtx01*sinrad;
	
	mtx[ 2] = mtx[10]*sinrad + mtx02*cosrad;
	mtx[10] = mtx[10]*cosrad - mtx02*sinrad;
	
	mtx[ 3] = mtx[11]*sinrad + mtx03*cosrad;
	mtx[11] = mtx[11]*cosrad - mtx03*sinrad;
}


void mtxRotateZApply(float* mtx, float deg)
{
	// [ 0 4  8 12 ]   [ cos -sin 0  0 ]
	// [ 1 5  9 13 ] x [ sin cos  0  0 ]
	// [ 2 6 10 14 ]   [ 0   0    1  0 ]
	// [ 3 7 11 15 ]   [ 0   0    0  1 ]
	
	float rad = deg * (M_PI/180.0f);
	
	float cosrad = cosf(rad);
	float sinrad = sinf(rad);
	
	float mtx00 = mtx[0];
	float mtx01 = mtx[1];
	float mtx02 = mtx[2];
	float mtx03 = mtx[3];
	
	mtx[ 0] = mtx[ 4]*sinrad + mtx00*cosrad;
	mtx[ 4] = mtx[ 4]*cosrad - mtx00*sinrad;
	
	mtx[ 1] = mtx[ 5]*sinrad + mtx01*cosrad;
	mtx[ 5] = mtx[ 5]*cosrad - mtx01*sinrad;
	
	mtx[ 2] = mtx[ 6]*sinrad + mtx02*cosrad;
	mtx[ 6] = mtx[ 6]*cosrad - mtx02*sinrad;
	
	mtx[ 3] = mtx[ 7]*sinrad + mtx03*cosrad;
	mtx[ 7] = mtx[ 7]*cosrad - mtx03*sinrad;
}

void mtxRotateApply(float* mtx, float deg, float xAxis, float yAxis, float zAxis)
{	
	if(yAxis == 0.0f && zAxis == 0.0f)
	{
		mtxRotateXApply(mtx, deg);
	}
	else if(xAxis == 0.0f && zAxis == 0.0f)
	{
		mtxRotateYApply(mtx, deg);
	}
	else if(xAxis == 0.0f && yAxis == 0.0f)
	{
		mtxRotateZApply(mtx, deg);
	}
	else
	{
		float rad = deg * M_PI/180.0f;
		
		float sin_a = sinf(rad);
		float cos_a = cosf(rad);
		
		// Calculate coeffs.  No need to check for zero magnitude because we wouldn't be here.
		float magnitude = sqrtf(xAxis * xAxis + yAxis * yAxis + zAxis * zAxis);
		
		float p = 1.0f / magnitude;
		float cos_am = 1.0f - cos_a;
		
		float xp = xAxis * p;
		float yp = yAxis * p;
		float zp = zAxis * p;
		
		float xx = xp * xp;
		float yy = yp * yp;
		float zz = zp * zp;
		
		float xy = xp * yp * cos_am;
		float yz = yp * zp * cos_am;
		float zx = zp * xp * cos_am;
		
		xp *= sin_a;
		yp *= sin_a;
		zp *= sin_a;
		
		// Load coefs
		float m0  = xx + cos_a * (1.0f - xx);
		float m1  = xy + zp;
		float m2  = zx - yp;
		float m4  = xy - zp;
		float m5  = yy + cos_a * (1.0f - yy);
		float m6  = yz + xp;
		float m8  = zx + yp;
		float m9  = yz - xp;
		float m10 = zz + cos_a * (1.0f - zz);
		
		// Apply rotation 
		float c1 = mtx[0];
		float c2 = mtx[4];
		float c3 = mtx[8];
		mtx[0]  = c1 * m0 + c2 * m1 + c3 * m2;
		mtx[4]  = c1 * m4 + c2 * m5 + c3 * m6;
		mtx[8]  = c1 * m8 + c2 * m9 + c3 * m10;
		
		c1 = mtx[1];
		c2 = mtx[5];
		c3 = mtx[9];
		mtx[1]  = c1 * m0 + c2 * m1 + c3 * m2;
		mtx[5]  = c1 * m4 + c2 * m5 + c3 * m6;
		mtx[9]  = c1 * m8 + c2 * m9 + c3 * m10;
		
		c1 = mtx[2];
		c2 = mtx[6];
		c3 = mtx[10];
		mtx[2]  = c1 * m0 + c2 * m1 + c3 * m2;
		mtx[6]  = c1 * m4 + c2 * m5 + c3 * m6;
		mtx[10] = c1 * m8 + c2 * m9 + c3 * m10;
		
		c1 = mtx[3];
		c2 = mtx[7];
		c3 = mtx[11];
		mtx[3]  = c1 * m0 + c2 * m1 + c3 * m2;
		mtx[7]  = c1 * m4 + c2 * m5 + c3 * m6;
		mtx[11] = c1 * m8 + c2 * m9 + c3 * m10;
	}	
}

void mtxScaleMatrix(float* mtx, float xScale, float yScale, float zScale)
{ 
    // [ x 0 0 0 ]   [ 0 4  8 12 ]
    // [ 0 y 0 0 ] x [ 1 5  9 13 ]
    // [ 0 0 z 0 ]   [ 2 6 10 14 ]
    // [ 0 0 0 1 ]   [ 3 7 11 15 ]
	
	mtx[ 0] *= xScale;
	mtx[ 4] *= xScale;
	mtx[ 8] *= xScale;
	mtx[12] *= xScale;
	
	mtx[ 1] *= yScale;
	mtx[ 5] *= yScale;
	mtx[ 9] *= yScale;		
	mtx[13] *= yScale;
	
	mtx[ 2] *= zScale;
	mtx[ 6] *= zScale;
	mtx[10] *= zScale;
	mtx[14] *= zScale;
}


void mtxRotateXMatrix(float* mtx, float rad)
{
	// [ 1  0    0  0 ]   [ 0 4  8 12 ]
	// [ 0 cos -sin 0 ] x [ 1 5  9 13 ]
	// [ 0 sin  cos 0 ]   [ 2 6 10 14 ]
	// [ 0  0    0  1 ]   [ 3 7 11 15 ]
	
	float cosrad = cosf(rad);
	float sinrad = sinf(rad);
	
	float mtx01 = mtx[ 1];
	float mtx05 = mtx[ 5];
	float mtx09 = mtx[ 9];
	float mtx13 = mtx[13];
	
	mtx[ 1] = cosrad*mtx01 - sinrad*mtx[ 2];
	mtx[ 2] = sinrad*mtx01 + cosrad*mtx[ 2];
	
	mtx[ 5] = cosrad*mtx05 - sinrad*mtx[ 6];
	mtx[ 6] = sinrad*mtx05 + cosrad*mtx[ 6];
	
	mtx[ 9] = cosrad*mtx09 - sinrad*mtx[10];
	mtx[10] = sinrad*mtx09 + cosrad*mtx[10];
	
	mtx[13] = cosrad*mtx13 - sinrad*mtx[14];
	mtx[14] = sinrad*mtx13 + cosrad*mtx[14];
}


void mtxRotateYMatrix(float* mtx, float rad)
{
	// [ cos 0  -sin 0 ]   [ 0 4  8 12 ]
	// [ 0   1  0    0 ] x [ 1 5  9 13 ]
	// [ sin 0  cos  0 ]   [ 2 6 10 14 ]
	// [ 0   0  0    1 ]   [ 3 7 11 15 ]
	
	float cosrad = cosf(rad);
	float sinrad = sinf(rad);
	
	float mtx00 = mtx[ 0];
	float mtx04 = mtx[ 4];
	float mtx08 = mtx[ 8];
	float mtx12 = mtx[12];
	
	mtx[ 0] = cosrad*mtx00 - sinrad*mtx[ 2];
	mtx[ 2] = sinrad*mtx00 + cosrad*mtx[ 2];
	
	mtx[ 4] = cosrad*mtx04 - sinrad*mtx[ 6];
	mtx[ 6] = sinrad*mtx04 + cosrad*mtx[ 6];
	
	mtx[ 8] = cosrad*mtx08 - sinrad*mtx[10];
	mtx[10] = sinrad*mtx08 + cosrad*mtx[10];
	
	mtx[12] = cosrad*mtx12 - sinrad*mtx[14];
	mtx[14] = sinrad*mtx12 + cosrad*mtx[14];
}


void mtxRotateZMatrix(float* mtx, float rad)
{
	// [ cos -sin 0  0 ]   [ 0 4  8 12 ]
	// [ sin cos  0  0 ] x [ 1 5  9 13 ]
	// [ 0   0    1  0 ]   [ 2 6 10 14 ]
	// [ 0   0    0  1 ]   [ 3 7 11 15 ]
	
	float cosrad = cosf(rad);
	float sinrad = sinf(rad);
	
	float mtx00 = mtx[ 0];
	float mtx04 = mtx[ 4];
	float mtx08 = mtx[ 8];
	float mtx12 = mtx[12];
	
	mtx[ 0] = cosrad*mtx00 - sinrad*mtx[ 1];
	mtx[ 1] = sinrad*mtx00 + cosrad*mtx[ 1];
	
	mtx[ 4] = cosrad*mtx04 - sinrad*mtx[ 5];
	mtx[ 5] = sinrad*mtx04 + cosrad*mtx[ 5];
	
	mtx[ 8] = cosrad*mtx08 - sinrad*mtx[ 9];
	mtx[ 9] = sinrad*mtx08 + cosrad*mtx[ 9];
	
	mtx[12] = cosrad*mtx12 - sinrad*mtx[13];
	mtx[13] = sinrad*mtx12 + cosrad*mtx[13];
}

void mtxRotateMatrix(float* mtx, float rad, float xAxis, float yAxis, float zAxis)
{
	float rotMtx[16];
	
	mtxLoadRotate(rotMtx, rad, xAxis, yAxis, zAxis);
	
	mtxMultiply(mtx, rotMtx, mtx);
}



void mtx3x3LoadIdentity(float* mtx)
{
	mtx[0] = mtx[4] = mtx[8] = 1.0f;
	
	mtx[1] = mtx[2] = mtx[3] = 
	mtx[5] = mtx[6] = mtx[7] = 0.0f;
	
}

void mtx3x3FromTopLeftOf4x4(float* mtx, const float* src)
{    
	mtx[0] = src[0];
	mtx[1] = src[1];
	mtx[2] = src[2];
	mtx[3] = src[4];
	mtx[4] = src[5];
	mtx[5] = src[6];
	mtx[6] = src[8];
	mtx[7] = src[9];
	mtx[8] = src[10];
}

void mtx3x3Transpose(float* mtx, const float* src)
{  
	float tmp;  
	mtx[0] = src[0];
	mtx[4] = src[4];
	mtx[8] = src[8];
	
	tmp = src[1];
	mtx[1] = src[3];
	mtx[3] = tmp;
	
	tmp = src[2];
	mtx[2] = src[6];
	mtx[6] = tmp;
	
	tmp = src[5];
	mtx[5] = src[7];
	mtx[7] = tmp;
}


void mtx3x3Invert(float* mtx, const float* src)
{    
	float cpy[9];
	float det =
	src[0] * (src[4]*src[8] - src[7]*src[5]) -
	src[1] * (src[3]*src[8] - src[6]*src[5]) +
	src[2] * (src[3]*src[7] - src[6]*src[4]);
	
	if ( fabs( det ) < 0.0005 )
	{
		mtx3x3LoadIdentity(mtx);
		return;
	}
	
	memcpy(cpy, src, 9 * sizeof(float));
	
	mtx[0] =   cpy[4]*cpy[8] - cpy[5]*cpy[7]  / det;
	mtx[1] = -(cpy[1]*cpy[8] - cpy[7]*cpy[2]) / det;
	mtx[2] =   cpy[1]*cpy[5] - cpy[4]*cpy[2]  / det;
	
	mtx[3] = -(cpy[3]*cpy[8] - cpy[5]*cpy[6]) / det;
	mtx[4] =   cpy[0]*cpy[8] - cpy[6]*cpy[2]  / det;
	mtx[5] = -(cpy[0]*cpy[5] - cpy[3]*cpy[2]) / det;
	
	mtx[6] =   cpy[3]*cpy[7] - cpy[6]*cpy[4]  / det;
	mtx[7] = -(cpy[0]*cpy[7] - cpy[6]*cpy[1]) / det;
	mtx[8] =   cpy[0]*cpy[4] - cpy[1]*cpy[3]  / det;
}

void mtx3x3Multiply(float* mtx, const float* lhs, const float* rhs)
{
	mtx[0] = lhs[0]*rhs[0] + lhs[3] * rhs[1] + lhs[6] * rhs[2];
	mtx[1] = lhs[1]*rhs[0] + lhs[4] * rhs[1] + lhs[7] * rhs[2];
	mtx[2] = lhs[2]*rhs[0] + lhs[5] * rhs[1] + lhs[8] * rhs[2];
	
	mtx[3] = lhs[0]*rhs[3] + lhs[3] * rhs[4] + lhs[6] * rhs[5];
	mtx[4] = lhs[1]*rhs[3] + lhs[4] * rhs[4] + lhs[7] * rhs[5];
	mtx[5] = lhs[2]*rhs[3] + lhs[5] * rhs[4] + lhs[8] * rhs[5];
	
	mtx[6] = lhs[0]*rhs[6] + lhs[3] * rhs[7] + lhs[6] * rhs[8];
	mtx[7] = lhs[1]*rhs[6] + lhs[4] * rhs[7] + lhs[7] * rhs[8];
	mtx[8] = lhs[2]*rhs[6] + lhs[5] * rhs[7] + lhs[8] * rhs[8];
}

