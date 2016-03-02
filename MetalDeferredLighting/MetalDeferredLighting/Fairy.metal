/*
 Copyright (C) 2016 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 Fairy shader
 */

#include <metal_graphics>
#include <metal_texture>
#include <metal_matrix>
#include <metal_common>

#include "common.h"

using namespace AAPL;
using namespace metal;


struct VertexInput
{
	float4 position;
	float4 view_light_position;
	float4 color;
};

struct VertexOutput
{
	float4 pos [[position]];
	float3 color;
	float pointSize [[point_size]];
};

vertex VertexOutput fairyVertex(device VertexInput *posData [[buffer(0)]],
                                constant float4x4 &mvp [[buffer(1)]],
                                uint vid [[vertex_id]])
{
	VertexOutput output; 
    VertexInput vData = posData[vid];
	float4 position = float4(vData.position.xyz, 1.0f);
	float3 color = float3(vData.color);
	
	output.pos = mvp * position;
	output.pointSize = 100 / output.pos.w;
	output.color = color;

	return output;
}

static float contrast(float Input, float ContrastPower)
{
     // piecewise contrast function
     bool IsAboveHalf = Input > 0.5;
     float ToRaise = clamp(2.0 * (IsAboveHalf ? 1.0 - Input : Input), 0.0, 1.0);
     float Output = 0.5 * pow(ToRaise, ContrastPower);
     Output = IsAboveHalf ? 1.0 - Output : Output;
     return Output;
}

fragment FragOutput fairyFragment( VertexOutput vo [[stage_in]],
                                  float2 pcoord [[point_coord]],
                                  constant SpriteData &sprite [[buffer(0)]],
                                  FragOutput g_buffers,
                                  texture2d<half> tex [[texture(0)]])
{
    constexpr sampler linear_sampler(min_filter::linear, mag_filter::linear);
	float3 color = vo.color * tex.sample(linear_sampler, pcoord).r;

	float scene_z = g_buffers.depth;
    
	float frag_z = 1.0 / vo.pos.w;
    
	float zdiff = (scene_z - frag_z);
	float c = contrast(zdiff * sprite.con_scale_intensity.y, sprite.con_scale_intensity.x);
    
	FragOutput output;

	color = color * sprite.con_scale_intensity.zzz * c;

	output.albedo = g_buffers.albedo + float4(color.xyz, 1.0);
	output.normal = g_buffers.normal;
	output.depth = g_buffers.depth;
	output.light = g_buffers.light;

	return output;

}
