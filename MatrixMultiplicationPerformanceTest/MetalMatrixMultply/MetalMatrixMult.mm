/*
 Copyright (C) 2015 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 Utility class for performing matrix multipication using a Metal compute kernel
 */

#import <Foundation/Foundation.h>

#import "MetalMatrixBuffers.h"
#import "MetalMatrixMult.h"

enum MetalMatrixBufferTypes:uint32_t
{
     eMTLMatBufferInA = 0,
     eMTLMatBufferInB,
     eMTLMatBufferOutA,
     eMTLMatBufferOutB,
     eMTLMatBufferMax
};

typedef enum MetalMatrixBufferTypes MetalMatrixBufferTypes;

struct MetalMatrixDim
{
     uint16_t m, k, n, pbytes, qbytes;
};

typedef struct MetalMatrixDim   MetalMatrixDim;
typedef        MetalMatrixDim*  MetalMatrixDimRef;

typedef float* FloatRef;

static const uint32_t kSzMTLFloat  = sizeof(float);
static const uint32_t kSzMTLMatDim = sizeof(MetalMatrixDim);

// Utility class encapsulating Metal matrix multipication compute
@implementation MetalMatrixMult
{
@private
     // Metal assests for the compute kernel
     id<MTLDevice>                m_Device;
     id<MTLCommandQueue>          m_Queue;
     id<MTLComputePipelineState>  m_Kernel;
     id<MTLCommandBuffer>         m_CmdBuffer;
     id<MTLComputeCommandEncoder> m_Encoder;
     
     // Buffer for matrices
     MetalMatrixBuffers*  mpBuffers;
     
     // Number of rows in matrices A and C.
     uint16_t _m;
     
     // Number of columns in matrix A; number of rows in matrix B.
     uint16_t _n;
     
     // Number of columns in matrices B and C.
     uint16_t _k;
     
     // Output matrix (padded) C row count
     uint16_t _M;
     
     // Output matrix (padded) C column count
     uint16_t _K;
     
     // Compute kernel threads
     MTLSize m_ThreadGroupSize;
     MTLSize m_ThreadGroups;
     
     // Dispatch Quueue
     dispatch_group_t  m_DGroup;
     dispatch_queue_t  m_DQueue;
}

- (instancetype) init
{
     self = [super init];
     
     if(self)
     {
          static dispatch_once_t token = 0;
          
          dispatch_once(&token, ^{
               // Dispatch group for  Metal buffer initializations
               m_DGroup = dispatch_group_create();
               
               // Dispatch queue for Metal buffers
               m_DQueue = dispatch_queue_create("com.apple.matrixmult.metal.main", 0);
               
               // Metal default system device
               m_Device = MTLCreateSystemDefaultDevice();
               
               if(!m_Device)
               {
                    NSLog(@">> ERROR: Failed creating a system default device!");
                    
                    assert(0);
               } // if
               
               // Command queue
               m_Queue = [m_Device newCommandQueue];
               
               if(!m_Queue)
               {
                    NSLog(@">> ERROR: Failed creating a command queue!");
                    
                    assert(0);
               } // if
               
               // Default library
               id <MTLLibrary> library = [m_Device newDefaultLibrary];
               
               if(!library)
               {
                    assert(0);
               } // if
               
               // New compute kernel function
               id<MTLFunction> func = [library newFunctionWithName:@"MatrixMultiply"];
               
               if(!func)
               {
                    NSLog(@">> ERROR: Failed creating a named function!");
                    
                    assert(0);
               } // if
               
               // Pipeline state, or the compute kernel
               m_Kernel = [m_Device newComputePipelineStateWithFunction:func
                                                                  error:nil];
               
               if(!m_Kernel)
               {
                    NSLog(@">> ERROR: Failed creating a compute pipeline state!");
                    
                    assert(0);
               } // if
               
               // Create a mutable array for buffers
               mpBuffers = [[MetalMatrixBuffers alloc] initWithDevice:m_Device
                                                             capacity:eMTLMatBufferMax];
               
               if(!mpBuffers)
               {
                    NSLog(@">> ERROR: Failed creating a mutable array for Metal buffers!");
                    
                    assert(0);
               } // if
          });
          
          // Initialize thread-group size
          m_ThreadGroupSize = MTLSizeMake(4, 8, 1);
          
          // Initialize thread-group parameters
          m_ThreadGroups.width  = 0;
          m_ThreadGroups.height = 0;
          m_ThreadGroups.depth  = 1;
          
          // Initialize the matrix dimensions
          _m = 0;
          _k = 0;
          _n = 0;
          
          // Initialize the aligned (padded) matrix dimensions
          _M = 0;
          _K = 0;
     } // if
     
     return self;
} // init

