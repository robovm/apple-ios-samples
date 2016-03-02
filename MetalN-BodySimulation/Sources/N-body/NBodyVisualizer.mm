/*
 Copyright (C) 2015 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 N-body controller object for visualizing the simulation.
 */

#import <QuartzCore/CAMetalLayer.h>

#import "CMNumerics.h"

#import "NBodyDefaults.h"
#import "NBodyPreferences.h"
#import "NBodyProperties.h"
#import "NBodyURDGenerator.h"
#import "MetalNBodyPresenter.h"

#import "NBodyVisualizer.h"

@implementation NBodyVisualizer
{
@private
    BOOL  _haveVisualizer;
    BOOL  _isComplete;

    float _aspect;
    
    id<CAMetalDrawable> _drawable;

    uint32_t _particles;
    uint32_t _frames;
    uint32_t _texRes;
    uint32_t _config;
    uint32_t _active;
    uint32_t _frame;
    
    uint32_t mnCount;
    
    NBodyProperties*     mpProperties;
    NBodyURDGenerator*   mpGenerator;
    MetalNBodyPresenter* mpPresenter;
}

- (instancetype) init
{
    self = [super init];
    
    if(self)
    {
        _haveVisualizer = NO;
        _isComplete     = NO;
        
        _aspect    = NBody::Defaults::kAspectRatio;
        _frames    = NBody::Defaults::kFrames;
        _config    = NBody::Defaults::Configs::eShell;
        _texRes    = NBody::Defaults::kTexRes;
        _particles = NBody::Defaults::kParticles;
        
        _active = 0;
        _frame  = 0;
        
        _device   = nil;
        _drawable = nil;
        
        mpProperties = nil;
        mpGenerator  = nil;
        mpPresenter  = nil;
    } // if
    
    return self;
} // init

// Coordinate points on the Eunclidean axis of simulation
- (void) setAxis:(simd::float3)axis
{
    if(mpGenerator)
    {
        mpGenerator.axis = axis;
    } // if
} // setAxis

// Aspect ratio
- (void) setAspect:(float)aspect
{
    float nEPS = NBody::Defaults::kTolerance;
    
    _aspect = CM::isLT(nEPS, aspect) ? aspect : 1.0f;
} // setAspect

// The number of point particels
- (void) setParticles:(uint32_t)particles
{
    if(!_haveVisualizer)
    {
        mpProperties.particles = _particles = (particles) ? particles : NBody::Defaults::kParticles;
    } // if
} // setParticles

// Texture resolution.  The default is 64x64.
- (void) setTexRes:(uint32_t)texRes
{
    if(!_haveVisualizer)
    {
        mpProperties.texRes = _texRes = (texRes > 64) ? texRes :  NBody::Defaults::kTexRes;
    } // if
} // setResolution

// Total number of frames to be rendered for a N-body simulation type
- (void) setFrames:(uint32_t)frames
{
    _frames = (frames) ? frames : NBody::Defaults::kFrames;
} // setFrames

- (BOOL) _acquire:(nullable id<MTLDevice>)device
{
    if(device)
    {
        // Get the N-body simulation properties from a property list file in app's resource
        mpProperties = [NBodyProperties new];
        
        if(!mpProperties)
        {
            NSLog(@">> ERROR: Failed to instantiate N-body properties object!");
            
            return NO;
        } // if
        
        mnCount = mpProperties.count;
        
        if(!mnCount)
        {
            NSLog(@">> ERROR: Empty array for N-Body properties!");
            
            return NO;
        } // if
        
        // Instantiate a new generator object for initial simualtion random data
        mpGenerator = [NBodyURDGenerator new];
        
        if(!mpGenerator)
        {
            NSLog(@">> ERROR: Failed to instantiate uniform random distribution object!");
            
            return NO;
        } // if
        
        // Instantiate a new render encoder object for N-body simaulation 
        mpPresenter = [MetalNBodyPresenter new];
        
        if(!mpPresenter)
        {
            NSLog(@">> ERROR: Failed to instantiate Metal render encoder object!");
            
            return NO;
        } // if
                
        mpPresenter.globals = mpProperties.globals;
        mpPresenter.device  = device;
        
        if(!mpPresenter.haveEncoder)
        {
            NSLog(@">> ERROR: Failed to acquire resources for the render encoder object!");
            
            return NO;
        } // if
        
        return YES;
    } // if
    
    return NO;
} // _acquire

- (void) _update
{
    NSLog(@">> MESSAGE[N-Body]: Demo [%u] selected!", _active);
    
    // Update the linear transformation matrices
    mpPresenter.update = YES;
    
    // Select a new dictionary of key-value pairs for simulation properties
    mpProperties.config = _active;
    
    // Using the properties dictionary generate initial data for the simulation
    mpGenerator.parameters = mpProperties.parameters;
    mpGenerator.colors     = mpPresenter.colors;
    mpGenerator.position   = mpPresenter.position;
    mpGenerator.velocity   = mpPresenter.velocity;
    mpGenerator.config     = _config;
} // _update

// Generate all the resources necessary for N-body simulation
- (void) acquire:(nullable id<MTLDevice>)device
{
    if(!_haveVisualizer)
    {
        _haveVisualizer = [self _acquire:device];
        
        if(_haveVisualizer)
        {
            [self _update];
        } // if
    } // if
} // acquire

// Render a new frame
- (void) _renderFrame:(nullable id<CAMetalDrawable>)drawable
{
    mpPresenter.aspect     = _aspect;                 // Update the aspect ratio
    mpPresenter.parameters = mpProperties.parameters; // Update the simulation parameters
    mpPresenter.drawable   = drawable;                // Set the new drawable and present
} // _renderFrame

// Go to a new frame
- (void) _nextFrame
{
    _frame++;
    
    _isComplete = (_frame % _frames) == 0;
    
    // If we reach the maximum number of frames switch to a new simulation type
    if(_isComplete)
    {
        [mpPresenter finish];
        
        _active = (_active + 1) % mnCount;
        
        [self _update];
    } // if
} // _nextFrame

// Render a frame for N-body simaulation
- (void) render:(nullable  id<CAMetalDrawable>)drawable
{
    if(drawable)
    {
        [self _renderFrame:drawable];
        [self _nextFrame];
    } // if
} // render

@end
