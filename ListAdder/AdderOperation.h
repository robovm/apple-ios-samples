/*
    File:       AdderOperation.h

    Contains:   Adds an array of numbers (very slowly) and returns the result.

    Written by: DTS

    Copyright:  Copyright (c) 2010 Apple Inc. All Rights Reserved.

    Disclaimer: IMPORTANT: This Apple software is supplied to you by Apple Inc.
                ("Apple") in consideration of your agreement to the following
                terms, and your use, installation, modification or
                redistribution of this Apple software constitutes acceptance of
                these terms.  If you do not agree with these terms, please do
                not use, install, modify or redistribute this Apple software.

                In consideration of your agreement to abide by the following
                terms, and subject to these terms, Apple grants you a personal,
                non-exclusive license, under Apple's copyrights in this
                original Apple software (the "Apple Software"), to use,
                reproduce, modify and redistribute the Apple Software, with or
                without modifications, in source and/or binary forms; provided
                that if you redistribute the Apple Software in its entirety and
                without modifications, you must retain this notice and the
                following text and disclaimers in all such redistributions of
                the Apple Software. Neither the name, trademarks, service marks
                or logos of Apple Inc. may be used to endorse or promote
                products derived from the Apple Software without specific prior
                written permission from Apple.  Except as expressly stated in
                this notice, no other rights or licenses, express or implied,
                are granted by Apple herein, including but not limited to any
                patent rights that may be infringed by your derivative works or
                by other works in which the Apple Software may be incorporated.

                The Apple Software is provided by Apple on an "AS IS" basis. 
                APPLE MAKES NO WARRANTIES, EXPRESS OR IMPLIED, INCLUDING
                WITHOUT LIMITATION THE IMPLIED WARRANTIES OF NON-INFRINGEMENT,
                MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE, REGARDING
                THE APPLE SOFTWARE OR ITS USE AND OPERATION ALONE OR IN
                COMBINATION WITH YOUR PRODUCTS.

                IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT,
                INCIDENTAL OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED
                TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
                DATA, OR PROFITS; OR BUSINESS INTERRUPTION) ARISING IN ANY WAY
                OUT OF THE USE, REPRODUCTION, MODIFICATION AND/OR DISTRIBUTION
                OF THE APPLE SOFTWARE, HOWEVER CAUSED AND WHETHER UNDER THEORY
                OF CONTRACT, TORT (INCLUDING NEGLIGENCE), STRICT LIABILITY OR
                OTHERWISE, EVEN IF APPLE HAS BEEN ADVISED OF THE POSSIBILITY OF
                SUCH DAMAGE.

*/

#import <Foundation/Foundation.h>

/*
    AdderOperation is an example of using NSOperation to do asynchronous processing 
    in a sane fashion.  It follows the thread confinement model.  That is, you 
    initialise the operation with an array of numbers to operate on, and it adds up 
    those numbers and vends the result through read-only properties.
    
    The data used by the operation are made thread safe in a number of different ways:
    
      o Some properties (for example, numbers) are set up at initialisation time and 
        can't be changed.  These are immutable, thus can be safely shared between threads.

      o Some properties must be set before the operation is queued and should be immutable 
        after that.  Again, these are thread safe because there's no possibility of two 
        threads trying to mutate the same value at the same time.  interNumberDelay 
        is an example of this.

      o Some properties are set by the operation but shouldn't be read by the client 
        until the operation is finished.  total and formattedTotal are examples of this.
    
      o Some properties, like formatter, are private to the operation and are only ever 
        accessed by the thread running the operation.
        
      o Global data, like sSequenceNumber, is protected by a lock.
    
    It's obvious that adding a few numbers is going to happen very quickly, so we 
    artifically slow things down by sleeping for an extended period of time between 
    additions.  This delay is controlled by the interNumberDelay, which defaults to 
    one second.
*/

@interface AdderOperation : NSOperation
{
    NSArray *           _numbers;
    NSUInteger          _sequenceNumber;
    NSTimeInterval      _interNumberDelay;
    NSInteger           _total;
    NSNumberFormatter * _formatter;
    NSString *          _formattedTotal;
}

- (id)initWithNumbers:(NSArray *)numbers;

// set up by the init method that can't be changed

@property (copy,   readonly ) NSArray *         numbers;                // of NSNumber
@property (assign, readonly ) NSUInteger        sequenceNumber;

// must be configured before the operation is started

@property (assign, readwrite) NSTimeInterval    interNumberDelay;       // defaults to 1.0

// only meaningful after the operation is finished

@property (assign, readonly ) NSInteger         total;
@property (copy,   readonly ) NSString *        formattedTotal;

@end
