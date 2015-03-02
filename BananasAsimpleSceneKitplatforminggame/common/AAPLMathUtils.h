/*
 Copyright (C) 2014 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 
  Utility math routines used throughout the app.
  
 */

#include <SceneKit/SceneKit.h>

static inline SCNVector3 AAPLMatrix4GetPosition(SCNMatrix4 matrix) {
	return (SCNVector3) {matrix.m41, matrix.m42, matrix.m43};
}

static inline SCNMatrix4 AAPLMatrix4SetPosition(SCNMatrix4 matrix, SCNVector3 v) {
	matrix.m41 = v.x; matrix.m42 = v.y; matrix.m43 = v.z;
	return matrix;
}

static inline CGFloat AAPLRandomPercent() {
	return ((rand() % 100)) * 0.01f;
}