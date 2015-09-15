/*
 Copyright (C) 2015 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information

 */

#import <mach/mach.h>
#import <mach/mach_time.h>
#import <unistd.h>

#import "MachTimer.h"

static const double kScaleMach   = 1.0e-9;
static const double kScaleGFlops = 1.0e-12;
static const double kScaleMSecs  = 1.0e5;

@implementation MachTimer
{
@private
    uint64_t mnStart;       // Start
    uint64_t mnStop;        // Stop time
    double   mnFreq;        // Host time frequency in ticks per seconds
    double   mnTime;        // Compute time
    double   mnCores;       // Number of cores per processor
    double   mnSockets;     // Number of processors
    double   mnLoops;       // Number of loops for compute
    double   mnScale;       // Time scale, where the default is millisecs
    double   _elapsed;      // The elapsed time per compute
    double   _gflops;       // Giga flops or the theoretical maximum achieved
}

- (instancetype) init
{
    self = [super init];
    
    if(self)
    {
        // Initializate with default values
        mnStart   = 0;
        mnStop    = 0;
        mnTime    = 0.0;
        mnLoops   = 1.0;
        mnCores   = 2.0;
        mnSockets = 1.0;
        mnScale   = kScaleMSecs;
        
        _elapsed = 0.0;
        _gflops  = 0.0;
        
        // The length of every unit of absolute time
        mach_timebase_info_data_t timebaseInfo;
        
        // Acquire length of every unit of absolute time
        mach_timebase_info(&timebaseInfo);
        
        // Compute the clock frequency
        mnFreq = kScaleMach * double(timebaseInfo.numer) / double(timebaseInfo.denom);
    } // if
    
    return self;
} // init

- (uint64_t) loops
{
    return uint64_t(mnLoops);
} // loops

- (uint8_t) sockets
{
    return uint8_t(mnSockets);
} // sockets

- (uint8_t) cores
{
    return uint8_t(mnCores);
} // cores

- (uint32_t) scale
{
    return uint32_t(mnScale);
} // scale

- (void) setLoops:(uint64_t)loops
{
    mnLoops = (loops) ? double(loops) : 1.0;
} // setCycles

- (void) setSockets:(uint8_t)sockets
{
    mnSockets = (sockets) ? double(sockets) : 1.0;
} // setSockets

- (void) setCores:(uint8_t)cores
{
    mnCores = (cores) ? double(cores) : 2.0;
} // setCores

- (void) setScale:(uint32_t)scale
{
    mnScale = (scale) ? double(scale) : kScaleMSecs;
} // setScale

- (void) start
{
    mnStart = mach_absolute_time();
} // start

- (void) stop
{
    mnStop = mach_absolute_time();
    mnTime = mnFreq * double(mnStop - mnStart) / mnLoops;
    
    _gflops  = kScaleGFlops * mnSockets * mnCores / mnTime;
    _elapsed = mnScale * mnTime;
} // stop

@end
