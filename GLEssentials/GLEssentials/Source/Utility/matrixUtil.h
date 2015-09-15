/*
 Copyright (C) 2015 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 Functions for performing matrix math.
 */
#ifndef __MATRIX_UTIL_H__
#define __MATRIX_UTIL_H__

// Matrix is a column major floating point array

// All matrices are 4x4 by unless the mtx3x3 prefix is specified in the function name

// [ 0 4  8 12 ]
// [ 1 5  9 13 ]
// [ 2 6 10 14 ]
// [ 3 7 11 15 ]

// MTX = LeftHandSideMatrix * RightHandSideMatrix
void mtxMultiply(float* ret, const float* lhs, const float* rhs);

// MTX = IdentityMatrix
void mtxLoadIdentity(float* mtx);

// MTX = Transpos(SRC)
void mtxTranspose(float* mtx, const float* src);

// MTX = src^-1
void mtxInvert(float* mtx, const float* src);

// MTX = PerspectiveProjectionMatrix
void mtxLoadPerspective(float* mtx, float fov, float aspect, float nearZ, float farZ);

// MTX = OrthographicProjectionMatrix
void mtxLoadOrthographic(float* mtx,
								float left, float right, 
								float bottom, float top, 
								float nearZ, float farZ);

// MTX = ObliqueProjectionMatrix(src, clipPlane)
void mtxModifyObliqueProjection(float* mtx, const float* src, const float* plane);

// MTX = TranlationMatrix
void mtxLoadTranslate(float* mtx, float xTrans, float yTrans, float zTrans);

// MTX = ScaleMatrix
void mtxLoadScale(float* mtx, float xScale, float yScale, float zScale);

// MTX = RotateXYZMatrix
void mtxLoadRotate(float*mtx, float deg, float xAxis, float , float zAxis);

// MTX = RotateXMatrix
void mtxLoadRotateX(float* mtx, float deg);

// MTX = RotateYMatrix
void mtxLoadRotateY(float* mtx, float deg);

// MTX = RotateZMatrix
void mtxLoadRotateZ(float* mtx, float deg);

// MTX = MTX * TranslationMatrix - Similar to glTranslate
void mtxTranslateApply(float* mtx, float xTrans, float yTrans, float zTrans);

// MTX = MTX * ScaleMatrix - Similar to glScale
void mtxScaleApply(float* mtx, float xScale, float yScale, float zScale);

// MTX = MTX * RotateXYZMatrix - Similar to glRotate
void mtxRotateApply(float* mtx, float deg, float xAxis, float yAxis, float zAxis);

// MTX = MTX * RotateXMatrix
void mtxRotateXApply(float* mtx, float rad);

// MTX = MTX * RotateYMatrix
void mtxRotateYApply(float* mtx, float rad);

// MTX = MTX * RotateZMatrix
void mtxRotateZApply(float* mtx, float rad);

// MTX = TranslationMatrix * MTX
void mtxTranslateMatrix(float* mtx, float xTrans, float yTrans, float zTrans);

// MTX = ScaleMatrix * MTX
void mtxScaleMatrix(float* mtx, float xScale, float yScale, float zScale);

// MTX = RotateXYZMatrix * MTX
void mtxRotateMatrix(float* mtx, float rad, float xAxis, float yAxis, float zAxis);

// MTX = RotateXMatrix * MTX
void mtxRotateXMatrix(float* mtx, float rad);

// MTX = RotateYMatrix * MTX
void mtxRotateYMatrix(float* mtx, float rad);

// MTX = RotateZMatrix * MTX
void mtxRotateZMatrix(float* mtx, float rad);

// 3x3 MTX = 3x3 IdendityMatrix
void mtx3x3LoadIdentity(float* mtx);


// 3x3 MTX = 3x3 LHS x 3x3 RHS
void mtx3x3Multiply(float* mtx, const float* lhs, const float* rhs);


// 3x3 MTX = TopLeft of MTX 
void mtx3x3FromTopLeftOf4x4(float* mtx, const float* src);

// 3x3 MTX = Transpose(3x3 SRC)
void mtx3x3Transpose(float* mtx, const float* src);

// 3x3 MTX = 3x3 SRC^-1
void mtx3x3Invert(float* mtx, const float* src);

#endif //__MATRIX_UTIL_H__

