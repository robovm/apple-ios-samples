/*
 Copyright (C) 2014 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 
   Metal Particle System for Metal Shader Showpiece. Initializes the particle system data that is sent to the GPU.
  
 */


#import <Foundation/Foundation.h>
#import <Metal/Metal.h>
#import "AAPLSharedTypes.h"

@interface AAPLParticleSystem : NSObject

@property (nonatomic) id <MTLBuffer> initial_direction_buffer;
@property (nonatomic) id <MTLBuffer> birth_offsets_buffer;
@property (nonatomic, readonly) unsigned int num_particles;
@property (nonatomic, readonly) float lifespan;

- (instancetype)initWithDevice:(id <MTLDevice>)device;
@end
