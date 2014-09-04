/*
    File:       QReachabilityOperation.h

    Contains:   Runs until a host's reachability attains a certain value.

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

#import "QReachabilityOperation.h"

@interface QReachabilityOperation ()

// read/write versions of public properties

@property (assign, readwrite) NSUInteger    flags;

// forward declarations

static void ReachabilityCallback(
    SCNetworkReachabilityRef    target,
    SCNetworkReachabilityFlags  flags,
    void *                      info
);

- (void)reachabilitySetFlags:(NSUInteger)newValue;

@end

@implementation QReachabilityOperation

- (id)initWithHostName:(NSString *)hostName
    // See comment in header.
{
    assert(hostName != nil);
    self = [super init];
    if (self != nil) {
        self->_hostName         = [hostName copy];
        self->_flagsTargetMask  = kSCNetworkReachabilityFlagsReachable | kSCNetworkReachabilityFlagsInterventionRequired;
        self->_flagsTargetValue = kSCNetworkReachabilityFlagsReachable;
    }
    return self;
}

- (void)dealloc
{
    [self->_hostName release];
    assert(self->_ref == NULL);
    [super dealloc];
}

@synthesize hostName         = _hostName;
@synthesize flagsTargetMask  = _flagsTargetMask;
@synthesize flagsTargetValue = _flagsTargetValue;
@synthesize flags            = _flags;

- (void)operationDidStart
    // Called by QRunLoopOperation when the operation starts.  This is our opportunity 
    // to install our run loop callbacks, which is exactly what we do.  The only tricky 
    // thing is that we have to schedule the reachability ref to run in all of the 
    // run loop modes specified by our client.
{
    Boolean                         success;
    SCNetworkReachabilityContext    context = { 0, self, NULL, NULL, NULL };
    
    assert(self->_ref == NULL);
    self->_ref = SCNetworkReachabilityCreateWithName(NULL, [self.hostName UTF8String]);
    assert(self->_ref != NULL);

    success = SCNetworkReachabilitySetCallback(self->_ref, ReachabilityCallback, &context);
    assert(success);

    for (NSString * mode in self.actualRunLoopModes) {
        success = SCNetworkReachabilityScheduleWithRunLoop(self->_ref, CFRunLoopGetCurrent(), (CFStringRef) mode);
        assert(success);
    }
}

static void ReachabilityCallback(
    SCNetworkReachabilityRef    target,
    SCNetworkReachabilityFlags  flags,
    void *                      info
)
    // Called by the system when the reachability flags change.  We just forward 
    // the flags to our Objective-C code.
{
    QReachabilityOperation *    obj;
    
    obj = (QReachabilityOperation *) info;
    assert([obj isKindOfClass:[QReachabilityOperation class]]);
    assert(target == obj->_ref);
    #pragma unused(target)
    
    [obj reachabilitySetFlags:flags];
}

- (void)reachabilitySetFlags:(NSUInteger)newValue
    // Called when the reachability flags change.  We just store the flags and then 
    // check to see if the flags meet our target criteria, in which case we stop the 
    // operation.
{
    assert( [NSThread currentThread] == self.actualRunLoopThread );
    
    self.flags = newValue;
    if ( (self.flags & self.flagsTargetMask) == self.flagsTargetValue ) {
        [self finishWithError:nil];
    }
}

- (void)operationWillFinish
    // Called by QRunLoopOperation when the operation finishes.  We just clean up 
    // our reachability ref.
{
    Boolean success;

    if (self->_ref != NULL) {
        for (NSString * mode in self.actualRunLoopModes) {
            success = SCNetworkReachabilityUnscheduleFromRunLoop(self->_ref, CFRunLoopGetCurrent(), (CFStringRef) mode);
            assert(success);
        }

        success = SCNetworkReachabilitySetCallback(self->_ref, NULL, NULL);
        assert(success);
        
        CFRelease(self->_ref);
        self->_ref = NULL;
    }
}

@end
