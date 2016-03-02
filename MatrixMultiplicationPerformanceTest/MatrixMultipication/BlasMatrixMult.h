/*
 Copyright (C) 2015 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 A functor for performing matrix multipication using BLAS sgemm method
 */

#import <Accelerate/Accelerate.h>
#import <Foundation/Foundation.h>

typedef enum CBLAS_ORDER      CBLAS_ORDER;
typedef enum CBLAS_TRANSPOSE  CBLAS_TRANSPOSE;

@interface BlasMatrixMult: NSObject

// Specifies row-major (C) or column-major (Fortran) data ordering.
@property (nonatomic) CBLAS_ORDER order;

// Specifies whether to transpose matrix A.
@property (nonatomic) CBLAS_TRANSPOSE transA;

// Specifies whether to transpose matrix B.
@property (nonatomic) CBLAS_TRANSPOSE transB;

// Number of rows in matrices A and C.
@property (nonatomic) uint16_t m;

// Number of columns in matrix A; number of rows in matrix B.
@property (nonatomic) uint16_t n;

// Number of columns in matrices B and C.
@property (nonatomic) uint16_t k;

// The size of the first dimention of matrix A; if you
// are passing a matrix A[m][n], the value should be m.
@property (nonatomic) uint16_t lda;

// The size of the first dimention of matrix B; if you
// are passing a matrix B[m][n], the value should be m.
@property (nonatomic) uint16_t ldb;

// The size of the first dimention of matrix C; if you
// are passing a matrix C[m][n], the value should be m.
@property (nonatomic) uint16_t ldc;

// Scaling factor for the product of matrices A and B.
@property (nonatomic) float alpha;

// Scaling factor for matrix C.
@property (nonatomic) float beta;

// Matrix C = BLAS(A x B).
@property (nonatomic, readonly) float* output;

// Multiply matrix A with B using Blas sgemm
- (void) multiply:(float*)matA
             with:(float*)matB;

@end