// Set the row count of matrix A
- (void) setM:(uint16_t)m
{
     if(m != _m)
     {
          // Row count
          _m = m;
          
          // Aligned (padded) row count
          _M = (_m % 8) ? ((_m + 8) / 8) * 8 : _m;
          
          // Thread group size based on row count of matrix A
          NSUInteger width  = _m % 8 ? (_m + 8) / 8 : _m / 8;
          
          m_ThreadGroups.width = (width % m_ThreadGroupSize.width)
          ? (width + m_ThreadGroupSize.width)/m_ThreadGroupSize.width
          : width / m_ThreadGroupSize.width;
     } // if
} // setM

// Set the column count of matrix B
- (void) setK:(uint16_t)k
{
     if(k != _k)
     {
          // Column count
          _k = k;
          
          // Aligned (padded) column count
          _K = (_k % 8) ? ((_k + 8)/8)*8 : _k;
          
          // Thread group size based on column count of matrix B
          NSUInteger height = _k % 8 ? (_k + 8) / 8 : _k / 8;
          
          m_ThreadGroups.height = (height % m_ThreadGroupSize.height)
          ? (height + m_ThreadGroupSize.height)/m_ThreadGroupSize.height
          : height / m_ThreadGroupSize.height;
     } // if
} // setK

// For matrix A use i=0, and for matrix B use i=1
- (float *) input:(uint32_t)idx
{
     MetalMatrixBuffer* pBuffer = mpBuffers.array[idx];
     
     return FloatRef(pBuffer.baseAddr);
} // input

// Output matrix C = A x B
- (float *) output
{
     MetalMatrixBuffer* pBuffer = mpBuffers.array[eMTLMatBufferOutA];
     
     return FloatRef(pBuffer.baseAddr);
} // output

// Create an input matrix buffer if and only if the initial buffer
// size is zero (thus indicating a nullptr buffer), or the size of
// the buffer becomes greater than a previously allocated buffer.
- (BOOL) _newInput:(const uint32_t)idx
{
     __block BOOL bSuccess = NO;
     
     // Block for creating a new input matrix buffer
     dispatch_block_t block =  ^{
          MetalMatrixBuffer* pInBuffer = mpBuffers.array[idx];
          
          bSuccess = pInBuffer != nil;
          
          if(pInBuffer)
          {
               const size_t count = (idx) ? (_n * _K)  : (_M * _n);
               const size_t size  = count * kSzMTLFloat;
               
               pInBuffer.size = size;
               
               bSuccess = pInBuffer.resized;
          } // if
          
          // Leave the group for creating a new input matrix buffer
          dispatch_group_leave(m_DGroup);
     };
     
     // Enter the group for creating an input matrix buffer
     dispatch_group_enter(m_DGroup);
     
     // Create an input matrix buffer
     dispatch_group_async(m_DGroup, m_DQueue, block);
     
     return bSuccess;
} // _newInput

