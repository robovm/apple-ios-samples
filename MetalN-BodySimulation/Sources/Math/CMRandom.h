/*
 Copyright (C) 2015 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 Utility class for generating random values using uniform real distribution for a simd float3 vector with a least upper bound and a greatest lower bound.
 */

#ifndef _CORE_MATH_RANDOM_H_
#define _CORE_MATH_RANDOM_H_

#import <memory>
#import <random>

#import <simd/simd.h>

#ifdef __cplusplus

namespace CM
{
    namespace URD3
    {
        // Uniform real distribution triplets base class
        class core;
        
        // Facade for generating uniform random distribution triplets
        class generator
        {
        public:
            // Instantiate the object using a least uppper bound and a greatest lower
            // bound. If the length is a value greter than zero, then the object will
            // generate uniform real distribution triplets bounded by a 2-norm metric.
            // Otherwise, the instantiated object generates uniform real distribution
            // triplets without a bounding metric.
            generator(const float& min = 0.0f,
                      const float& max = 1.0f,
                      const float& len = 0.0f,
                      const float& eps = 1.0e-6);
            
            // Copy constructor
            generator(const generator& rObject);
            
            // Destructor
            virtual ~generator();
            
            // Assignment operator
            generator& operator=(const generator& rObject);
            
            // Get the greatest lower bound
            const float min() const;
            
            // Get the least upper bound
            const float max() const;
            
            // Reset the distribution such that subsequent values generated
            // are independent of previously generated values
            void reset();
            
            // Uniform real distribution triplets
            simd::float3 rand();
            
            // Normalized uniform real distribution triplets
            simd::float3 nrand();
            
        private:
            core* mpCore;
        }; // generator
        
        // Constructor method for creating a shared pointer.  If the length is
        // a value greter than zero, then the shared pointer returned will
        // be for the utility class for generating uniform real distribution
        // triplets bounded by a 2-norm metric. Otherwise, the shared pointer
        // returned will be for the utility class generating uniform real
        // distribution triplets without a bounding metric.
        std::shared_ptr<generator> shared_ptr(const float& min = 0.0f,
                                              const float& max = 1.0f,
                                              const float& len = 0.0f,
                                              const float& eps = 1.0e-6);
        
        // Constructor method for creating a unique pointer.  If the length is
        // a value greter than zero, then the unique pointer returned will
        // be for the utility class for generating uniform real distribution
        // triplets bounded by a 2-norm metric. Otherwise, the unique pointer
        // returned will be for the utility class generating uniform real
        // distribution triplets without a bounding metric.
        std::unique_ptr<generator> unique_ptr(const float& min = 0.0f,
                                              const float& max = 1.0f,
                                              const float& len = 0.0f,
                                              const float& eps = 1.0e-6);
    } // URD3
} // CM

#endif

#endif
