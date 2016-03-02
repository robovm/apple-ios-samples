/*
 Copyright (C) 2015 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 Keys for the N-Body application preferences, global parameters, and simulation properties.
 */

#import <Foundation/Foundation.h>

// Keys for the N-Body application prefs property list      // For values
NSString* kNBodyGlobals    = @"NBody_Globals";              // Dictionary
NSString* kNBodyParameters = @"NBody_Parameters";           // Array of dictionaries

// Keys for the N-Body globals parameters                   // For values
NSString* kNBodyParticles = @"NBody_Particles";             // Unsigned Integer 32
NSString* kNBodyTexRes    = @"NBody_Tex_Res";               // Unsigned Integer 32
NSString* kNBodyChannels  = @"NBody_Channels";              // Unsigned Integer 32

// Keys for the N-Body simulation properties                // For values
NSString* kNBodyTimestep      = @"NBody_Timestep";          // Float
NSString* kNBodyClusterScale  = @"NBody_Cluster_Scale";     // Float
NSString* kNBodyVelocityScale = @"NBody_Velocity_Scale";    // Float
NSString* kNBodySoftening     = @"NBody_Softening";         // Float
NSString* kNBodyDamping       = @"NBody_Damping";           // Float
NSString* kNBodyPointSize     = @"NBody_PointSize";         // Float
