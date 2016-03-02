/*
 <codex>
 <abstract>
 Base class for generating random packed or split data sets for the gpu bound simulator using unifrom real distribution.
 </abstract>
 </codex>
 */

#import <simd/simd.h>

#import <Foundation/Foundation.h>

@interface NBodyURDGenerator : NSObject

// Generate a inital simulation data
@property (nonatomic, setter=acquire:) uint32_t config;

// N-body simulation global parameters
@property (nullable, nonatomic) NSDictionary* globals;

// N-body parameters for simulation types
@property (nullable, nonatomic) NSDictionary* parameters;

// Coordinate points on the Eunclidean axis of simulation
@property (nonatomic) simd::float3 axis;

// Position and velocity pointers
@property (nullable) simd::float4* position;
@property (nullable) simd::float4* velocity;

// Colors pointer
@property (nullable, nonatomic) simd::float4* colors;

@end
