/*
 Copyright (C) 2015 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 Utility class for testing the matrix multipication performance of Metal compute and Blas sgemm
 */

#import "MachTimer.h"
#import "MatrixRandomizer.h"
#import "BlasMatrixMult.h"
#import "MetalMatrixMult.h"
#import "MatrixMultPerfTest.h"

// Floating-point sizes
static const uint32_t kSzFloat = sizeof(float);

// Default number of test iterations
static const uint32_t kCntIter = 100;

@implementation MatrixMultPerfTest
{
@private
    uint32_t _loops;                    // Number of loops per compute
    uint16_t _m;                        // Number of rows in matrices A and C
    uint16_t _n;                        // Number of columns in matrix A; number of rows in matrix B
    uint16_t _k;                        // Number of columns in matrices B and C
    uint16_t _M;                        // Output matrix (padded) C row count
    uint16_t _K;                        // Output matrix (padded) C column count
    
    float   _min;                       // Greatest lower bound of random numbers
    float   _max;                       // Least upper bound of random numbers
    
    BOOL _randomize;                    // Flag for generating random values for the elements
                                        // of input matrices A and B with values using random
                                        // number distribution that produces floating-point
                                        // values according to a uniform real distribution.
                                        // The defualt is set NO.
    
    double  mnCycles;                   // Total cycles for tests
    
    double  m_Time[2];                  // Compute time performace
    double  m_GFlops[2];                // GFlops performance
    
    double  _length;                    // Averaged length for the resultant matrix elements,
                                        // where the 2-norm for the length is computed from the
                                        // vector space formed by the elements of the matrices
                                        // C' = Metal(A x B) and C = BLAS(A x B)
    
    MachTimer*        mpTimer;          // Mach hi-res timer
    MetalMatrixMult*  mpMetal;          // Metal compute matrix multipication object
    BlasMatrixMult*   mpBLAS;           // Blas sgemm matrix multipication object
    MatrixRandValues* mpValues;         // For generating random values for matrix elements
    
    dispatch_queue_t m_DQueue[2];       // Dispatch queue
}

- (instancetype) init
{
    self = [super init];
    
    if(self)
    {
        static dispatch_once_t token = 0;
        
        dispatch_once(&token, ^{
            // Instantiate a uniform real distribution
            // object for generating  random values
            // for matrix elements
            mpValues = [MatrixRandValues new];
            
            if(!mpValues)
            {
                NSLog(@">> WARNING: Failed creating a randomizer object for matrix dimensions!");
            } // if
            
            // The default is to generate random values for the
            // elements of the input matrices A and B.
            _randomize = mpValues != nil;
            
            // Instantiate a Mach hi-res timer object
            mpTimer = [MachTimer new];
            
            if(!mpTimer)
            {
                NSLog(@">> ERROR: Failed creating a Mach hi-res timer object!");
                
                assert(0);
            } // if
            
            // Initialize a serial dispatch queues
            m_DQueue[0] = dispatch_queue_create("com.apple.matrixmult.perftest.main", 0);
            m_DQueue[1] = dispatch_queue_create("com.apple.matrixmult.perftest.rsrc", 0);
        });
        
        // Instantiate a Metal matrix multipication object
        mpMetal = [MetalMatrixMult new];
        
        if(!mpMetal)
        {
            NSLog(@">> ERROR: Failed creating a Metal matrix multipication object!");
            
            assert(0);
        } // if
        
        // Set to invoke, if needed, the concrete implementation
        // of the delegate to initialize the elements of the input
        // matrices A and B with random values using the uniform
        // real distribution
        mpMetal.delegate = self;
        
        // Instantiate a Blas matrix multipication functor
        mpBLAS = [BlasMatrixMult new];
        
        if(!mpBLAS)
        {
            NSLog(@">> ERROR: Failed creating a Blas sgemm multipication object!");
            
            assert(0);
        } // if
        
        // Initialize the matrix dimensions
        _m = 0;
        _n = 0;
        _k = 0;
        _M = 0;
        _K = 0;
        
        // Initialize statistics
        _length = 0.0;
        
        // Set the default number of loops
        _loops = kCntIter;
        
        // Set the numbers of compute iteration a timer
        // should consider when computing results
        mpTimer.loops = _loops;
        
        // Performance data initializations
        m_Time[0]   = 0.0;
        m_Time[1]   = 0.0;
        m_GFlops[0] = 0.0;
        m_GFlops[1] = 0.0;
        
        // Default random number bounds
        _min = -2.5;
        _max =  2.5;
    } // if
    
    return self;
} // init

