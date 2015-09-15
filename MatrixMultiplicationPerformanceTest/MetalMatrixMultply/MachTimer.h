/*
 Copyright (C) 2015 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 Utility class implementing a Mach hi-res timer
 */

#import <Foundation/Foundation.h>

@interface MachTimer: NSObject

// Number of cores per processor
@property (nonatomic) uint8_t cores;

// Number of processors
@property (nonatomic) uint8_t sockets;

// Number of loops for compute
@property (nonatomic) uint64_t loops;

// Time scale, where the default is millisecs
@property (nonatomic) uint32_t scale;

// The elapsed time per compute
@property (nonatomic, readonly) double elapsed;

// Giga flops or the theoretical maximum achieved
@property (nonatomic, readonly) double gflops;

// Start the timer
- (void) start;

// Stop the timer
- (void) stop;

@end
