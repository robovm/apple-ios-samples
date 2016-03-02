/*
 <codex>
 <import>NBodyURDGenerator.h</import>
 </codex>
 */

#import <memory>

#import "CFQueueGenerator.h"

#import "CMNumerics.h"
#import "CMRandom.h"

#import "NBodyDefaults.h"
#import "NBodyPreferences.h"

#import "NBodyURDGenerator.h"

static const float kScale = 1.0f/1024.0f;

struct NBodyScales
{
    float mnCluster;
    float mnVelocity;
    float mnParticles;
};

typedef struct NBodyScales NBodyScales;

@implementation NBodyURDGenerator
{
@private
    uint32_t _config;
    
    NSDictionary* _globals;
    NSDictionary* _parameters;
    
    simd::float3 _axis;
    
    simd::float4* _position;
    simd::float4* _velocity;
    simd::float4* _colors;
    
    bool isComplete;
    
    uint32_t mnParticles;
    
    NBodyScales m_Scales;
    
    dispatch_queue_t m_DQueue;
    
    std::unique_ptr<CM::URD3::generator> mpGenerator[2];
}

- (instancetype) init
{
    self = [super init];
    
    if(self)
    {
        mpGenerator[0] = CM::URD3::unique_ptr();
        mpGenerator[1] = CM::URD3::unique_ptr(-1.0f, 1.0f, 1.0f);

        _globals    = nil;
        _parameters = nil;
        
        _config = NBody::Defaults::Configs::eCount;
        
        _axis = {0.0f, 0.0f, 1.0f};
        
        _position = nullptr;
        _velocity = nullptr;
        _colors   = nullptr;
        
        m_DQueue = nullptr;
        
        mnParticles = NBody::Defaults::kParticles;
        
        m_Scales.mnCluster   = NBody::Defaults::Scale::kCluster;
        m_Scales.mnVelocity  = NBody::Defaults::Scale::kVelocity;
        m_Scales.mnParticles = kScale * float(mnParticles);
        
        isComplete = (mpGenerator[0] != nullptr) && (mpGenerator[1] != nullptr);
    } // if
    
    return self;
} // init

// Coordinate points on the Eunclidean axis of simulation
- (void) setAxis:(simd::float3)axis
{
    _axis = simd::normalize(axis);
} // setAxis

// Colors pointer
- (void) setColors:(simd::float4 *)colors
{
    if(colors != nullptr)
    {
        _colors = colors;
        
        dispatch_apply(mnParticles, m_DQueue, ^(size_t i) {
            _colors[i].xyz = mpGenerator[0]->rand();
            _colors[i].w   = 1.0f;
        });
    } // if
} // setColors

// N-body simulation global parameters
- (void) setGlobals:(NSDictionary *)globals
{
    if(globals)
    {
        _globals = globals;
        
        mnParticles = [_globals[kNBodyParticles] unsignedIntValue];
        
        m_Scales.mnParticles = kScale * float(mnParticles);
    } // if
} // setGlobals

// N-body parameters for simulation types
- (void) setParameters:(NSDictionary *)parameters
{
    if(parameters)
    {
        _parameters = parameters;
        
        m_Scales.mnCluster  = [_parameters[kNBodyClusterScale]  floatValue];
        m_Scales.mnVelocity = [_parameters[kNBodyVelocityScale] floatValue];
    } // if
} // setParameters

- (void) _configRandom
{
    const float pscale = m_Scales.mnCluster  * std::max(1.0f, m_Scales.mnParticles);
    const float vscale = m_Scales.mnVelocity * pscale;
    
    dispatch_apply(mnParticles, m_DQueue, ^(size_t i) {
        simd::float3 point    = mpGenerator[1]->nrand();
        simd::float3 velocity = mpGenerator[1]->nrand();
        
        _position[i].xyz = pscale * point;
        _position[i].w   = 1.0f;
        
        _velocity[i].xyz = vscale * velocity;
        _velocity[i].w   = 1.0f;
    });
} // _configRandom

- (void) _configShell
{
    const float pscale = m_Scales.mnCluster;
    const float vscale = pscale * m_Scales.mnVelocity;
    const float inner  = 2.5f * pscale;
    const float outer  = 4.0f * pscale;
    const float length = outer - inner;
    
    dispatch_apply(mnParticles, m_DQueue, ^(size_t i) {
        simd::float3 nrpos    = mpGenerator[1]->nrand();
        simd::float3 rpos     = mpGenerator[0]->rand();
        simd::float3 position = nrpos * (inner + (length * rpos));
        
        _position[i].xyz = position;
        _position[i].w   = 1.0;
        
        simd::float3 axis = _axis;
        
        float scalar = simd::dot(nrpos, axis);
        
        if((1.0f - scalar) < 1e-6)
        {
            axis.xy = nrpos.yx;
            
            axis = simd::normalize(axis);
        } // if
        
        simd::float3 velocity = simd::cross(position, axis);
        
        _velocity[i].xyz = velocity * vscale;
        _velocity[i].w   = 1.0;
    });
} // _configShell

- (void) _configExpand
{
    const float pscale = m_Scales.mnCluster * std::max(1.0f, m_Scales.mnParticles);
    const float vscale = pscale * m_Scales.mnVelocity;
    
    dispatch_apply(mnParticles, m_DQueue, ^(size_t i) {
        simd::float3 point = mpGenerator[1]->rand();
        
        _position[i].xyz = point * pscale;
        _position[i].w   = 1.0;
        
        _velocity[i].xyz = point * vscale;
        _velocity[i].w   = 1.0;
    });
} // _configExpand

// Generate a inital simulation data
- (void) acquire:(uint32_t)config
{
    if(isComplete && (_position != nullptr) && (_velocity != nullptr))
    {
        _config = config;
        
        if(!m_DQueue)
        {
            CFQueueGenerator* pQGen = [CFQueueGenerator new];
            
            if(pQGen)
            {
                pQGen.label = "com.apple.nbody.generator.main";
                
                m_DQueue = pQGen.queue;
            } // if
        } // if
        
        if(m_DQueue)
        {
            switch(_config)
            {
                case NBody::Defaults::Configs::eExpand:
                    [self _configExpand];
                    break;
                    
                case NBody::Defaults::Configs::eRandom:
                    [self _configRandom];
                    break;
                    
                case NBody::Defaults::Configs::eShell:
                default:
                    [self _configShell];
                    break;
            } // switch
        } // if
    } // if
} // acquire

@end
