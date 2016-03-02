/*
 Copyright (C) 2015 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 Utility class for performing matrix multipication using a Metal compute kernel
 */

#import <Metal/Metal.h>

// Forward decelaration for the matrix multipication using
// Metal compute
@class MetalMatrixMult;

// Metal matrix multipication delegate for initializing
// or randomizing data.
@protocol MetalMatrixMultDelegate <NSObject>

@optional
// Implement this method to initialize the elements of
// matrices A and B. In the concrete implementation of
// this delegate use index=0 to initialize matrix A,
// and use index=1 to initialize matrix B.
- (void) initialize:(float *)data
               rows:(const uint16_t)rows
            columns:(const uint16_t)columns
              index:(const uint32_t)index;

@end

// Metal matgrix multipication using a compute kernel
@interface MetalMatrixMult: NSObject

// Delegate for initializing data
@property (nonatomic, assign) id<MetalMatrixMultDelegate> delegate;

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

// Output matrix C = A x B
@property (nonatomic, readonly) float* output;

// For matrix A use i=0, and for matrix B use i=1
- (float *) input:(uint32_t)idx;

// Allocate new buffers for input matrices A and B,
// as well as the output matrix C, provided there is
// change in their sizes and as determined by changes
// in their dimensions
- (BOOL) newBuffers;

// Create a command buffer, encode and set buffers
- (BOOL) encode;

// Dispatch the compute kernel for matrix multipication
- (void) dispatch;

// Wait until the matrix computation is complete
- (void) finish;

@end
