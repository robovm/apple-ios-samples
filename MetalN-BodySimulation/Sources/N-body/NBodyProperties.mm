/*
 Copyright (C) 2015 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 Utility class for managing a set of defualt initial conditions for n-body simulation.
 */

#import "NBodyDefaults.h"
#import "NBodyPreferences.h"
#import "NBodyProperties.h"

@implementation NBodyProperties
{
@private
    uint32_t  _count;
    uint32_t  _config;
    uint32_t  _particles;
    uint32_t  _texRes;
    uint32_t  _channels;
    
    NSMutableDictionary* mpGlobals;
    NSMutableDictionary* mpParameters;
    
    NSMutableArray* mpProperties;
}

- (nullable NSMutableDictionary *) _newProperties:(nullable NSString *)pFileName
{
    NSMutableDictionary* pProperties = nil;
    
    if(!pFileName)
    {
        NSLog(@">> ERROR: File name is nil!");
        
        return nil;
    } // if

    NSBundle* pBundle = [NSBundle mainBundle];
    
    if(!pBundle)
    {
        NSLog(@">> ERROR: Failed acquiring a main bundle object!");

        return nil;
    } // if
    
    NSString* pPathname = [NSString stringWithFormat:@"%@/%@", pBundle.resourcePath, pFileName];
    
    if(!pPathname)
    {
        NSLog(@">> ERROR: Failed instantiating a pathname from reource path and file name!");

        return nil;
    } // if
    
    NSData* pXML = [NSData dataWithContentsOfFile:pPathname];
    
    if(!pXML)
    {
        NSLog(@">> ERROR: Failed instantiating a xml data from the contents of a file!");

        return nil;
    } // if
    
    NSError* pError = nil;
    
    NSPropertyListFormat format = NSPropertyListXMLFormat_v1_0;
    
    pProperties = [NSPropertyListSerialization propertyListWithData:pXML
                                                            options:NSPropertyListMutableContainers
                                                             format:&format
                                                              error:&pError];
    
    if(pError)
    {
        NSLog(@">> ERROR: \"%@\"", pError.description);
    } // if
    
    return pProperties;
} // _newProperties

// Designated initializer for loading the property list file containing
// global and simulation parameters
- (nullable instancetype) initWithFile:(nullable NSString *)fileName
{
    self = [super init];
    
    if(self)
    {
        NSMutableDictionary* pProperties = [self _newProperties:fileName];
        
        if(pProperties)
        {
            mpGlobals = pProperties[kNBodyGlobals];
            
            if(mpGlobals)
            {
                _particles = [mpGlobals[kNBodyParticles] unsignedIntValue];
                _texRes    = [mpGlobals[kNBodyTexRes]    unsignedIntValue];
                _channels  = [mpGlobals[kNBodyChannels]  unsignedIntValue];
            } // if
            
            mpProperties = pProperties[kNBodyParameters];
            
            if(mpProperties)
            {
                _count  = uint32_t(mpProperties.count);
                _config = _count;
            } // if
            
            mpParameters = nil;
        } // if
    } // if
    
    return self;
} // init

- (nullable instancetype) init
{
    return [self initWithFile:@"NBodyAppPrefs.plist"];
} // init

// N-body simulation global parameters
- (NSDictionary *) globals
{
    return mpGlobals;
} // globals

// N-body parameters for simulation types
- (NSDictionary *) parameters
{
    return mpParameters;
} // parameters

// Select the specific type of N-body simulation
- (void) setConfig:(uint32_t)config
{
    if(config != _config)
    {
        _config = config;
        
        mpParameters = mpProperties[_config];
    } // if
} // setConfig

// Number of point particles
- (void) setParticles:(uint32_t)particles
{
    const uint32_t ptparticles = (particles > 1024) ? particles : NBody::Defaults::kParticles;
    
    if(ptparticles != _particles)
    {
        _particles = ptparticles;
        
        mpGlobals[kNBodyParticles] = @(_particles);
    } // if
} // setParticles

// Number of color channels.  Default is 4 for RGBA.
- (void) setChannels:(uint32_t)channels
{
    const uint32_t nChannels = (channels) ? channels : NBody::Defaults::kChannels;
    
    if(nChannels != _channels)
    {
        _channels = nChannels;
        
        mpGlobals[kNBodyChannels] = @(_channels);
    } // if
} // setChannels

// Texture resolution.  The default is 64x64.
- (void) setTexRes:(uint32_t)texRes
{
    const uint32_t nTexRes = (texRes) ? texRes : NBody::Defaults::kTexRes;
    
    if(nTexRes != _texRes)
    {
        _texRes = nTexRes;
        
        mpGlobals[kNBodyTexRes] = @(_texRes);
    } // if
} // setTexRes

@end
