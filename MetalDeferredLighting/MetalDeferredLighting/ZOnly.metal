/*
 <samplecode>
 <abstract>
 zOnly shader
 </abstract>
 </samplecode>
 */

#include <metal_graphics>
#include <metal_matrix>

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
};

vertex VertexOutput zOnly(constant Vertex *pos_data [[buffer(0)]],
                          constant float4x4 &mvp [[buffer(1)]],
                          uint vid [[vertex_id]] )
{
    float4 tempPosition = float4(pos_data[vid].position, 1.0f);

	VertexOutput output;
	output.position = mvp * tempPosition;

	return output;
}