// If rows or columns of matrix A or B are changed allocate
//  a new buffer for output matrix C
- (BOOL) _newOutput
{
     __block BOOL bSuccess = NO;
     
     // Block for creating an output matrix buffer
     dispatch_block_t block =  ^{
          MetalMatrixBuffer* pOutBufferA = mpBuffers.array[eMTLMatBufferOutA];
          
          bSuccess = pOutBufferA != nil;
          
          if(pOutBufferA)
          {
               const size_t size = kSzMTLFloat * _M * _K;
               
               pOutBufferA.size = size;
               
               bSuccess = pOutBufferA.resized;
          } // if
          
          // Create a buffer for output matrix C dimensions
          MetalMatrixBuffer* pOutBufferB = mpBuffers.array[eMTLMatBufferOutB];
          
          if(pOutBufferB)
          {
               pOutBufferB.size = kSzMTLMatDim;
          } // if
          
          // Leave the group for creating a new input matrix buffer
          dispatch_group_leave(m_DGroup);
     };
     
     // Enter the group for creating an output matrix buffer
     dispatch_group_enter(m_DGroup);
     
     // Create an output matrix buffer
     dispatch_group_async(m_DGroup, m_DQueue, block);
     
     return bSuccess;
} // _newOutput

- (BOOL) _newBuffers
{
     BOOL bSzMatA = [self _newInput:eMTLMatBufferInA];
     BOOL bSzMatB = [self _newInput:eMTLMatBufferInB];
     BOOL bSzMatC = [self _newOutput];
     
     return bSzMatA || bSzMatB || bSzMatC;
} // _newBuffers

- (void) _initInput:(const uint32_t)idx
{
     MetalMatrixBuffer* pInBuffer = mpBuffers.array[idx];
     
     if(pInBuffer)
     {
          // Get the matrix data from the associated Metal buffer
          FloatRef pInMatrix = FloatRef(pInBuffer.baseAddr);
          
          if(pInMatrix != nullptr)
          {
               // Matrix dimensions
               const uint16_t rows = (idx) ? _n : _M;
               const uint16_t cols = (idx) ? _K : _n;
               
               // Block for initializing input matrices
               dispatch_block_t block =  ^{
                    // Initialize input matrices using a concrete implementation
                    // of the delegate
                    [_delegate initialize:pInMatrix
                                     rows:rows
                                  columns:cols
                                    index:idx];
                    
                    // Leave the group for input matrix initializations
                    dispatch_group_leave(m_DGroup);
               };
               
               // Enter the group for input matrix initializations
               dispatch_group_enter(m_DGroup);
               
               // Initialize the input matrices
               dispatch_group_async(m_DGroup, m_DQueue, block);
          } // if
     } // if
} // _initInput

- (void) _initOutput
{
     // If the output buffer is valid initialize the values to zero
     MetalMatrixBuffer* pOutBufferA = mpBuffers.array[eMTLMatBufferOutA];
     
     if(pOutBufferA)
     {
          // Get the matrix data from the associated Metal buffer
          FloatRef pOutMatrixC = FloatRef(pOutBufferA.baseAddr);
          
          if(pOutMatrixC != nullptr)
          {
               const size_t size = pOutBufferA.buffer.length;
               
               // Block for initializing the output matrix
               dispatch_block_t block =  ^{
                    // Clear the output matrix
                    memset(pOutMatrixC, 0x0, size);
                    
                    // Leave the group for clearing the output matrix
                    dispatch_group_leave(m_DGroup);
               };
               
               // Enter the group for clearing the output matrix
               dispatch_group_enter(m_DGroup);
               
               // Initialize the output matrix buffer
               dispatch_group_async(m_DGroup, m_DQueue, block);
          } // if
     } // if
     
     // Set the buffer parameters for matrix dimensions
     MetalMatrixBuffer* pOutBufferB = mpBuffers.array[eMTLMatBufferOutB];
     
     if(pOutBufferB)
     {
          MetalMatrixDimRef pOutMatrixDims = MetalMatrixDimRef(pOutBufferB.baseAddr);
          
          if(pOutMatrixDims != nullptr)
          {
               pOutMatrixDims->m = _m;
               pOutMatrixDims->n = _n;
               pOutMatrixDims->k = _k;
               
               pOutMatrixDims->pbytes = _M * kSzMTLFloat;
               pOutMatrixDims->qbytes = _K * kSzMTLFloat;
          } // if
     } // if
} // _initOutput

