/*
 Copyright (C) 2015 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 Utility class for generating two random matrices for multipication using Metal compute
 */

#import <cstdlib>

#import "MatrixRandomizer.h"
#import "MatrixMultPerfTest.h"
#import "MatrixMultPTScheduler.h"

static const uint32_t kSzUInt16   = sizeof(uint16_t);
static const uint32_t kCntIter    = 100;
static const uint32_t kCntTextMax = 20;

static const uint8_t kInputMatrixA = uint8_t('a');
static const uint8_t kInputMatrixB = uint8_t('b');

typedef uint16_t* UInt16Ref;

// Keys for the Performance dictionary                          // For values
NSString* kMatrixMultTestID      = @"Matrix_Mult_Test_Id";      // Unsigned Short 32
NSString* kMatrixARowCount       = @"Matrix_A_Row_Count";       // Unsigned Short 16
NSString* kMatrixAColCount       = @"Matrix_A_Col_Count";       // Unsigned Short 16
NSString* kMatrixBRowCount       = @"Matrix_B_Row_Count";       // Unsigned Short 16
NSString* kMatrixBColCount       = @"Matrix_B_Col_Count";       // Unsigned Short 16
NSString* kMatrixCPaddRowCount   = @"Matrix_C_Padd_Row_Count";  // Unsigned Short 16
NSString* kMatrixCPaddColCount   = @"Matrix_C_Padd_Col_Count";  // Unsigned Short 16
NSString* kMatrixMultGFlopsBlas  = @"Matrix_Mult_GFlops_Blas";  // Double
NSString* kMatrixMultGFlopsMetal = @"Matrix_Mult_GFlops_Metal"; // Double
NSString* kMatrixMultTimeBlas    = @"Matrix_Mult_Time_Blas";    // Double
NSString* kMatrixMultTimeMetal   = @"Matrix_Mult_Time_Metal";   // Double
NSString* kMatrixMultLength      = @"Matrix_Mult_Length";       // Double

// Keys for the performnace log dictionary
NSString* kMatrixLogTestID      = @"Matrix_Log_Test_Id";        // Unsigned Short 32
NSString* kMatrixLogDimensions  = @"Matrix_Log_Dimensions";     // String
NSString* kMatrixLogPerformance = @"Matrix_Log_Performance";    // String

// Notifications
NSString* kMatrixNotificationIsReadyPerfData = @"Matrix_Notification_Is_Ready_Perf_Data";
NSString* kMatrixNotificationIsReadyLogData  = @"Matrix_Notification_Is_Ready_Log_Data";
NSString* kMatrixNotificationIsDoneTests     = @"Matrix_Notification_Is_Done_Tests";

@implementation MatrixMultPTScheduler
{
@private
    BOOL _print;                            // Log the test results
    BOOL _isRandomized;                     // Matrix elements have random values
    
    uint16_t _min;                          // Greatest lower bound of the range of values that may
                                            // be used for uniform integer distribution.
    
    uint16_t _max;                          // Least upper bound of the range of values that may be
                                            // used for uniform integer distribution.
    
    uint32_t         _loops;                // Number of loops per test
    uint32_t         _tests;                // Number of tests
    NSMutableArray*  _data;                 // Performance data.  This is an array of dictionaries.
    NSMutableArray*  _logs;                 // Performance log. This is an array of dictionaries.
    
    MatrixRandDims*      mpDims;            // For generating random set of dimension triplets
    MatrixMultPerfTest*  mpTest;            // Matrix performance test object
    
    uint32_t  mnSize;                       // Size (in bytes) of the array of dimension triplets
    uint32_t  mnCount;                      // The number of dimension triplets
    uint16_t* mpList;                       // Set of random dimensions for matrix multipication tests
    
    dispatch_group_t  m_DGroup;             // Dispatch group
    dispatch_queue_t  m_DQueue[3];          // Dispatch queues
}

- (instancetype) init
{
    self = [super init];
    
    if(self)
    {
        static dispatch_once_t token = 0;
        
        dispatch_once(&token, ^{
            // Initialize mutable arrays
            _data = [NSMutableArray new];
            _logs = [NSMutableArray new];
            
            // Initialize the serial dispatch queues
            m_DQueue[0] = dispatch_queue_create("com.apple.matrixmult.scheduler.buffers", 0);
            m_DQueue[1] = dispatch_queue_create("com.apple.matrixmult.scheduler.inits", 0);
            m_DQueue[2] = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
            
            // Create a dispatch group
            m_DGroup = dispatch_group_create();
            
            // Allocate a persistent test object
            mpTest = [MatrixMultPerfTest new];
            
            if(!mpTest)
            {
                NSLog(@">> ERROR: Failed creating a matrix multipication test object!");
                
                assert(0);
            } // if
        });
        
        // If the delegate for initializing input matrices A and B
        // is not implemented, then generate random values for the
        // elements of input matrices A and B.
        mpTest.randomize = ![_delegate respondsToSelector:@selector(matrix:rows:columns:data:)];
        
        // Set the flag
        _isRandomized = mpTest.randomize;
        
        // Initialize properties
        _tests = kCntTextMax;
        _loops = kCntIter;
        _min   = 256;
        _max   = 2048;
        _print = NO;
        
        // Initialize private instance variables
        mpDims  = nil;
        mnCount = 0;
        mnSize  = 0;
        mpList  = nullptr;
    } // if
    
    return self;
} // init

