/*
 Copyright (C) 2015 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 Utility classes for generating random matrix dimension triplets and randomizing matrix entry
 */

#import <random>

#import "MatrixRandomizer.h"

#pragma mark -
#pragma mark Matrix Random Dimensions

@implementation MatrixRandDims
{
@private
    uint16_t _count;        // The number of matrix dimension triplets
    uint16_t _size;         // The number of generated random matrix dimensions
    uint16_t _min;          // Greatest lower bound for uniform integer distribution
    uint16_t _max;          // Least upper bound for uniform integer distribution
    
    BOOL mbUpdate;          // Flag for updating the random number generator
    
    // Dispatch queue and semaphore
    dispatch_semaphore_t m_DSemaphore;
    dispatch_queue_t     m_DQueue;
    
    // Uniform discrete integer distribution:
    //
    // <http://www.cplusplus.com/reference/random/uniform_int_distribution/>
    //
    // The valid type names here are uint8_t, uint16_t, uint32_t, uint64_t,
    // or size_t.
    std::random_device                       m_Device;
    std::default_random_engine               m_Generator;
    std::uniform_int_distribution<uint16_t>  m_Distribution;
}

- (instancetype) init
{
    self = [super init];
    
    if(self)
    {
        static dispatch_once_t token = 0;
        
        dispatch_once(&token, ^{
            m_DSemaphore = dispatch_semaphore_create(0);
            m_DQueue     = dispatch_queue_create("com.apple.matrixmult.matrixranddims.main", 0);
        });
        
        // Initialize the uniform integer distribution for
        // random number generation
        m_Generator = std::default_random_engine(m_Device());
        
        // Initialize dimensions' properties
        _count = 20;
        _size  = 3 * _count;
        
        // Default bounds for the uniform integer distribution
        _min = 256;
        _max = 2048;
        
        // Update the random number generator if and only if
        // the bounds have changed
        mbUpdate = YES;
    } // if
    
    return self;
} // init

- (void) dealloc
{
    // Release the semaphore.
    dispatch_semaphore_signal(m_DSemaphore);
} // dealloc

// Set the least upper bound
- (void) setMax:(uint16_t)max
{
    mbUpdate = mbUpdate || (max != _max);
    
    _max = max;
} // setMax

// Set the greatest lower bound
- (void) setMin:(uint16_t)min
{
    mbUpdate = mbUpdate || (min != _min);
    
    _min = min;
} // setMin

// Set the number of dimension triplets
- (void) setCount:(uint16_t)count
{
    _count = count;
    _size  = 3 * _count;
} // setCount

// Reset the distribution such that subsequent values generated
// are independent of previously generated values
- (void) reset
{
    m_Distribution.reset();
} // reset

// Set the array of a matrix dimension triplets
// to random bounded values
- (void) randomize:(uint16_t *)dimensions
{
    if(dimensions != nullptr)
    {
        const uint32_t iMax = _size;
        const uint16_t min  = _min;
        const uint16_t max  = _max;
        
        if(mbUpdate)
        {
            dispatch_async(m_DQueue, ^{
                m_Distribution = std::uniform_int_distribution<uint16_t>(min, max);
                
                dispatch_semaphore_signal(m_DSemaphore);
            });
            
            mbUpdate = NO;
            
            dispatch_semaphore_wait(m_DSemaphore, DISPATCH_TIME_FOREVER);
        } // if
        
        __block uint16_t* pDimensions = dimensions;
        
        dispatch_apply(iMax, m_DQueue, ^(size_t i) {
            // The matrix dimension triplet start index
            const size_t j = 3 * i;
            
            // Set row count of matrix A to some random dimension
            pDimensions[j] = m_Distribution(m_Generator);
            
            // Set the column count of matrix A and row count
            // of matrix B to some random dimension
            pDimensions[j+1] = m_Distribution(m_Generator);
            
            // Set the column count of matrix B to some random dimension
            pDimensions[j+2] = m_Distribution(m_Generator);
        });
    } // if
} // randomize

@end

#pragma mark -
#pragma mark Matrix Random Values

@implementation MatrixRandValues
{
@private
    uint16_t _m;            // Number of rows in a matrix
    uint16_t _n;            // Number of columns in a matrix
    float    _min;          // Greatest lower bound for uniform integer distribution
    float    _max;          // Least upper bound for uniform integer distribution
    
    BOOL mbUpdate;          // Flag for updating the random number generator
    
    // Dispatch queue and semaphore
    dispatch_semaphore_t m_DSemaphore;
    dispatch_queue_t     m_DQueue;
    
    // Uniform discrete real distribution:
    //
    // <http://www.cplusplus.com/reference/random/uniform_real_distribution/>
    //
    // The valid type names here are float, double, or long double.
    std::random_device                     m_Device;
    std::default_random_engine             m_Generator;
    std::uniform_real_distribution<float>  m_Distribution;
}

- (instancetype) init
{
    self = [super init];
    
    if(self)
    {
        static dispatch_once_t token = 0;
        
        dispatch_once(&token, ^{
            m_DSemaphore = dispatch_semaphore_create(0);
            m_DQueue     = dispatch_queue_create("com.apple.matrixmult.matrixrandvalues.main", 0);
        });
        
        // Initialize the uniform integer distribution for
        // random number generation
        m_Generator = std::default_random_engine(m_Device());
        
        // Initialize matrix dimensions
        _m = 0;
        _n = 0;
        
        // Default bounds for the uniform integer distribution
        _min = -2.5;
        _max =  2.5;
        
        // Update the random number generator if and only if
        // the bounds have changed
        mbUpdate = YES;
    } // if
    
    return self;
} // init

- (void) dealloc
{
    // Release the semaphore.
    dispatch_semaphore_signal(m_DSemaphore);
} // dealloc

// Set the least upper bound
- (void) setMax:(float)max
{
    mbUpdate = mbUpdate || (max != _max);
    
    _max = max;
} // setMax

// Set the greatest lower bound
- (void) setMin:(float)min
{
    mbUpdate = mbUpdate || (min != _min);
    
    _min = min;
} // setMin

// Reset the distribution such that subsequent values generated
// are independent of previously generated values
- (void) reset
{
    m_Distribution.reset();
} // reset

// Set the elements of a matrix to random bounded values
- (void) randomize:(float *)matrix
{
    if(matrix != nullptr)
    {
        const uint32_t iMax = _m * _n;
        
        if(iMax)
        {
            const float min = _min;
            const float max = _max;
            
            // Update the uniform real distribution if the bounds have changed
            if(mbUpdate)
            {
                // Yield time
                dispatch_async(m_DQueue, ^{
                    m_Distribution = std::uniform_real_distribution<float>(min, max);
                    
                    dispatch_semaphore_signal(m_DSemaphore);
                });
                
                mbUpdate = NO;
                
                // Wait for the block to complete
                dispatch_semaphore_wait(m_DSemaphore, DISPATCH_TIME_FOREVER);
            } // if
            
            __block float* pMatrix = matrix;
            
            // Populate the input matrix with random values
            dispatch_apply(iMax, m_DQueue, ^(size_t i) {
                pMatrix[i] = m_Distribution(m_Generator);
            });
        } // if
    } // if
} // randomize

@end
