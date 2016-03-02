/*
 Copyright (C) 2015 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 Utility classes for generating random matrix dimension triplets and randomizing matrix entry
 */

#import <Foundation/Foundation.h>

@interface MatrixRandDims: NSObject

// The number of generated random matrix dimensions
@property (readonly) uint16_t size;

// The number of matrix dimension triplets
@property (nonatomic) uint16_t count;

// Least upper bound of the range of values that may be
// used for uniform integer distribution.
@property (nonatomic) uint16_t max;

// Greatest lower bound of the range of values that may
// be used for uniform integer distribution.
@property (nonatomic) uint16_t min;

// Reset the distribution such that subsequent values
// generated are independent of previously generated
// values
- (void) reset;

// Set the array of a matrix dimension triplets
// to random bounded values
- (void) randomize:(uint16_t *)dimensions;

@end

@interface MatrixRandValues: NSObject

// The number of rows in a matrix
@property (nonatomic) uint16_t m;

// The number of columns in a matrix
@property (nonatomic) uint16_t n;

// Greatest lower bound of the range of values that may
// be used for uniform real distribution.
@property (nonatomic) float min;

// Least upper bound of the range of values that may be
// used for uniform real distribution.
@property (nonatomic) float max;

// Reset the distribution such that subsequent values
// generated are independent of previously generated
// values
- (void) reset;

// Set the elements of a matrix to random bounded values
- (void) randomize:(float *)matrix;

@end
