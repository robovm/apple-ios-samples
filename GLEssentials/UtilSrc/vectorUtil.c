/*
     File: vectorUtil.c
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

#include "vectorUtil.h"

#include <math.h>
#include <memory.h>

void vec4Add(float* vec, const float* lhs, const float* rhs)
{
	vec[0] = lhs[0] + rhs[0];
	vec[1] = lhs[1] + rhs[1];
	vec[2] = lhs[2] + rhs[2];
	vec[3] = lhs[3] + rhs[3];
}

void vec4Subtract(float* vec, const float* lhs, const float* rhs)
{
	vec[0] = lhs[0] - rhs[0];
	vec[1] = lhs[1] - rhs[1];
	vec[2] = lhs[2] - rhs[2];
	vec[3] = lhs[3] - rhs[3];
}


void vec4Multiply(float* vec, const float* lhs, const float* rhs)
{
	vec[0] = lhs[0] * rhs[0];
	vec[1] = lhs[1] * rhs[1];
	vec[2] = lhs[2] * rhs[2];
	vec[3] = lhs[3] * rhs[3];
}

void vec4Divide(float* vec, const float* lhs, const float* rhs)
{
	vec[0] = lhs[0] / rhs[0];
	vec[1] = lhs[1] / rhs[1];
	vec[2] = lhs[2] / rhs[2];
	vec[3] = lhs[3] / rhs[3];
}


void vec3Add(float* vec, const float* lhs, const float* rhs)
{
	vec[0] = lhs[0] + rhs[0];
	vec[1] = lhs[1] + rhs[1];
	vec[2] = lhs[2] + rhs[2];
}

void vec3Subtract(float* vec, const float* lhs, const float* rhs)
{
	vec[0] = lhs[0] - rhs[0];
	vec[1] = lhs[1] - rhs[1];
	vec[2] = lhs[2] - rhs[2];
}


void vec3Multiply(float* vec, const float* lhs, const float* rhs)
{
	vec[0] = lhs[0] * rhs[0];
	vec[1] = lhs[1] * rhs[1];
	vec[2] = lhs[2] * rhs[2];
}

void vec3Divide(float* vec, const float* lhs, const float* rhs)
{
	vec[0] = lhs[0] / rhs[0];
	vec[1] = lhs[1] / rhs[1];
	vec[2] = lhs[2] / rhs[2];
}

float vec3DotProduct(const float* lhs, const float* rhs)
{
	return lhs[0]*rhs[0] + lhs[1]*rhs[1] + lhs[2]*rhs[2];	
}

float vec4DotProduct(const float* lhs, const float* rhs)
{
	return lhs[0]*rhs[0] + lhs[1]*rhs[1] + lhs[2]*rhs[2] + lhs[3]*rhs[3];	
}

void vec3CrossProduct(float* vec, const float* lhs, const float* rhs)
{
	vec[0] = lhs[1] * rhs[2] - lhs[2] * rhs[1];
	vec[1] = lhs[2] * rhs[0] - lhs[0] * rhs[2];
	vec[2] = lhs[0] * rhs[1] - lhs[1] * rhs[0];
}

float vec3Length(const float* vec)
{
	return sqrtf(vec[0]*vec[0] + vec[1]*vec[1] + vec[2]*vec[2]);
}

float vec3Distance(const float* pointA, const float* pointB)
{
	float diffx = pointA[0]-pointB[0];
	float diffy = pointA[1]-pointB[1];
	float diffz = pointA[2]-pointB[2];
	return sqrtf(diffx*diffx + diffy*diffy + diffz*diffz);
}

void vec3Normalize(float* vec, const float* src)
{
	float length = vec3Length(src);
	
	vec[0] = src[0]/length;
	vec[1] = src[1]/length;
	vec[2] = src[2]/length;
}