// For matrix A use i=0, and for matrix B use i=1
- (float *) input:(uint32_t)idx
{
    return [mpMetal input:idx];
} // input

// Output matrix C = A x B. For results from Metal compute
// use i=0, and for BLAS use i=1. Defaults to Metal results.
- (float *) output:(uint32_t)idx
{
    return (idx) ? mpBLAS.output : mpMetal.output;
} // output

// Matrix multipication compute time performance.
// For results from Metal compute use i=0, and
// for BLAS use i=1. Defaults to Metal results.
- (double) time:(uint32_t)idx
{
    return (idx) ? m_Time[1] : m_Time[0];
} // time

// Matrix multipication compute gflops performance.
// For results from Metal compute use i=0, and
// for BLAS use i=1. Defaults to Metal results.
- (double) gflops:(uint32_t)idx
{
    return (idx) ? m_GFlops[1] : m_GFlops[0];
} // gflops

// Metal compute multipication performance
- (void) _multiplyMetal
{
    // Create a command buffers, encode and set buffer
    // for all the matrices
    if([mpMetal encode])
    {
        // Set the value for the maximum number of iterations
        const uint32_t iMax = _loops;
        
        // Block for Metal matrix performance test
        dispatch_block_t block =  ^{
            uint32_t i;
            
            [mpTimer start];
            {
                for(i = 0; i < iMax; ++i)
                {
                    [mpMetal dispatch];
                } // for
                
                [mpMetal finish];
            }
            [mpTimer stop];
            
            // Performance data for metal matrix multiply
            m_Time[0]   = mpTimer.elapsed;
            m_GFlops[0] = mpTimer.gflops;
        };
        
        // Metal matrix multipication compute performance
        dispatch_async(m_DQueue[0], block);
    } // if
} // _multiplyMetal

// Blas sgemm performance
- (void) _multiplyBlas
{
    __block float* pMatrixA = nullptr;
    __block float* pMatrixB = nullptr;
    
    // Block for initializing BLAS object
    dispatch_block_t block_blas_init = ^{
        // Setup properties for multiplying two matrices
        // using CBLAS sgemm method
        mpBLAS.m = mpMetal.m;
        mpBLAS.n = mpMetal.n;
        mpBLAS.k = mpMetal.k;
        
        mpBLAS.lda = mpMetal.M;
        mpBLAS.ldb = mpMetal.K;
        mpBLAS.ldc = mpMetal.K;
        
        // Get the the matrices A and B from Metal buffers
        pMatrixA = [mpMetal input:0];
        pMatrixB = [mpMetal input:1];
    };
    
    // Block until initializations are complete
    dispatch_barrier_sync(m_DQueue[0], block_blas_init );
    
    // Set the value for the maximum number of iterations
    const uint32_t iMax = _loops;
    
    // Block for BLAS matrix multipication performance test
    dispatch_block_t block_blas_test = ^{
        uint32_t i;
        
        [mpTimer start];
        {
            for(i = 0; i < iMax; ++i)
            {
                [mpBLAS multiply:pMatrixA
                            with:pMatrixB];
            } // for
        }
        [mpTimer stop];
        
        // Performance data for Blas sgemm matrix multiply
        m_Time[1]   = mpTimer.elapsed;
        m_GFlops[1] = mpTimer.gflops;
    };
    
    // CBLAS sgemm compute performance using matrices
    // A and B acquired from Metal buffers and populated
    // with random values
    dispatch_async(m_DQueue[0], block_blas_test );
} // _multiplyBlas

