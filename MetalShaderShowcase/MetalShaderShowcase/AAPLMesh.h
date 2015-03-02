/*
 Copyright (C) 2014 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 
   A class to represent a mesh and its buffers used for drawing.
  
 */

#import <Foundation/Foundation.h>
#import <Metal/Metal.h>
#import "AAPLSharedTypes.h"


@interface AAPLMesh : NSObject

@property (nonatomic) id <MTLBuffer> vertex_buffer;
@property (nonatomic) id <MTLBuffer> normal_buffer;
@property (nonatomic) id <MTLBuffer> uv_buffer;
@property (nonatomic) id <MTLBuffer> tangents_buffer;
@property (nonatomic) id <MTLBuffer> bitangents_buffer;
@property (nonatomic) id <MTLBuffer> index_buffer;
@property (nonatomic) short* indices;
@property (nonatomic) float* vertices;
@property (nonatomic) float* normals;
@property (nonatomic) float* uvs;
@property (nonatomic) float* tangents;
@property (nonatomic) float* bitangents;
@property (nonatomic) unsigned int index_count;
@property (nonatomic) unsigned int vertex_count;
@property (nonatomic) MTLPrimitiveType primitive_type;
@property (nonatomic) float translate_x;
@property (nonatomic) float translate_y;
@property (nonatomic) float translate_z;

+ (instancetype)sharedInstance;

@end