- (void) _initBuffers
{
     // Wait until matrix buffers are created
     dispatch_group_wait(m_DGroup, DISPATCH_TIME_FOREVER);
     
     // Invoke the delegate for initializing the elements
     // of the input matrices A and B
     if([_delegate respondsToSelector:@selector(initialize:rows:columns:index:)])
     {
          [self _initInput:eMTLMatBufferInA];
          [self _initInput:eMTLMatBufferInB];
     } // if
     
     [self _initOutput];
} // _initBuffers

// Allocate new buffers for input matrices A and B,
// as well as the output matrix C, provided there is
// change their sizes and as determinted by their
// dimensions
- (BOOL) newBuffers
{
     BOOL success = [self _newBuffers];
     
     [self _initBuffers];
     
     return success;
} // newBuffers

// Submit a specific buffer to our encoder
- (void) _encode:(const uint32_t)idx
{
     MetalMatrixBuffer* pBuffer = mpBuffers.array[idx];
     
     if(pBuffer)
     {
          // Block for encoding a Metal matrix buffer
          dispatch_block_t block =  ^{
               [m_Encoder setBuffer:pBuffer.buffer
                             offset:0
                            atIndex:idx];
               
               dispatch_group_leave(m_DGroup);
          };
          
          // Dispatch group for input matrix A
          dispatch_group_enter(m_DGroup);
          
          // Submit buffer for input matrix A to the encoder
          dispatch_group_async(m_DGroup, m_DQueue, block);
     } // if
} // _encodeWith

// Create a command buffer, encode and set buffers
- (BOOL) encode
{
     // Acquire a command buffer for compute
     m_CmdBuffer = [m_Queue commandBuffer];
     
     if(!m_CmdBuffer)
     {
          // Wait until matrix initializations are complete
          dispatch_group_wait(m_DGroup, DISPATCH_TIME_FOREVER);
          
          NSLog(@">> ERROR: Failed acquiring a command buffer!");
          
          return NO;
     } // if
     
     // Acquire a compute command encoder
     m_Encoder = [m_CmdBuffer computeCommandEncoder];
     
     if(!m_Encoder)
     {
          // Wait until matrix initializations are complete
          dispatch_group_wait(m_DGroup, DISPATCH_TIME_FOREVER);
          
          NSLog(@">> ERROR: Failed acquiring a compute command encoder!");
          
          return NO;
     } // if
     
     // Set the encoder with the buffers
     [m_Encoder setComputePipelineState:m_Kernel];
     
     // Wait until matrix initializations are complete
     dispatch_group_wait(m_DGroup, DISPATCH_TIME_FOREVER);
     
     // Submit input matrix buffer A to the encoder
     [self _encode:eMTLMatBufferInA];
     
     // Submit input matrix buffer B to the encoder
     [self _encode:eMTLMatBufferInB];
     
     // Submit output matrix buffer C to the encoder
     [self _encode:eMTLMatBufferOutA];
     
     // Submit buffer for output matrix dimensions to the encoder
     [self _encode:eMTLMatBufferOutB];
     
     // Wait until the encoding is complete
     dispatch_group_wait(m_DGroup, DISPATCH_TIME_FOREVER);
     
     return YES;
} // encode

// Dispatch the compute kernel for matrix multipication
- (void) dispatch
{
     [m_Encoder dispatchThreadgroups:m_ThreadGroups
               threadsPerThreadgroup:m_ThreadGroupSize];
} // dispatch

// Wait until the matrix computation is complete
- (void) finish
{
     [m_Encoder endEncoding];
     
     [m_CmdBuffer commit];
     [m_CmdBuffer waitUntilCompleted];
} // finish

@end
