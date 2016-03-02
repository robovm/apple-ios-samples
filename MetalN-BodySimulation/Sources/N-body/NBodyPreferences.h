/*
 Copyright (C) 2015 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 Keys for the N-Body application preferences, global parameters, and simulation properties.
 */

#import <Foundation/Foundation.h>

// Keys for the N-Body application prefs property list      // For values
extern NSString* kNBodyGlobals;                             // Dictionary
extern NSString* kNBodyParameters;                          // Array of dictionaries

// Keys for the N-Body globals parameters                   // For values
extern NSString* kNBodyParticles;                           // Unsigned Integer 32
extern NSString* kNBodyTexRes;                              // Unsigned Integer 32
extern NSString* kNBodyChannels;                            // Unsigned Integer 32

// Keys for the N-Body simulation properties                // For values
extern NSString* kNBodyTimestep;                            // Float
extern NSString* kNBodyClusterScale;                        // Float
extern NSString* kNBodyVelocityScale;                       // Float
extern NSString* kNBodySoftening;                           // Float
extern NSString* kNBodyDamping;                             // Float
extern NSString* kNBodyPointSize;                           // Float
