/*
     File: vectorUtil.h
 Abstract: 
 Functions for performing vector math.
 
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

#ifndef __VECTOR_UTIL_H__
#define __VECTOR_UTIL_H__

// A Vector is floating point array with either 3 or 4 components
// functions with the vec4 prefix require 4 elements in the array
// functions with vec3 prefix require only 3 elements in the array

// Subtracts one 4D vector to another
void vec4Add(float* vec, const float* lhs, const float* rhs);

// Subtracts one 4D vector from another
void vec4Subtract(float* vec, const float* lhs, const float* rhs);

// Multiplys one 4D vector by another
void vec4Multiply(float* vec, const float* lhs, const float* rhs);

// Divides one 4D vector by another
void vec4Divide(float* vec, const float* lhs, const float* rhs);

// Subtracts one 4D vector to another
void vec3Add(float* vec, const float* lhs, const float* rhs);

// Subtracts one 4D vector from another
void vec3Subtract(float* vec, const float* lhs, const float* rhs);

// Multiplys one 4D vector by another
void vec3Multiply(float* vec, const float* lhs, const float* rhs);

// Divides one 4D vector by another
void vec3Divide(float* vec, const float* lhs, const float* rhs);

// Calculates the Cross Product of a 3D vector
void vec3CrossProduct(float* vec, const float* lhs, const float* rhs);

// Normalizes a 3D vector
void vec3Normalize(float* vec, const float* src);

// Returns the Dot Product of 2 3D vectors
float vec3DotProduct(const float* lhs, const float* rhs);

// Returns the Dot Product of 2 4D vectors
float vec4DotProduct(const float* lhs, const float* rhs);

// Returns the length of a 3D vector 
// (i.e the distance of a point from the origin)
float vec3Length(const float* vec);

// Returns the distance between two 3D points
float vec3Distance(const float* pointA, const float* pointB);

#endif //__VECTOR_UTIL_H__