- (void) dealloc
{
    if(mpList != nullptr)
    {
        std::free(mpList);
        
        mpList = nullptr;
    } // if
} // dealloc

// Get the the base address to the dimensions integer array
- (uint16_t *) dims
{
    return mpList;
} // dims

// Allocate a backing store for dimensions triplets if and
// only if the list size is greater than the current list size
- (BOOL) _newList
{
    const uint32_t count = 3 * _tests;
    const uint32_t size  = count * kSzUInt16;
    
    // Matrix dimension triplets memory initialization
    if(mpList != nullptr)
    {
        if(mnSize < size)
        {
            mpList = UInt16Ref(realloc(mpList, size));
        } // if
        
        memset(mpList, 0x0, mnSize);
    } // if
    else
    {
        mpList = UInt16Ref(calloc(count, kSzUInt16));
    } // else
    
    BOOL bSuccess = mpList != nullptr;
    
    if(bSuccess)
    {
        mnCount = count;
        mnSize  = size;
    } // if
    else
    {
        NSLog(@">> ERROR: Failed creating a backing-store for the dimension triplets!");
    } // else
    
    return bSuccess;
} // _newList

// Populate the list of dimension triplets
- (BOOL) _acquireDims
{
    BOOL bSuccess = [self _newList];
    
    if(bSuccess)
    {
        if([_delegate respondsToSelector:@selector(dimensions:count:)])
        {
            // Set dimension triplets using a concrete implementation
            // of the delegate
            [_delegate dimensions:mpList
                            count:mnCount];
        } // if
        else
        {
            // Instantiate a uniform integer distribution
            // object for matrix dimension triplets
            if(!mpDims)
            {
                mpDims = [MatrixRandDims new];
            } // if
            
            // Set the bounds for the uniform integer distribution
            // and generate dimension triplets
            if(mpDims)
            {
                mpDims.min = _min;
                mpDims.max = _max;
                
                [mpDims randomize:mpList];
            } // if
        } // if
    } // if
    
    return bSuccess;
} // _acquireDims

// Add the performance log strings to a mutable array
- (void) _addLogs:(const uint32_t)tid
{
    const uint32_t tidx = tid + 1;
    
    NSString* pTextDims = [NSString stringWithFormat:@">> [%d] Matrix Dimensions: A = [%d x %d], B = [%d x %d], C = [%d x %d], lda = %d, ldb = %d, ldc = %d",
                           tidx,
                           mpTest.m,
                           mpTest.n,
                           mpTest.n,
                           mpTest.k,
                           mpTest.m,
                           mpTest.k,
                           mpTest.M,
                           mpTest.K,
                           mpTest.K];
    
    if(pTextDims)
    {
        NSString* pTextPerf = [NSString stringWithFormat:@">> [%d] Accelerate %f gflops/sec, Metal %f gflops/sec, Accelerate %f millisec, Metal %f millisec, Diff %e",
                               tidx,
                               [mpTest gflops:1],
                               [mpTest gflops:0],
                               [mpTest time:1],
                               [mpTest time:0],
                               mpTest.length];
        
        if(pTextPerf)
        {
            NSArray* pObjects = @[ @(tidx), pTextDims, pTextPerf ];
            NSArray* pKeys    = @[ kMatrixLogTestID, kMatrixLogDimensions, kMatrixLogPerformance ];
            
            NSDictionary* pDictionary = [NSDictionary dictionaryWithObjects:pObjects
                                                                    forKeys:pKeys];
            
            if(pDictionary)
            {
                // Append dictionary to the performance logs output array
                [_logs addObject:pDictionary];
                
                [[NSNotificationCenter defaultCenter] postNotificationName:kMatrixNotificationIsReadyLogData
                                                                    object:nil
                                                                  userInfo:_logs[tid]];
            } // if
            
            if(_print)
            {
                NSLog(@"%@\n%@\n\n", pTextDims, pTextPerf);
            } // if
        } // if
    } // if
} // _addLogs