// Averaged length for the resultant matrix elements,
// where the 2-norm for the length is computed from the
// vector space formed by the elements of the matrices
// C' = Metal(A x B) and C = BLAS(A x B)
- (void) _avgLength
{
    __block float* res = nullptr;
    __block float* ref = nullptr;
    
    __block uint16_t rows  = 0;
    __block uint16_t cols  = 0;
    __block uint16_t pcols = 0;
    
    // Block for initializations
    dispatch_block_t block_inits = ^{
        res = mpMetal.output;
        ref = mpBLAS.output;
        
        rows  = mpMetal.m;
        cols  = mpMetal.k;
        pcols = mpMetal.K;
    };
    
    // Block until initilizations are complete
    dispatch_barrier_sync(m_DQueue[0], block_inits );
    
    // Block for compute the average length
    dispatch_block_t block_compute = ^{
        double diff = 0.0;
        double sum  = 0.0;
        
        uint32_t i, j, m;
        
        for(i = 0; i < rows; ++i)
        {
            for(j = 0; j < cols; ++j)
            {
                m = i * pcols + j;
                
                diff  = ref[m] - res[m];
                sum  += (diff * diff);
            } // for
        } // for
        
        const double count = double(rows) * double(cols);
        
        // The average length
        _length = sqrt(sum) / count;
    };
    
    // Compute the Euclidean length of the vector space
    // formed by the difference in the elments of matrices
    // C' = Metal(A xB) and C = BLAS(A x B)
    dispatch_async(m_DQueue[0], block_compute );
} // _avgLength

// Compute the test results
- (void) _calcResults
{
    // Averaged length for the matrix elements given by
    // C' = Metal(A x B) and C = BLAS(A x B)
    [self _avgLength];
    
    // Block for completing the computation
    dispatch_block_t block = ^{
        // Theoretical GFlops maximum achieved
        mnCycles = double(mpMetal.m) * double(mpMetal.n) * double(mpMetal.k);
        
        m_GFlops[0] *= mnCycles;
        m_GFlops[1] *= mnCycles;
    };
    
    // Complete the computation
    dispatch_barrier_sync(m_DQueue[0], block);
} // _calcResults

// Determine Metal compute and Blas sgemm performance data
- (void) dispatch
{
    // Set the number of loops for the timer
    mpTimer.loops = _loops;
    
    // Metal compute matrix multipication
    [self _multiplyMetal];
    
    // Blas sgemm matrix multipication
    [self _multiplyBlas];
    
    // Compute the test results
    [self _calcResults];
} // dispatch

// Allocate new buffers for input matrices A and B,
// as well as the output matrix C, provided there is
// change their sizes and as determined by their
// dimensions
- (BOOL) newBuffers
{
    const uint16_t m = _m;
    const uint16_t n = _n;
    const uint16_t k = _k;
    
    // Set the row count of matrix A
    mpMetal.m = m;
    
    // Set the column count of matrix A
    // and row count of matrix B
    mpMetal.n = n;
    
    // Set the column count of matrix B
    mpMetal.k = k;
    
    // Get the output matrix (padded) C row count
    _M = mpMetal.M;
    
    // Get the output matrix (padded) C column count
    _K = mpMetal.K;
    
    // Generate new buffers for input matrices A and B,
    // and the output matrix C.
    return [mpMetal newBuffers];
} // newBuffers

// Concrete implementation of the Metal matrix multipication
// delegate for randomizing or initializing of the elements
// of the input matrices.
- (void) initialize:(float *)data
               rows:(const uint16_t)rows
            columns:(const uint16_t)columns
              index:(const uint32_t)index
{
    if(data != nullptr)
    {
        float* pOutData = data;
        
        if(_randomize)
        {
            const float  min = _min;
            const float  max = _max;
            
            // Block for setting matrix element randomizer properties
            dispatch_block_t block = ^{
                mpValues.m   = rows;
                mpValues.n   = columns;
                mpValues.min = min;
                mpValues.max = max;
                
                [mpValues randomize:pOutData];
            };
            
            // Randomize matrix elements
            dispatch_sync(m_DQueue[1], block);
        } // if
        else
        {
            const size_t size = rows * columns * kSzFloat;
            
            // Block for clearing matrix elements
            dispatch_block_t block = ^{
                memset(pOutData, 0x0, size);
            };
            
            // Clear matrix elements
            dispatch_sync(m_DQueue[1], block);
        } // else
    } // if
} // initialize

@end
