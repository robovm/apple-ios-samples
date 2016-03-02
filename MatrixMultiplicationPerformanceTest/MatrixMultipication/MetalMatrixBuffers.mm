/*
 Copyright (C) 2015 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 Utilities for managing metal buffers representing matrices.
 */

#import "MetalMatrixBuffers.h"

// A utility class to encapsulate instantiation of Metal matrix buffer.
// By the virtue of this encapsulation, and after the buffers are added
// to a mutable array of buffers, all buffers are kept alive in the
// matrix multipication object's life-cycle.
@implementation MetalMatrixBuffer
{
@private
    BOOL           _resized;     // Buffer size changed
    size_t         _size;        // Buffer size in bytes
    void*          _baseAddr;    // Base address for buffers
    id<MTLBuffer>  _buffer;      // Buffer for matrices
    id<MTLDevice>  _device;      // Default Metal system device
}

- (instancetype) initWithDevice:(id<MTLDevice>)device
{
    self = [super init];
    
    if(self)
    {
        if(device)
        {
            _device   = device;
            _size     = 0;
            _resized  = NO;
            _baseAddr = nullptr;
            _buffer   = nil;
        } // if
        else
        {
            NSLog(@">> ERROR: Invalid default Metal system device!");
        } // else
    } // if
    
    return self;
} // initWithDevice

- (void) setSize:(size_t)size
{
    _resized = size > _size;
    
    if(_resized)
    {
        _buffer = [_device newBufferWithLength:size
                                       options:0];
        
        if(_buffer)
        {
            _baseAddr = [_buffer contents];
            _size     = size;
        } // if
        else
        {
            NSLog(@">> ERROR: Failed creating a Metal buffer with size %lu!", size);
        } // else
    } // if
} // setSize

@end

// A utility class to encapsulate instantiation of Metal matrix buffer.
// By the virtue of this encapsulation, and after the buffers are added
// to a mutable array of buffers, all buffers are kept alive in the
// matrix multipication object's life-cycle.
@implementation MetalMatrixBuffers
{
@private
    NSMutableArray*  _array;       // Mutable array of buffers
    size_t           _capacity;    // The number of elements in the array
}

- (instancetype) initWithDevice:(id<MTLDevice>)device
                       capacity:(size_t)capacity
{
    self = [super init];
    
    if(self)
    {
        // Create a mutable array for buffers
        _array = [[NSMutableArray alloc] initWithCapacity:capacity];
        
        if(_array)
        {
            size_t i;
            
            _capacity = capacity;
            
            for(i = 0; i < _capacity; ++i)
            {
                // Initialize mutable array of buffers
                _array[i] = [[MetalMatrixBuffer alloc] initWithDevice:device];
                
                if(!_array[i])
                {
                    NSLog(@">> ERROR: Failed creating a Metal buffers at index %lu!", i);
                } // if
            } // for
        } // if
        else
        {
            NSLog(@">> ERROR: Failed creating a mutable array for Metal buffers!");
        } // else
    } // if
    
    return self;
} // initWithDevice

@end
