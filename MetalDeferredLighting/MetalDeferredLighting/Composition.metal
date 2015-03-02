/*
 <samplecode>
 <abstract>
 Composition shader
 </abstract>
 </samplecode>
 */

#include <metal_graphics>
#include <metal_geometric>

#include "common.h"

using namespace AAPL;
using namespace metal;

struct VertexOutput
{
	float4 position [[position]];
};

vertex VertexOutput compositionVertex(constant float2 *posData [[buffer(0)]],
                                   uint vid [[vertex_id]] )
{
	VertexOutput output;
	output.position = float4(posData[vid], 0.0f, 1.0f);
	return output;
}

// This fragment program will write its output to color[0], effectively overwriting the contents of gBuffers.albedo
fragment float4 compositionFrag(VertexOutput in [[stage_in]],
                                 constant MaterialSunData &sunData [[buffer(0)]],
                                 FragOutput gBuffers)
{
    float4 light = gBuffers.light;
    float3 diffuse = light.rgb;
    float3 specular = light.aaa;
	
    float3 n_s = gBuffers.normal.rgb;
    float sun_atten = gBuffers.albedo.a;
    float sun_diffuse = fmax(dot(n_s * 2.0 - 1.0, sunData.sunDirection.xyz), 0.0) * sun_atten;
	
    diffuse += sunData.sunColor.rgb * sun_diffuse;
	
    diffuse *= gBuffers.albedo.rgb;
	
    // Specular lighting mask is stored in gBuffers.normal.w
    specular *= gBuffers.normal.w;
    
    diffuse += diffuse;
    specular += specular;
    
    return float4(diffuse.xyz + specular.xyz, 1.0);
}

