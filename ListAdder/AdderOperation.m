/*
    File:       AdderOperation.m

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

#import "AdderOperation.h"

@interface AdderOperation ()

// only accessed by the operation thread

@property (retain, readwrite) NSNumberFormatter *   formatter;

// read/write versions of public properties

@property (assign, readwrite) NSInteger             total;
@property (copy,   readwrite) NSString *            formattedTotal;

@end

@implementation AdderOperation

- (id)initWithNumbers:(NSArray *)numbers
{
    // can be called on any thread
    
    // An NSOperation's init method does not have to be thread safe; it's relatively 
    // easy to enforce the requirement that the init method is only called by the 
    // main thread, or just one single thread.  However, in this case it's easy to 
    // make the init method thread safe, so we do that.
    
    assert(numbers != nil);
    self = [super init];
    if (self != nil) {

        // Initialise our numbers property by taking a copy of the incoming 
        // numbers array.  Note that we use a copy here.  If you just retain 
        // the incoming value then the program will crash because our client 
        // passes us an NSMutableArray (which is type compatible with NSArray) 
        // and can then mutate it behind our back.

        if ( [[NSUserDefaults standardUserDefaults] boolForKey:@"retainNotCopy"] ) {
            self->_numbers = [numbers retain];
        } else {
            self->_numbers = [numbers copy];
        }
        assert(self->_numbers != nil);

        // Set up our sequenceNumber property.  Note that, because we can be called 
        // from any thread, we have to use a lock to protect sSequenceNumber (that 
        // is, to guarantee that each operation gets a unique sequence number).  
        // In this case locking isn't a problem because we do very little within 
        // that lock; there's no possibility of deadlock, and the chances of lock 
        // contention are slight.

        @synchronized ([AdderOperation class]) {
            static NSUInteger sSequenceNumber;
            self->_sequenceNumber = sSequenceNumber;
            sSequenceNumber += 1;
        }

        self->_interNumberDelay = 1.0;
    }
    return self;
}

- (id)initWithNumbers2:(NSArray *)numbers
{
    // IMPORTANT: This is method is not actually used.  It is here because it's a code 
    // snippet in the technote, and i wanted to make sure it compiles.

    assert(NO);

    assert(numbers != nil);
    self = [super init];
    if (self != nil) {
        self->_numbers = [numbers copy];
        assert(self->_numbers != nil);
    }
    return self;
}

- (void)dealloc
{
    // can be called on any thread
    
    // Note that we can safely release our properties here, even properties like 
    // formatter, which are meant to only be accessed by the operation's thread. 
    // That's because -retain and -release are always fully thread safe, even in 
    // situations where other methods on an object are not.
    
    [self->_numbers release];
    [self->_formatter release];
    [self->_formattedTotal release];
    [super dealloc];
}

@synthesize numbers          = _numbers;
@synthesize sequenceNumber   = _sequenceNumber;
@synthesize interNumberDelay = _interNumberDelay;
@synthesize total            = _total;
@synthesize formatter        = _formatter;
@synthesize formattedTotal   = _formattedTotal;

- (void)main
{
    NSUInteger      numberCount;
    NSUInteger      numberIndex;
    NSTimeInterval  localInterNumberDelay;
    NSInteger       localTotal;

    // This method is called by a thread that's set up for us by the NSOperationQueue.
    
    assert( ! [NSThread isMainThread] );
    
    // We latch interNumberDelay at this point so that, if the client changes 
    // it after they've queued the operation (something they shouldn't be doing, 
    // but hey, we're cautious), we always see a consistent value.
    
    localInterNumberDelay = self.interNumberDelay;
    
    // Set up the formatter.  This is a private property that's only accessed by 
    // the operation thread, so we don't have to worry about synchronising access to it.
    
    self.formatter = [[[NSNumberFormatter alloc] init] autorelease];
    assert(self.formatter != nil);
    
    [self.formatter setNumberStyle:NSNumberFormatterDecimalStyle];
    [self.formatter setUsesGroupingSeparator:YES];
    
    // Do the heavy lifting (-:
    
    localTotal = 0;
    numberCount = [self.numbers count];
    for (numberIndex = 0; numberIndex < numberCount; numberIndex++) {
        NSNumber *  numberObj;
        
        // Check for cancellation.
        
        if ([self isCancelled]) {
            break;
        }
        
        // Sleep for the inter-number delay.  This makes it easiest to 
        // test cancellation and so on.
        
        [NSThread sleepForTimeInterval:localInterNumberDelay];
        
        // Do the maths (but they said there'd be no maths!).
        
        numberObj = [self.numbers objectAtIndex:numberIndex];
        assert([numberObj isKindOfClass:[NSNumber class]]);
        
        localTotal += [numberObj integerValue];
    }
    
    // Set our output properties base on the value we calculated.  Our client 
    // shouldn't look at these until -isFinished goes to YES (which happens when 
    // we return from this method).
    
    self.total = localTotal;
    self.formattedTotal = [self.formatter stringFromNumber:[NSNumber numberWithInteger:localTotal]];
}

- (void)main2
{
    NSUInteger      numberCount;
    NSUInteger      numberIndex;
    NSInteger       total;

    // IMPORTANT: This is method is not actually used.  It is here because it's a code 
    // snippet in the technote, and i wanted to make sure it compiles.

    assert(NO);

    // This method is called by a thread that's set up for us by the NSOperationQueue.
    
    assert( ! [NSThread isMainThread] );
    
    // Do the heavy lifting (-:
    
    total = 0;
    numberCount = [self.numbers count];
    for (numberIndex = 0; numberIndex < numberCount; numberIndex++) {
        NSNumber *  numberObj;
        
        // Check for cancellation.
        
        if ([self isCancelled]) {
            break;
        }
        
        // Sleep for a second.  This makes it easiest to test cancellation 
        // and so on.
        
        [NSThread sleepForTimeInterval:1.0];
        
        // Do the maths (but they said there'd be no maths!).
        
        numberObj = [self.numbers objectAtIndex:numberIndex];
        assert([numberObj isKindOfClass:[NSNumber class]]);
        
        total += [numberObj integerValue];
    }
    
    // Set our output properties base on the value we calculated.  Our client 
    // shouldn't look at these until -isFinished goes to YES (which happens when 
    // we return from this method).
    
    self.formattedTotal = [self.formatter stringFromNumber:[NSNumber numberWithInteger:total]];
}

@end
