/*
 Copyright (C) 2016 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 GBuffer shader
 */

#include <metal_graphics>
#include <metal_texture>
#include <metal_matrix>
#include <metal_math>

#include "common.h"

using namespace AAPL;
using namespace metal;

struct Vertex
{
    packed_float3 position;
    packed_float3 normal;
    packed_float3 texcoord;
    packed_float3 tangent;
    packed_float3 bitangent;
};

struct VertexOutput
{
	float4 position [[position]];
	float4 v_shadowcoord;
	float3 v_normal;
	float3 v_tangent;
	float3 v_bitangent;
	float3 v_texcoord;
	float v_lineardepth;
};

vertex VertexOutput gBufferVert(device Vertex *pos_data [[ buffer(0) ]],
                                constant ModelMatrices *matrices [[ buffer(1) ]],
                                uint vid [[vertex_id]])
{
	VertexOutput output;

    Vertex vData = pos_data[vid];
    
	float3 normal = float3(vData.normal);
	float3 tangent = float3(vData.tangent);
	float3 bitangent = float3(vData.bitangent);
	float4 tempPosition = float4(vData.position, 1.0f);

	output.v_normal = normal.xxx * matrices->normalMatrix[0].xyz;
	output.v_normal += normal.yyy * matrices->normalMatrix[1].xyz;
	output.v_normal += normal.zzz * matrices->normalMatrix[2].xyz;
	output.v_normal = normalize(output.v_normal);

	output.v_tangent = tangent.xxx * matrices->normalMatrix[0].xyz;
	output.v_tangent += tangent.yyy * matrices->normalMatrix[1].xyz;
	output.v_tangent += tangent.zzz * matrices->normalMatrix[2].xyz;
	output.v_tangent = normalize(output.v_tangent);

	output.v_bitangent = bitangent.xxx * matrices->normalMatrix[0].xyz;
	output.v_bitangent += bitangent.yyy * matrices->normalMatrix[1].xyz;
	output.v_bitangent += bitangent.zzz * matrices->normalMatrix[2].xyz;
	output.v_bitangent = normalize(output.v_bitangent);

	output.v_lineardepth = (matrices->mvMatrix * tempPosition).z;

	output.v_texcoord = float3(vData.texcoord);

	output.position = tempPosition.xxxx * matrices->mvpMatrix[0];
	output.position += tempPosition.yyyy * matrices->mvpMatrix[1];
	output.position += tempPosition.zzzz * matrices->mvpMatrix[2];
	output.position += matrices->mvpMatrix[3];

	output.v_shadowcoord = matrices->shadowMatrix * tempPosition;

	return output;
}

fragment FragOutput gBufferFrag(VertexOutput in [[stage_in]],
                                               constant float4 &clear_color_gbuffer3 [[buffer(0)]],
                                               texture2d<half> bump_texture [[texture(0)]],
                                               texture2d<float> albedo_texture [[texture(1)]],
                                               texture2d<half> specular_texture [[texture(2)]],
                                               depth2d<float> shadow_texture [[texture(3)]])
{
    constexpr sampler linear_sampler(min_filter::linear, mag_filter::linear);
    
	half3 tangent_normal = bump_texture.sample(linear_sampler, in.v_texcoord.xy).xyz * 2.0 - 1.0;
	float4 albedo = albedo_texture.sample(linear_sampler, in.v_texcoord.xy);
	
	half specular_mask = specular_texture.sample(linear_sampler, in.v_texcoord.xy).r;
	float3 world_normal = in.v_normal * tangent_normal.z + in.v_tangent * tangent_normal.x - in.v_bitangent * tangent_normal.y;
//	float3 world_normal = in.v_normal * tangent_normal.z + in.v_normal * tangent_normal.x - in.v_normal * tangent_normal.y;
	float scale = rsqrt(dot(world_normal, world_normal)) * 0.5;

	constexpr sampler shadow_sampler(coord::normalized, filter::linear, address::clamp_to_edge, compare_func::less);

	float r = shadow_texture.sample_compare(shadow_sampler, in.v_shadowcoord.xy, in.v_shadowcoord.z);

	FragOutput output;

	world_normal = world_normal * scale + 0.5;

	output.albedo.rgb = albedo.rgb;
	output.albedo.a = r;
	output.normal.rgb = world_normal.xyz;
	output.normal.w = specular_mask;
	output.depth = in.v_lineardepth;
	output.light = clear_color_gbuffer3;

	return output;
}