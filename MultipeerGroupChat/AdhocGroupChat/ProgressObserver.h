/*
     File: ProgressObserver.h
 Abstract: 
    This model class uses Key Value Observeration (KVO) to monitor the NSProgress for Multipeer Connectivity API resource sending/receiving completion progress (or cancellation). 
 
  Version: 1.0
 
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
 
 Copyright (C) 2013 Apple Inc. All Rights Reserved.
 
*/

@protocol ProgressObserverDelegate;

// This class is a helper class which implements KVO on the NSProgress cancel and completedUnitCount properties.
// This is useful for driving a UIProgressBar for exmaple
@interface ProgressObserver : NSObject

// Human readable name string for this observer
@property (nonatomic, readonly) NSString *name;
// NSProgress this class is monitoring
@property (nonatomic, readonly) NSProgress *progress;
// Delegate for receiving change events
@property (nonatomic, weak) id<ProgressObserverDelegate> delegate;

// Designated initializer
- (id)initWithName:(NSString *)name progress:(NSProgress *)progress;

@end

// Protocol for notifying listeners of changes to the NSProgress we are observing
@protocol ProgressObserverDelegate <NSObject>

// Called when there is a change to the completion % of the resource transfer
- (void)observerDidChange:(ProgressObserver *)observer;
// Called when cancel is called on the NSProgress
- (void)observerDidCancel:(ProgressObserver *)observer;
// Called when the resource transfer is complete
- (void)observerDidComplete:(ProgressObserver *)observer;

@end