// Add the performance data to a mutable array and then post-porcess
// using a concrete implementation of the delegate
- (void) _addTest:(const uint32_t)tid
{
    NSArray* pObjects = @[ @(tid),
                           @(mpTest.m),
                           @(mpTest.n),
                           @(mpTest.n),
                           @(mpTest.k),
                           @(mpTest.M),
                           @(mpTest.K),
                           @([mpTest gflops:0]),
                           @([mpTest gflops:1]),
                           @([mpTest time:0]),
                           @([mpTest time:1]),
                           @(mpTest.length) ];
    
    NSArray* pKeys = @[ kMatrixMultTestID,
                        kMatrixARowCount,
                        kMatrixAColCount,
                        kMatrixBRowCount,
                        kMatrixBColCount,
                        kMatrixCPaddRowCount,
                        kMatrixCPaddColCount,
                        kMatrixMultGFlopsMetal,
                        kMatrixMultGFlopsBlas,
                        kMatrixMultTimeMetal,
                        kMatrixMultTimeBlas,
                        kMatrixMultLength ];
    
    NSDictionary* pDictionary = [NSDictionary dictionaryWithObjects:pObjects
                                                            forKeys:pKeys];
    
    if(pDictionary)
    {
        // Append dictionary to the performance data output array
        [_data addObject:pDictionary];
        
        [[NSNotificationCenter defaultCenter] postNotificationName:kMatrixNotificationIsReadyPerfData
                                                            object:nil
                                                          userInfo:_data[tid]];
    } // if
} // _addTest

// Create matrix buffers with the dimension triplets
- (void) _newBuffers:(const uint32_t)tid
{
    // Block for initializing Metal input and output matrix buffers
    dispatch_block_t block =  ^{
        // The matrix dimension triplet start index
        const uint32_t j = 3 * tid;
        
        // Get dimension triplets at an index
        const uint16_t * const pList = &mpList[j];
        
        // Set the matrix dimension triplets for performance tests
        mpTest.m = pList[0];
        mpTest.n = pList[1];
        mpTest.k = pList[2];
        
        // Generate new buffers for the input matrices A and B,
        // and run the matrix multipication performance tests
        [mpTest newBuffers];
    };
    
    // Initialize input and output matrices
    dispatch_sync(m_DQueue[0], block);
} // _setDims

// Initialize an input matrix using a dispatch group
- (void) _initInput:(const uint8_t)type
               rows:(const uint16_t)rows
            columns:(const uint16_t)columns
               data:(float *)data
{
    // Block for initializing matrices
    dispatch_block_t block =  ^{
        // Use delegate's concrete implemetation to initialize
        // an imput matrix
        [_delegate matrix:type
                     rows:rows
                  columns:columns
                     data:data];
        
        // leave the dispatch group for matrix initialization
        dispatch_group_leave(m_DGroup);
    };
    
    // Enter the dispatch group for matrix initialization
    dispatch_group_enter(m_DGroup);
    
    // Use the delegate to initialize the input matrix A
    dispatch_group_async(m_DGroup, m_DQueue[1], block);
} // _initInputs

// If optional input initializer delegate for the data sources
// of matrices A and B was implemented, then set the elements
// of the matrices A and B using the concerete implementation
// of this delegate.
- (void) _initInputs
{
    if(!_isRandomized)
    {
        // Dimension triplets for the input matrices
        const uint16_t M = mpTest.m;
        const uint16_t n = mpTest.n;
        const uint16_t K = mpTest.k;
        
        // Data for the input matrices A and B
        float* pMatrixA = [mpTest input:0];
        float* pMatrixB = [mpTest input:1];
        
        // Use the delegate to initialize the input matrix A
        [self _initInput:kInputMatrixA
                    rows:M
                 columns:n
                    data:pMatrixA];
        
        // Initialize the input matrix B
        [self _initInput:kInputMatrixB
                    rows:n
                 columns:K
                    data:pMatrixB];
        
        // Wait until the group is finished
        dispatch_group_wait(m_DGroup, DISPATCH_TIME_FOREVER);
    } // if
} // _initInputs

// Instantiate a new test object, set the dimension matrix
// triplets, run the test, and store the performance data
- (void) _displatchTest:(const uint32_t)tid
{
    // Set the dimension triplets for the test
    [self _newBuffers:tid];
    
    // Initialize the input matrices if and only if
    // there are concrete implementations of their
    // delegate
    [self _initInputs];
    
    // Dispatch performance test using the dimension triplets
    [mpTest dispatch];
} // _displatchTest

- (void) dispatch
{
    // Acquire matrix dimension triplets list
    if([self _acquireDims])
    {
        // Set the test object to loop over a number of times
        // over the same set of matrices in a Blas and Metal
        // matrix multipications
        mpTest.loops = _loops;
        
        // Block for dispatching perfomance tests
        dispatch_block_t block_tests = ^{
            // Test id
            uint32_t tid;
            
            // Run a group of tests
            for(tid = 0; tid < _tests; ++tid)
            {
                // Run the test with id
                [self _displatchTest:tid];
                
                // Add the performance data for the test to
                // the data array
                [self _addTest:tid];
                
                // Add the performance data for the test to
                // the logs array
                [self _addLogs:tid];
            } // for
            
            // Post performance data notification
            [[NSNotificationCenter defaultCenter] postNotificationName:kMatrixNotificationIsDoneTests
                                                                object:nil
                                                              userInfo:nil];
        };
        
        // Dispatch all perfomance tests
        dispatch_async(m_DQueue[2], block_tests);
    } // if
} // dispatch

@end
