/*
    File:       NetworkManager.h

    Contains:   A singleton to manage the core network interactions.

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

@interface NetworkManager : NSObject
{
    NSThread *                      _networkRunLoopThread;
    NSOperationQueue *              _queueForNetworkManagement;
    NSOperationQueue *              _queueForNetworkTransfers;
    NSOperationQueue *              _queueForCPU;
    CFMutableDictionaryRef          _runningOperationToTargetMap;
    CFMutableDictionaryRef          _runningOperationToActionMap;
    CFMutableDictionaryRef          _runningOperationToThreadMap;
    NSUInteger                      _runningNetworkTransferCount;
}

+ (NetworkManager *)sharedManager;
    // Returns the network manager singleton.
    //
    // Can be called from any thread.

- (NSMutableURLRequest *)requestToGetURL:(NSURL *)url;
    // Returns a mutable request that's configured to do an HTTP GET operation 
    // for the specified URL.  This sets up any request properties that should be 
    // common to all network requests, most notably the user agent string.
    //
    // Can be called from any thread.

// networkInUse is YES if any network transfer operations are in progress; you can only 
// call the getter from the main thread.

@property (nonatomic, assign, readonly ) BOOL           networkInUse;               // observable, always changes on main thread

// Operation dispatch

// We have three operation queues to separate our various operations.  There are a bunch of 
// important points here:
//
// o There are separate network management, network transfer and CPU queues, so that network 
//   operations don't hold up CPU operations, and vice versa.
//
// o The width of the network management queue (that is, the maxConcurrentOperationCount value) 
//   is unbounded, so that network management operations always proceed.  This is fine because 
//   network management operations are all run loop based and consume very few real resources.
//
// o The width of the network transfer queue is set to some fixed value, which controls the total 
//   number of network operations that we can be running simultaneously.
//
// o The width of the CPU operation queue is left at the default value, which typically means 
//   we start one CPU operation per available core (which on iOS devices means one).  This 
//   prevents us from starting lots of CPU operations that just thrash the scheduler without 
//   getting any concurrency benefits.
//
// o When you queue an operation you must supply a target/action pair that is called when 
//   the operation completes without being cancelled.
//
// o The target/action pair is called on the thread that added the operation to the queue.
//   You have to ensure that this thread runs its run loop.
//
// o If you queue a network operation and that network operation supports the runLoopThread 
//   property and the value of that property is nil, this sets the run loop thread of the operation 
//   to the above-mentioned internal networking thread.  This means that, by default, all 
//   network run loop callbacks run on this internal networking thread.  The goal here is to 
//   minimise main thread latency.
// 
//   It's worth noting that this is only true for network operation run loop callbacks, and is
//   /not/ true for target/action completions.  These are called on the thread that queued 
//   the operation, as described above.
//
// o If you cancel an operation you must do so using -cancelOperation:, lest things get 
//   very confused.
//
// o Both -addXxxOperation:finishedTarget:action: and -cancelOperation: can be called from 
//   any thread.
//
// o If you always cancel the operation on the same thread that you used to queue the operation 
//   (and therefore the same thread that will run the target/action completion), you can be 
//   guaranteed that, after -cancelOperation: returns, the target/action completion will 
//   never be called.
//
// o To simplify clean up, -cancelOperation: does nothing if the supplied operation is nil 
//   or if it's not currently queued.
//
// We don't do any prioritisation of operations, although that would be a relatively 
// simple extension.  For example, you could have one network transfer queue for gallery XML 
// files and another for thumbnail downloads, and tweak their widths appropriately.  And 
// don't forget, within a queue, a client can affect the priority of an operation using 
// -[NSOperation setThreadPriority:] and -[NSOperation setQueuePriority:].

- (void)addNetworkManagementOperation:(NSOperation *)operation finishedTarget:(id)target action:(SEL)action;
- (void)addNetworkTransferOperation:(NSOperation *)operation finishedTarget:(id)target action:(SEL)action;
- (void)addCPUOperation:(NSOperation *)operation finishedTarget:(id)target action:(SEL)action;
- (void)cancelOperation:(NSOperation *)operation;

@end
