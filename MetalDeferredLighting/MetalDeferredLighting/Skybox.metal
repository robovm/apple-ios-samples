/*
 Copyright (C) 2016 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 Skybox shader
 */

#include <metal_graphics>
#include <metal_geometric>
#include <metal_matrix>
#include <metal_texture>

#include "common.h"

using namespace AAPL;
using namespace metal;

struct VertexOutput
{
	float4 position [[position]];
	float3 v_texcoord;
};


vertex VertexOutput skyboxVert(constant float4  *vert [[buffer(0)]],
                               constant float4x4 &mvp [[buffer(1)]],
                               uint vid [[vertex_id]] )
{
	VertexOutput output;

    // Note: we use the same data for vertex and texcoords for the skybox
    float3 vertexAndTexCoord = vert[vid].xyz;
	output.position = mvp * float4(vertexAndTexCoord, 1.0f);
	output.v_texcoord = vertexAndTexCoord;

	return output;
}

fragment FragOutput skyboxFrag(VertexOutput in [[stage_in]],
                                              texturecube<float> skybox_texture [[texture(0)]],
                                              constant ClearColorBuffers &clear_color_gbuffer [[buffer(0)]])
{
    constexpr sampler linear_sampler(min_filter::linear, mag_filter::linear);
	float4 color = skybox_texture.sample(linear_sampler, in.v_texcoord);
	FragOutput output;

	output.albedo = color;
	output.normal = clear_color_gbuffer.clear_color;
	output.depth = clear_color_gbuffer.linear_depth_clear_color.r;
	output.light = clear_color_gbuffer.light_buffer_clear_color;

	return output;
}    
