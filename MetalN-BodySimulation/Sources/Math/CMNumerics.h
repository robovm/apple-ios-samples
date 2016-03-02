/*
 Copyright (C) 2015 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 Numerics utilities for fast-float comparison and swapping integer values.
 */

#ifndef _CORE_MATH_NUMERICS_H_
#define _CORE_MATH_NUMERICS_H_

#import <cstdlib>

#ifdef __cplusplus

namespace CM
{
    // Single and double precision comparisons
    bool isEQ(float&  x, float&  y, const int32_t& max = 1);
    bool isEQ(double& x, double& y, const int64_t& max = 1);
    
    bool isLT(float&  x, float&  y);
    bool isLT(double& x, double& y);
    
    bool isZero(float&  x, float&  eps);
    bool isZero(double& x, double& eps);
        
    // Storsge-free swap
    void swap(long&   x, long&   y);
    void swap(size_t& x, size_t& y);
    
    void swap(int8_t&  x, int8_t&  y);
    void swap(int16_t& x, int16_t& y);
    void swap(int32_t& x, int32_t& y);
    void swap(int64_t& x, int64_t& y);
    
    void swap(uint8_t&  x, uint8_t&  y);
    void swap(uint16_t& x, uint16_t& y);
    void swap(uint32_t& x, uint32_t& y);
    void swap(uint64_t& x, uint64_t& y);
} // CM

#endif

#endif
