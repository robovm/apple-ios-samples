/*
 Copyright (C) 2014 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 
  A class to represent a cube mesh used for drawing.
  
 */

#import "AAPLMesh.h"

extern const int num_cube_indices;
extern const int num_cube_vertices;
extern const int num_cube_normals;
extern const int num_cube_uvs;

extern float cube_vertices[];
extern float cube_normals[];
extern float cube_uvs[];
extern short cube_indices[];
extern float cube_tangents[];
extern float cube_bitangents[];

extern unsigned int sizeof_cube_vertices;
extern unsigned int sizeof_cube_normals;
extern unsigned int sizeof_cube_uvs;
extern unsigned int sizeof_cube_indices;


@interface AAPLCubeMesh : AAPLMesh

@end
