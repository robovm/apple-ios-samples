/*
 Copyright (C) 2014 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information

 */

#import "AAPLRenderer.h"
#import "AAPLViewController.h"
#import "AAPLView.h"
#import "AAPLTransforms.h"
#import "AAPLSharedTypes.h"
#import "AAPLTeapotMesh.h"
#import "AAPLMesh.h"
#import "AAPLParticleSystemRenderer.h"
#import "AAPLParticleSystem.h"


@implementation AAPLParticleSystemRenderer
{
    // particle system data
    NSDate* _startTime;
    AAPLParticleSystem* _particleSystem;
}

// Overriding base class method to make particles blend
- (instancetype)initWithName:(NSString *)name vertexShader:(NSString *)vertexShaderName fragmentShader:(NSString *)fragmentShaderName mesh:(AAPLMesh *)mesh
{
    self = [super initWithName:name vertexShader:vertexShaderName fragmentShader:fragmentShaderName mesh:mesh];
    
    if (self)
    {
        _blending = YES;
        _depthWriteEnabled = NO;
    }
    
    return self;
}

#pragma mark RENDER VIEW DELEGATE METHODS

// Overriding base class method to create the particle system, it's timer, and to set the particle's lifespan
- (void)configure:(AAPLView *)view
{
    [super configure:view];

    _startTime = [NSDate date];
    _particleSystem = [[AAPLParticleSystem alloc] initWithDevice:self.device];
    
    AAPL::uniforms_t* bufferPointer = (AAPL::uniforms_t *)[_dynamicConstantBuffer contents];
    bufferPointer->lifespan = _particleSystem.lifespan;
}

// Overriding base class method to render the particle system instead of the mesh
- (void)renderObject:(id <MTLRenderCommandEncoder>)renderEncoder view:(AAPLView *)view bufferOffset:(uint32_t)offset name:(NSString *)name
{
    [renderEncoder pushDebugGroup:name];
    [renderEncoder setRenderPipelineState:_pipelineState];
    
    // Go through the reflection items and set the buffers
    for (MTLArgument *arg in _reflection.vertexArguments)
    {
        if ([arg.name isEqualToString:@"initialDirection"])
        {
            [renderEncoder setVertexBuffer:_particleSystem.initial_direction_buffer offset:0 atIndex:arg.index];
        }
        else if ([arg.name isEqualToString:@"birthOffsets"])
        {
            [renderEncoder setVertexBuffer:_particleSystem.birth_offsets_buffer offset:0 atIndex:arg.index];
        }
        else if ([arg.name isEqualToString:@"uniforms"])
        {
            [renderEncoder setVertexBuffer:_dynamicConstantBuffer offset:offset atIndex:arg.index];
        }
    }
    
    // tell the render context we want to draw our primitives
    [renderEncoder drawPrimitives:MTLPrimitiveTypePoint vertexStart:0 vertexCount:_particleSystem.num_particles];
    [renderEncoder popDebugGroup];
}

#pragma mark VIEW CONTROLLER DELEGATE METHODS

// Overriding base class method to update the time of the particle system and make it not rotate
- (void)update:(AAPLViewController *)controller
{
    AAPL::uniforms_t* bufferPointer = (AAPL::uniforms_t *)[_dynamicConstantBuffer contents];
    simd::float4x4 model_matrix = AAPL::translate(0.0f, -0.2f, 1.0f);
    bufferPointer->model_matrix = model_matrix;
    
    // Update the time for our paticle system
    NSDate* currentTime = [NSDate date];
    bufferPointer->t = [currentTime timeIntervalSinceDate:_startTime];
}


@end
