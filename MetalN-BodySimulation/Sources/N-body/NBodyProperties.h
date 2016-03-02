/*
 Copyright (C) 2015 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 Utility class for managing a set of defualt initial conditions for n-body simulation.
 */

#import <Foundation/Foundation.h>

@interface NBodyProperties : NSObject

// Designated initializer for loading the property list file containing
// global and simulation parameters
- (nullable instancetype) initWithFile:(nullable NSString *)fileName;

// Select the specific type of N-body simulation
@property (nonatomic) uint32_t config;

// Number of color channels.  Default is 4 for RGBA.
@property (nonatomic) uint32_t channels;

// Number of point particles
@property (nonatomic) uint32_t particles;

// Texture resolution.  The default is 64x64.
@property (nonatomic) uint32_t texRes;

// The number of N-body simulation types
@property (readonly) uint32_t count;

// N-body simulation global parameters
@property (nullable, nonatomic, readonly) NSDictionary* globals;

// N-body parameters for simulation types
@property (nullable, nonatomic, readonly) NSDictionary* parameters;

@end
