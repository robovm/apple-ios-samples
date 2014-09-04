/*
     File: EnumerableClass.mm
 Abstract: n/a
  Version: 1.1
 
 Disclaimer: IMPORTANT:  This Apple software is supplied to you by Apple
 Inc. ("Apple") in consideration of your agreement to the following
 terms, and your use, installation, modification or redistribution of
 this Apple software constitutes acceptance of these terms.  If you do
 not agree with these terms, please do not use, install, modify or
 redistribute this Apple software.
 
 In consideration of your agreement to abide by the following terms, and
 subject to these terms, Apple grants you a personal, non-exclusive
 license, under Apple's copyrights in this original Apple software (the
 "Apple Software"), to use, reproduce, modify and redistribute the Apple
 Software, with or without modifications, in source and/or binary forms;
 provided that if you redistribute the Apple Software in its entirety and
 without modifications, you must retain this notice and the following
 text and disclaimers in all such redistributions of the Apple Software.
 Neither the name, trademarks, service marks or logos of Apple Inc. may
 be used to endorse or promote products derived from the Apple Software
 without specific prior written permission from Apple.  Except as
 expressly stated in this notice, no other rights or licenses, express or
 implied, are granted by Apple herein, including but not limited to any
 patent rights that may be infringed by your derivative works or by other
 works in which the Apple Software may be incorporated.
 
 The Apple Software is provided by Apple on an "AS IS" basis.  APPLE
 MAKES NO WARRANTIES, EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION
 THE IMPLIED WARRANTIES OF NON-INFRINGEMENT, MERCHANTABILITY AND FITNESS
 FOR A PARTICULAR PURPOSE, REGARDING THE APPLE SOFTWARE OR ITS USE AND
 OPERATION ALONE OR IN COMBINATION WITH YOUR PRODUCTS.
 
 IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL
 OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 INTERRUPTION) ARISING IN ANY WAY OUT OF THE USE, REPRODUCTION,
 MODIFICATION AND/OR DISTRIBUTION OF THE APPLE SOFTWARE, HOWEVER CAUSED
 AND WHETHER UNDER THEORY OF CONTRACT, TORT (INCLUDING NEGLIGENCE),
 STRICT LIABILITY OR OTHERWISE, EVEN IF APPLE HAS BEEN ADVISED OF THE
 POSSIBILITY OF SUCH DAMAGE.
 
 Copyright (C) 2014 Apple Inc. All Rights Reserved.
 
 */

#import "EnumerableClass.h"

#include <vector>

// NSEnumerator subclass, tailored specifically for enumerating over the data
// stored in an EnumerableClass instance.
@interface EnumerableClassEnumerator : NSEnumerator
{
    // Pointer to the EnumerableClass instance we are enumerating.
    EnumerableClass *_enumerableClassInstanceToEnumerate;
    // Current position
    NSUInteger _currentIndex;
}
- (id)initWithEnumerableClass:(EnumerableClass*)anEnumerableClass;
@end


@implementation EnumerableClassEnumerator

// -------------------------------------------------------------------------------
//	initWithEnumerableClass:
//  Designated initializer for this class.
// -------------------------------------------------------------------------------
- (id)initWithEnumerableClass:(EnumerableClass*)anEnumerableClass
{
    self = [super init];
    if (self)
    {
        // Note: If you choose not to use ARC, the enumerator should explicitly
        //       retain the object it is enumerating.
        _enumerableClassInstanceToEnumerate = anEnumerableClass;
        _currentIndex = 0;
    }
    return self;
}

// -------------------------------------------------------------------------------
//	nextObject
//  You must override this method in any NSEnumerator subclass you create.
//  This method is called repeatedly during enumeration to get the next object
//  until all objects have been enumerated at which point it must return nil.
// -------------------------------------------------------------------------------
- (id)nextObject
{
    if (_currentIndex >= _enumerableClassInstanceToEnumerate.numItems)
        return nil;
    
    return _enumerableClassInstanceToEnumerate[_currentIndex++];
}

// NOTE: NSEnumerator provides a default implementation of -allObjects that uses
//       -nextObject to fill up an array, which is then returned.  You may wish 
//       to provide your own implementation for better performance.

@end



