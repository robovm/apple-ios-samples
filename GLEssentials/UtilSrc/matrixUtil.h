/*
     File: matrixUtil.h
 Abstract: 
 Functions for performing matrix math.
 
  Version: 1.7
 
 Disclaimer: IMPORTANT:  This Apple software is supplied to you by Apple
 Inc. ("Apple") in consideration of your agreement to the following
 terms, and your use, installation, modification or redistribution of
 this Apple software constitutes acceptance of these terms.  If you do
 not agree with these terms, please do not use, install, modify or
 redistribute this Apple software.
 
 In consideration of your agreement to abide by the following terms, and
 subject to these terms, Apple grants you a personal, non-exclusive
 license, under Apple's copyrights in this original Apple software (the
 "Apple Software"), to use, reproduce, modify and redistribute the Apple
 Software, with or without modifications, in source and/or binary forms;
 provided that if you redistribute the Apple Software in its entirety and
 without modifications, you must retain this notice and the following
 text and disclaimers in all such redistributions of the Apple Software.
 Neither the name, trademarks, service marks or logos of Apple Inc. may
 be used to endorse or promote products derived from the Apple Software
 without specific prior written permission from Apple.  Except as
 expressly stated in this notice, no other rights or licenses, express or
 implied, are granted by Apple herein, including but not limited to any
 patent rights that may be infringed by your derivative works or by other
 works in which the Apple Software may be incorporated.
 
 The Apple Software is provided by Apple on an "AS IS" basis.  APPLE
 MAKES NO WARRANTIES, EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION
 THE IMPLIED WARRANTIES OF NON-INFRINGEMENT, MERCHANTABILITY AND FITNESS
 FOR A PARTICULAR PURPOSE, REGARDING THE APPLE SOFTWARE OR ITS USE AND
 OPERATION ALONE OR IN COMBINATION WITH YOUR PRODUCTS.
 
 IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL
 OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 INTERRUPTION) ARISING IN ANY WAY OUT OF THE USE, REPRODUCTION,
 MODIFICATION AND/OR DISTRIBUTION OF THE APPLE SOFTWARE, HOWEVER CAUSED
 AND WHETHER UNDER THEORY OF CONTRACT, TORT (INCLUDING NEGLIGENCE),
 STRICT LIABILITY OR OTHERWISE, EVEN IF APPLE HAS BEEN ADVISED OF THE
 POSSIBILITY OF SUCH DAMAGE.
 
 Copyright (C) 2013 Apple Inc. All Rights Reserved.
 
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

