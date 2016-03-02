/*
 Copyright (C) 2015 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 Utility class for testing the matrix multipication performance of Metal compute and Blas sgemm
 */

#import <Foundation/Foundation.h>

#import "MetalMatrixMult.h"

// Metal compute and Blas sgemm performance tests
@interface MatrixMultPerfTest: NSObject<MetalMatrixMultDelegate>

// Flag for generating random values for the elements
// of input matrices A and B with values using random
// number distribution that produces floating-point
// values according to a uniform real distribution.
// The defualt is set NO.
@property (nonatomic) BOOL randomize;

// Greatest lower bound of the range of values that may
// be used for uniform real distribution.
@property (nonatomic) float min;

// Least upper bound of the range of values that may be
// used for uniform real distribution.
@property (nonatomic) float max;

// Number of cycles per compute
@property (nonatomic) uint32_t loops;

// Number of rows in matrices A and C.
@property (nonatomic) uint16_t m;

// Number of columns in matrix A; number of rows in matrix B.
@property (nonatomic) uint16_t n;

// Number of columns in matrices B and C.
@property (nonatomic) uint16_t k;

// Output matrix (padded) C row count
@property (nonatomic, readonly) uint16_t M;

// Output matrix (padded) C column count
@property (nonatomic, readonly) uint16_t K;

// Averaged length for the resultant matrix elements,
// where the 2-norm for the length is computed from the
// vector space formed by the elements of the matrices
// C' = Metal(A x B) and C = BLAS(A x B)
@property (nonatomic, readonly) double length;

// For matrix A use i=0, and for matrix B use i=1
- (float *) input:(uint32_t)idx;

// Output matrix C = A x B. For results from Metal compute
// use i=0, and for BLAS use i=1.  Defaults to Metal results.
- (float *) output:(uint32_t)idx;

// Matrix multipication compute time performance.
// For results from Metal compute use i=0, and
// for BLAS use i=1. Defaults to Metal results.
- (double) time:(uint32_t)idx;

// Matrix multipication compute gflops performance.
// For results from Metal compute use i=0, and
// for BLAS use i=1. Defaults to Metal results.
- (double) gflops:(uint32_t)idx;

// Allocate new buffers for input matrices A and B,
// as well as the output matrix C, provided there is
// change their sizes and as determined by their
// dimensions
- (BOOL) newBuffers;

// Generate some random values for matrices A = [m x n]
// and B = [n x k] and run matrix multipication tests
// using Metal compute and Blas sgemm
- (void) dispatch;

@end