@implementation EnumerableClass
{
    // You can create a specialization of a C++ STL container that holds
    // pointers to Objective-C objects.
    //
    // Keep in mind that C++ containers do not understand Objective-C memory
    // semantics.  Under ARC, the definition below is silently modified to
    // std::vector<__strong NSNumber*> which causes the container to take
    // ownership of any object added to it.
    // If you choose not to use ARC, you must remember to retain and release any
    // object inserted, or removed from the container.
	std::vector<NSNumber*> _list;
}

// -------------------------------------------------------------------------------
//	initWithCapacity:
//  Designated initializer for this class.
// -------------------------------------------------------------------------------
- (id)initWithCapacity:(NSUInteger)numItems
{
	self = [super init];
	if (self)
	{
        // Since this is just a sample, we'll generate some random data for the
        // enumeration to return later.
        srandomdev();
        
		for(NSUInteger i = 0; i < numItems; ++i)
		{
            NSNumber *aRandomNumber = @(random());
			_list.push_back(aRandomNumber);
		}
	}
	return self;
}

// NOTE: If you choose not to use ARC, you must override -dealloc.  Your
//       implementation must send a -release message to all items in _list.

// -------------------------------------------------------------------------------
//	numItems
//  Custom implementation of the getter for the numItems property.
// -------------------------------------------------------------------------------
- (NSUInteger)numItems
{
    return _list.size();
}

// -------------------------------------------------------------------------------
//	objectAtIndexedSubscript:
// -------------------------------------------------------------------------------
- (id)objectAtIndexedSubscript:(NSUInteger)idx
{
    // Specifying an invalid index is a programmer error and should be treated as
    // such.
    if (idx >= _list.size())
        [NSException raise:NSRangeException format:@"Index %li is beyond bounds [0, %li].", (unsigned long)idx, _list.size()];
    
    return _list[idx];
}

// -------------------------------------------------------------------------------
//	enumerateObjectsUsingBlock:
// -------------------------------------------------------------------------------
- (void)enumerateObjectsUsingBlock:(void (^)(id obj, NSUInteger idx, BOOL *stop))block
{
    BOOL stop = NO;
    
    for (auto it=_list.cbegin(); it!=_list.cend(); it++)
    {
        // Subtracting 'it' from an iterator pointing to the first element in
        // _list gives the position of 'it' in _list.
        NSUInteger index = it - _list.cbegin();
        
        // If you choose not to use ARC, you do not need to retain+autorelease the
        // object before passing it to the block supplied by the caller.  It is the
        // caller's responsibility to ensure we are not deallocated during
        // enumeration.
        block(*it, index, &stop);
        
        if (stop)
            break;
    }
}

// -------------------------------------------------------------------------------
//	objectEnumerator
//  Creates and returns an instance of EnumerableClassEnumerator, our NSEnumerator
//  subclass tailored specifically for enumerating over a vector of NSNumber
//  objects.
// -------------------------------------------------------------------------------
- (NSEnumerator*)objectEnumerator
{
    return [[EnumerableClassEnumerator alloc] initWithEnumerableClass:self];
}

