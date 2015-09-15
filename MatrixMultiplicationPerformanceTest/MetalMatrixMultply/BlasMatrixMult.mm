/*
 Copyright (C) 2015 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 A functor for performing matrix multipication using BLAS segmm method
 */

#import "BlasMatrixMult.h"

static const size_t kSzFloat = sizeof(float);

typedef float* FloatRef;

@implementation BlasMatrixMult
{
@private
    
    CBLAS_ORDER     _order;             // Specifies row-major or column-major data ordering.
    CBLAS_TRANSPOSE _transA;            // Specifies whether to transpose matrix A.
    CBLAS_TRANSPOSE _transB;            // Specifies whether to transpose matrix B.
    
    uint16_t _m;                        // Number of rows in matrices A and C.
    uint16_t _n;                        // Number of columns in matrix A; number of rows in matrix B.
    uint16_t _k;                        // Number of columns in matrices B and C.
    
    uint16_t _lda;                      // The size of the first dimention of matrix A;
                                        // if you are passing a matrix A[m][n], the value should be m.
    
    uint16_t _ldb;                      // The size of the first dimention of matrix B;
                                        // if you are passing a matrix B[m][n], the value should be m.
    
    uint16_t _ldc;                      // The size of the first dimention of matrix C;
                                        // if you are passing a matrix C[m][n], the value should be m.
    
    float _alpha;                       // Scaling factor for the product of matrices A and B.
    float _beta;                        // Scaling factor for matrix C.
    
    size_t   mnSize;                    // Output matrix size
    FloatRef mpOutput;                  // Output matrix, where C = A x B
    
    dispatch_queue_t  m_DQueue;         // Dispatch queue
}

- (instancetype) init
{
    self = [super init];
    
    if(self)
    {
        static dispatch_once_t token = 0;
        
        dispatch_once(&token, ^{
            m_DQueue = dispatch_queue_create("com.apple.matrixmult.blas.main", 0);
        });
        
        _order  = CblasRowMajor;
        _transA = CblasTrans;
        _transB = CblasNoTrans;
        
        _m = 0;
        _k = 0;
        _n = 0;
        
        _lda = 0;
        _ldb = 0;
        _ldc = 0;
        
        _alpha = 1.0;
        _beta  = 0.0;
        
        mpOutput = nullptr;
        mnSize   = 0;
    } // if
    
    return self;
} // init

- (void) dealloc
{
    if(mpOutput != nullptr)
    {
        std::free(mpOutput);
        
        mpOutput = nullptr;
    } // if
} // dealloc

- (float *) output
{
    return mpOutput;
} // output

// Multiply matrix A with B using Blas sgemm
- (void) multiply:(float*)matA
             with:(float*)matB
{
    if((matA != nullptr) && (matB != nullptr))
    {
        const size_t count = _lda * _ldb;
        const size_t size  = count * kSzFloat;
        
        dispatch_block_t block_alloc =  ^{
            if(mpOutput != nullptr)
            {
                if(mnSize < size)
                {
                    mpOutput = FloatRef(realloc(mpOutput, size));
                } // if
                
                memset(mpOutput, 0x0, mnSize);
            } // if
            else
            {
                mpOutput = FloatRef(calloc(count, kSzFloat));
            } // else
        };
        
        // Allocate a backing store for the elements of the output
        // matrix, if and only if the output matrix size is less
        // than the current output matrix size
        dispatch_async(m_DQueue, block_alloc);
        
        const float * const pMatA = matA;
        const float * const pMatB = matB;
        
        // Block for BLAS matrix multipication
        dispatch_block_t block_sgemm =  ^{
            if(mpOutput != nullptr)
            {
                cblas_sgemm(_order,     // Specifies whether to transpose matrix A
                            _transA,    // Specifies whether to transpose matrix A
                            _transB,    // Specifies whether to transpose matrix B
                            _m,         // Number of rows in matrices A and C
                            _k,         // Number of columns in matrices B and C
                            _n,         // Number of columns in matrix A; number of rows in matrix B
                            _alpha,     // Scaling factor for the product of matrices A and B
                            pMatA,      // Input matrix A
                            _lda,       // The size of the first dimention of matrix A
                            pMatB,      // Input matrix B
                            _ldb,       // The size of the first dimention of matrix B
                            _beta,      // Scaling factor for the output C
                            mpOutput,   // Output matrix C
                            _ldc);      // The size of the first dimension of matrix C
            } // if
        };
        
        // Multiply matrices on a background thread
        dispatch_barrier_sync(m_DQueue, block_sgemm);
        
        mnSize = size;
    } // if
} // multiply

@end
