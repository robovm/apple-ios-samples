/*
 Copyright (C) 2014 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information

 */

#import "AAPLParticleSystem.h"

static const unsigned int NUM_PARTICLES = 200;
static const float SPREAD = 0.1f;
static const float LIFESPAN = 1.0f;

@implementation AAPLParticleSystem
{
    float* _initialDirection;
    float* _birthOffsets;
}

- (instancetype)initWithDevice:(id <MTLDevice>)device
{
    self = [super init];
    if (self)
    {
        // Allocate and initialize the initial direction buffer
        unsigned int initialDirectionDataSize = NUM_PARTICLES * 3 * sizeof(float);
        _initialDirection = (float*) malloc(initialDirectionDataSize);
        
        // Set the initial direction as a random vector mostly pointing up with the variable
        // SPREAD controlling the ammount the particles go out from the center.
        for (unsigned int i = 0; i < NUM_PARTICLES; i++) {
            
            float d_0_x = ( (2.0f * ( (float)rand()/RAND_MAX ) ) - 1.0f) * SPREAD;
            float d_0_y = ( (float)rand()/RAND_MAX );
            float d_0_z = ( (2.0f * ( (float)rand()/RAND_MAX ) ) - 1.0f) * SPREAD;
            float length = sqrtf(d_0_x*d_0_x + d_0_y*d_0_y + d_0_z*d_0_z);
            
            // Normalize the initial direction vector so the length of the vectoris always
            // one.
            _initialDirection[i*3] = d_0_x / length;
            _initialDirection[i*3+1] = d_0_y / length;
            _initialDirection[i*3+2] = d_0_z / length;
            
        }
        
        _initial_direction_buffer = [device newBufferWithBytes:_initialDirection  length:initialDirectionDataSize  options:MTLResourceOptionCPUCacheModeDefault];
        _initial_direction_buffer.label = @"Velocities";
        
        // Allocate and initialize the birth offsets. These are random numbers between 0 and
        // the lifespan that make it so all the particles don't come out of the emitter at
        // the same time.
        unsigned int birthOffsetsDataSize = NUM_PARTICLES * sizeof(float);
        _birthOffsets = (float*) malloc(birthOffsetsDataSize);
        
        for (unsigned int i = 0; i < NUM_PARTICLES; i++) {
            _birthOffsets[i] = ( (float)rand()/RAND_MAX ) * LIFESPAN;
        }
        
        _birth_offsets_buffer = [device newBufferWithBytes:_birthOffsets  length:birthOffsetsDataSize  options:MTLResourceOptionCPUCacheModeDefault];
        _birth_offsets_buffer.label = @"Birth Offsets";
        
        
        _num_particles = NUM_PARTICLES;
        _lifespan = LIFESPAN;
    }
    return self;
}

@end