// -------------------------------------------------------------------------------
//	countByEnumeratingWithState:objects:count:
//  This is where all the fast enumeration magic happens.
//  You have two choices when implementing this method:
//      1) Use the stack based array provided by stackbuf. If you do this, then
//         you must respect the value of 'stackbufLength'.
//      2) Return your own array of objects. If you do this, return the full
//         length of each array returned until you run out of objects, then
//         return 0. For example, a linked-array implementation may return each
//         array in order until you iterate through all arrays.
//  In either case, state->itemsPtr MUST be a valid array (non-nil) before
//  control reaches the end of this method.
//
#define USE_STACKBUF 1
//
//  This sample can be configured to use either approach by changing the value of
//  the USE_STACKBUF define (Set to 1 to use the first approach or 0 for to use
//  second approach).
// -------------------------------------------------------------------------------
- (NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state
                                  objects:(id __unsafe_unretained [])stackbuf
                                    count:(NSUInteger)stackbufLength
{
    NSUInteger count = 0;
    
    // We use state->state to track how far we have enumerated through _list
    // between sucessive invocations of -countByEnumeratingWithState:objects:count:
    unsigned long countOfItemsAlreadyEnumerated = state->state;
    
	// This is the initialization condition, so we'll do one-time setup here.
	// Ensure that you never set state->state back to 0, or use another method to
    // detect initialization (such as using one of the values of state->extra).
	if(countOfItemsAlreadyEnumerated == 0)
	{
		// We are not tracking mutations, so we'll set state->mutationsPtr to point
        // into one of our extra values, since these values are not otherwise used
        // by the protocol.
		// If your class was mutable, you may choose to use an internal variable that
        // is updated when the class is mutated.
		// state->mutationsPtr MUST NOT be NULL and SHOULD NOT be set to self.
		state->mutationsPtr = &state->extra[0];
	}
    
#if USE_STACKBUF // Method One.
    
	// Now we provide items and determine if we have finished iterating.
	if(countOfItemsAlreadyEnumerated < _list.size())
	{
		// Set state->itemsPtr to the provided buffer.
		// state->itemsPtr MUST NOT be NULL.
		state->itemsPtr = stackbuf;
		// Fill in the stack array, either until we've provided all items from the list
		// or until we've provided as many items as the stack based buffer will hold.
		while((countOfItemsAlreadyEnumerated < _list.size()) && (count < stackbufLength))
		{
			// Add the item for the next index to stackbuf.
            //
            // If you choose not to use ARC, you do not need to retain+autorelease the
            // objects placed into stackbuf.  It is the caller's responsibility to ensure we
            // are not deallocated during enumeration.
			stackbuf[count] = _list[countOfItemsAlreadyEnumerated];
			countOfItemsAlreadyEnumerated++;
            
            // We must return how many items are in state->itemsPtr.
			count++;
		}
	}
	else
	{
		// We've already provided all our items.  Signal that we are finished by returning 0.
		count = 0;
	}
    
#else // Method Two.
    
    // Now we provide items.  We only have one list to return.
    if (countOfItemsAlreadyEnumerated < _list.size())
    {
        // Set state->itemsPtr to the backing array of _list.  Note, the ability to access
        // the data in an std::vector as a C array requires C++11.
        //
        // If you choose not to use ARC, you do not need to retain+autorelease the
        // objects placed into state->itemsPtr.  It is the caller's responsibility to ensure
        // we are not deallocated during enumeration.
        //
        // The code below works around a nuance of the type-casting rules when ARC is enabled.
        //
        // Section 4.3.3 of the Automatic Reference counting documentation discusses the
        // semantics of casts under ARC:
        //
        // A program is ill-formed if an expression of type T* is converted, explicitly or
        // implicitly, to the type U*, where T and U have different ownership qualification,
        // unless:
        //      * T is qualified with __strong, __autoreleasing, or __unsafe_unretained, and
        //        U is qualified with both const and __unsafe_unretained; or
        //      * either T or U is cv void, where cv is an optional sequence of non-ownership
        //        qualifiers; or
        //      * the conversion is requested with a reinterpret_cast in Objective-C++; or
        //      * the conversion is a well-formed pass-by-writeback.
        // <http://clang.llvm.org/docs/AutomaticReferenceCounting.html>
        //
        // The type of state->itemsPtr is defined to be an array whose element type is 'id'
        // with an ownership qualifier of __unsafe_unretained.  The type returned by
        // _list.data() is defined to be an array whose element type is 'NSNumber*' with an
        // ownership qualifier of __strong.  Under ARC, a cast from the later type to the
        // former type is ill-formed.  Under ARC, a cast from the later type to the former
        // type is not allowed.
        //
        // We work around this by casting the type returned by calling _list.data() to an
        // array whose element type is a const qualified 'id' with an ownership qualifier of
        // __unsafe_unretained; legal as per the first exception in the above list.  A second
        // cast is then used to remove the const qualification; legal because the ownership
        // qualifications are now the same.
        //
        __unsafe_unretained const id * const_array = _list.data();
        state->itemsPtr = (__typeof__(state->itemsPtr))const_array;
        
        // We must return how many items are in state->itemsPtr.
        // We are returning all of our items at once so set count equal to the size of _list.
        count = _list.size();
        
        countOfItemsAlreadyEnumerated = _list.size();
    }
    else
    {
        // We've already provided all our items.  Signal that we are finished by returning 0.
        count = 0;
    }
    
#endif
    
    // Update state->state with the new value of countOfItemsAlreadyEnumerated so that it is
    // preserved for the next invocation.
    state->state = countOfItemsAlreadyEnumerated;
    
	return count;
}

@end
