/*
 Copyright (C) 2015 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 Default values for N-body simulation.
 */

#ifndef _NBODY_DEFAULTS_H_
#define _NBODY_DEFAULTS_H_

#import <cstdlib>

#ifdef __cplusplus

namespace NBody
{
    namespace Defaults
    {
        static const uint32_t kParticles = 1024 * 8;
        static const uint32_t kChannels  = 4;
        static const uint32_t kFrames    = 300;
        static const uint32_t kTexRes    = 64;

        static const float kAspectRatio  = 1.0f;
        static const float kCenter       = 0.5;
        static const float kDamping      = 1.0f;
        static const float kPointSz      = 10.0f;
        static const float kSofteningSqr = 1.0f;
        static const float kTolerance    = 1.0e-9;
        static const float kTimestep     = 0.016f;
        static const float kZCenter      = 100.0f;
        
        namespace Scale
        {
            static const float kCluster  = 1.54f;
            static const float kVelocity = 8.0f;
        } // Scale
        
        namespace Configs
        {
            enum : uint8_t
            {
                eRandom = 0,
                eShell,
                eExpand,
                eCount
            };
        } // Configs
    } // Defaults
} // NBody

#endif

#endif
