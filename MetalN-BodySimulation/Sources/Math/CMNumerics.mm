/*
 Copyright (C) 2015 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 Numerics utilities for fast-float comparison and swapping integer values.
 */

#import <cassert>

#import "CMNumerics.h"

#ifdef _SIGNED_SHIFT
#define NUMERICS_SGN_MASK_32(i) ((i)>>31)
#define NUMERICS_SGN_MASK_64(i) ((i)>>63)
#else
#define NUMERICS_SGN_MASK_32(i) (-(int32_t)(((uint32_t)(i))>>31))
#define NUMERICS_SGN_MASK_64(i) (-(int64_t)(((uint64_t)(i))>>63))
#endif

//-------------------------------------------------------------------------------
//
// Algorithm:  Performant single and double precision comparisons
//
// Lomont, Chris. “Floating Point Tricks”: Game Programming Gems #6, 2006, pg 121
//
//-------------------------------------------------------------------------------

bool CM::isEQ(float& x,
              float& y,
              const int32_t& max)
{
    int32_t v = *reinterpret_cast<int32_t *>(&x);
    int32_t w = *reinterpret_cast<int32_t *>(&y);
    int32_t r = NUMERICS_SGN_MASK_32(v^w);
    
    assert((0 == r) || (0xFFFFFFFF == r));
    
    int32_t d = (v ^ (r&  0x7FFFFFFF)) - w;
    
    int32_t lub = max + d;
    int32_t glb = max - d;
    
    return (lub|glb) >= 0;
} // isEQ

bool CM::isEQ(double& x,
              double& y,
              const int64_t& max)
{
    int64_t v = *reinterpret_cast<int64_t *>(&x);
    int64_t w = *reinterpret_cast<int64_t *>(&y);
    int64_t r = NUMERICS_SGN_MASK_64(v^w);
    
    assert((0 == r) || (0xFFFFFFFFFFFFFFFF == r));
    
    int64_t d = (v ^ (r&  0x7FFFFFFFFFFFFFFF)) - w;
    
    int64_t lub = max + d;
    int64_t glb = max - d;
    
    return (lub|glb) >= 0;
} // isEQ

bool CM::isLT(float& x,
              float& y)
{
    int32_t v = *reinterpret_cast<int32_t *>(&x);
    int32_t w = *reinterpret_cast<int32_t *>(&y);
    int32_t r = NUMERICS_SGN_MASK_32(v & w);
    
    return (v ^ r) < (w ^ r);
} // isLT

bool CM::isLT(double& x,
              double& y)
{
    int64_t v = *reinterpret_cast<int64_t *>(&x);
    int64_t w = *reinterpret_cast<int64_t *>(&y);
    int64_t r = NUMERICS_SGN_MASK_64(v & w);
    
    return (v ^ r) < (w ^ r);
} // isLT

bool  CM::isZero(float& x,
                 float& eps)
{
    int32_t v = *reinterpret_cast<int32_t *>(&x);
    int32_t e = *reinterpret_cast<int32_t *>(&eps);
    
    return (v & 0x7FFFFFFF) <= e;
} // isZero

bool  CM::isZero(double& x,
                 double& eps)
{
    int64_t v = *reinterpret_cast<int64_t *>(&x);
    int64_t e = *reinterpret_cast<int64_t *>(&eps);
    
    return (v & 0x7FFFFFFFFFFFFFFF) <= e;
} // isZero

//------------------------------------------------------------------------------------
//
// Algorithm:
//
//  <http://graphics.stanford.edu/~seander/bithacks.html#SwappingValuesSubAdd>
//
// Traditional integer swapping requires the use of a temporary variable.
// However, using the XOR swap, no temporary variable is required.
//
//------------------------------------------------------------------------------------

#define NUMERICS_SWAP(a, b) (((a) ^ (b)) && ((b) ^= (a) ^= (b), (a) ^= (b)))

void CM::swap(long& x, long& y)
{
    NUMERICS_SWAP(x, y);
} // swap

void swap(size_t& x, size_t& y)
{
    NUMERICS_SWAP(x, y);
} // swap

void CM::swap(int8_t& x, int8_t& y)
{
    NUMERICS_SWAP(x, y);
} // swap

void CM::swap(int16_t& x, int16_t& y)
{
    NUMERICS_SWAP(x, y);
} // swap

void CM::swap(int32_t& x, int32_t& y)
{
    NUMERICS_SWAP(x, y);
} // swap

void CM::swap(int64_t& x, int64_t& y)
{
    NUMERICS_SWAP(x, y);
} // swap

void CM::swap(size_t& x, size_t& y)
{
    NUMERICS_SWAP(x, y);
} // swap

void CM::swap(uint8_t& x, uint8_t& y)
{
    NUMERICS_SWAP(x, y);
} // swap

void CM::swap(uint16_t& x, uint16_t& y)
{
    NUMERICS_SWAP(x, y);
} // swap

void CM::swap(uint32_t& x, uint32_t& y)
{
    NUMERICS_SWAP(x, y);
} // swap

void CM::swap(uint64_t& x, uint64_t& y)
{
    NUMERICS_SWAP(x, y);
} // swap
