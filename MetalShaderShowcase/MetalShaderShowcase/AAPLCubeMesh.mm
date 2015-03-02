/*
 Copyright (C) 2014 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information

 */

#import "AAPLCubeMesh.h"

const int num_cube_indices = 36;
const int num_cube_vertices = 24;
const int num_cube_normals = 24;
const int num_cube_uvs = 24;

float cube_vertices[] = {
    //Left
    -1, -1, -1,
    -1, 1, -1,
    -1, 1, 1,
    -1, -1, 1,
    
    //Right
    1, -1, 1,
    1, 1, 1,
    1, 1, -1,
    1, -1, -1,
    
    //Bottom
    -1, -1, -1,
    -1, -1, 1,
    1, -1, 1,
    1, -1, -1,
    
    //Top
    -1, 1, -1,
    1, 1, -1,
    1, 1, 1,
    -1, 1, 1,
    
    //Back
    1, -1, -1,
    1, 1, -1,
    -1, 1, -1,
    -1, -1, -1,
    
    //Front
    -1, -1, 1,
    -1, 1, 1,
    1, 1, 1,
    1, -1, 1
};

float cube_uvs[] = {
    //Left
    0, 0,
    0, 1,
    1, 1,
    1, 0,
    
    //Right
    0, 0,
    0, 1,
    1, 1,
    1, 0,
    
    //Bottom
    0, 0,
    0, 1,
    1, 1,
    1, 0,
    
    //Top
    0, 0,
    0, 1,
    1, 1,
    1, 0,
    
    //Back
    0, 0,
    0, 1,
    1, 1,
    1, 0,
    
    //Front
    0, 0,
    0, 1,
    1, 1,
    1, 0,
};

short cube_indices[] = {
    //Left
    0, 1, 2,
    0, 2, 3,
    
    //Right
    4, 5, 6,
    4, 6, 7,
    
    //Bottom
    8, 9, 10,
    8, 10, 11,
    
    //Top
    12, 13, 14,
    12, 14, 15,
    
    //Back
    16, 17, 18,
    16, 18, 19,
    
    //Front
    20, 21, 22,
    20, 22, 23
};

float cube_tangents[] = {
    //Left
    0, 0, 1,
    0, 0, 1,
    0, 0, 1,
    0, 0, 1,
    
    //Right
    0, 0, -1,
    0, 0, -1,
    0, 0, -1,
    0, 0, -1,
    
    //Bottom
    1, 0, 0,
    1, 0, 0,
    1, 0, 0,
    1, 0, 0,
    
    //Top
    1, 0, 0,
    1, 0, 0,
    1, 0, 0,
    1, 0, 0,
    
    //Back
    -1, 0, 0,
    -1, 0, 0,
    -1, 0, 0,
    -1, 0, 0,
    
    //Front
    1, 0, 0,
    1, 0, 0,
    1, 0, 0,
    1, 0, 0
};

float cube_bitangents[] = {
    //Left
    0, 1, 0,
    0, 1, 0,
    0, 1, 0,
    0, 1, 0,
    
    //Right
    0, 1, 0,
    0, 1, 0,
    0, 1, 0,
    0, 1, 0,
    
    //Bottom
    0, 0, 1,
    0, 0, 1,
    0, 0, 1,
    0, 0, 1,
    
    //Top
    0, 0, -1,
    0, 0, -1,
    0, 0, -1,
    0, 0, -1,
    
    //Back
    0, 1, 0,
    0, 1, 0,
    0, 1, 0,
    0, 1, 0,
    
    //Front
    0, 1, 0,
    0, 1, 0,
    0, 1, 0,
    0, 1, 0
};

float cube_normals[] = {
    //Left
    -1, 0, 0,
    -1, 0, 0,
    -1, 0, 0,
    -1, 0, 0,
    
    //Right
    1, 0, 0,
    1, 0, 0,
    1, 0, 0,
    1, 0, 0,
    
    //Bottom
    0, -1, 0,
    0, -1, 0,
    0, -1, 0,
    0, -1, 0,
    
    //Top
    0, 1, 0,
    0, 1, 0,
    0, 1, 0,
    0, 1, 0,
    
    //Back
    0, 0, -1,
    0, 0, -1,
    0, 0, -1,
    0, 0, -1,
    
    //Front
    0, 0, 1,
    0, 0, 1,
    0, 0, 1,
    0, 0, 1
};

unsigned int sizeof_cube_vertices = sizeof(cube_vertices);
unsigned int sizeof_cube_normals = sizeof(cube_normals);
unsigned int sizeof_cube_uvs = sizeof(cube_uvs);
unsigned int sizeof_cube_indices = sizeof(cube_indices);
unsigned int sizeof_cube_tangents = sizeof(cube_tangents);
unsigned int sizeof_cube_bitangents = sizeof(cube_bitangents);


@interface AAPLCubeMesh ()

- (instancetype)initWithDevice:(id <MTLDevice>)device;

@end

@implementation AAPLCubeMesh

+ (instancetype)sharedInstance
{
    static AAPLCubeMesh *cubeMesh = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        id <MTLDevice> device = MTLCreateSystemDefaultDevice();
        cubeMesh = [[self alloc] initWithDevice:device];
    });
    return cubeMesh;
}

- (instancetype)initWithDevice:(id <MTLDevice>)device
{
    self = [super init];
    
    self.vertex_buffer = [device newBufferWithBytes:cube_vertices  length:sizeof_cube_vertices  options:MTLResourceOptionCPUCacheModeDefault];
    self.vertex_buffer.label = @"Vertices";
    
    self.normal_buffer = [device newBufferWithBytes:cube_normals  length:sizeof_cube_normals  options:MTLResourceOptionCPUCacheModeDefault];
    self.normal_buffer.label = @"Normals";
    
    self.tangents_buffer = [device newBufferWithBytes:cube_tangents  length:sizeof_cube_tangents  options:MTLResourceOptionCPUCacheModeDefault];
    self.tangents_buffer.label = @"Tangents";
    
    self.bitangents_buffer = [device newBufferWithBytes:cube_bitangents  length:sizeof_cube_bitangents  options:MTLResourceOptionCPUCacheModeDefault];
    self.bitangents_buffer.label = @"Bitangents";
    
    self.uv_buffer = [device newBufferWithBytes:cube_uvs  length:sizeof_cube_uvs  options:MTLResourceOptionCPUCacheModeDefault];
    self.uv_buffer.label = @"UVs";
    
    self.index_buffer = [device newBufferWithBytes:cube_indices  length:sizeof_cube_indices  options:MTLResourceOptionCPUCacheModeDefault];
    self.index_buffer.label = @"Indices";
    
    self.index_count = num_cube_indices;
    self.vertex_count = num_cube_vertices;
    self.primitive_type = MTLPrimitiveTypeTriangle;
    
    self.translate_x = 0.0f;
    self.translate_y = 0.0f;
    self.translate_z = 6.0f;
    
    self.indices = cube_indices;
    self.vertices = cube_vertices;
    self.normals = cube_normals;
    self.uvs = cube_uvs;
    self.tangents = cube_tangents;
    self.bitangents = cube_bitangents;
    
    return self;
}

@end
