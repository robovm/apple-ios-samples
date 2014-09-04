
/*
     File: MotionSynchronizer.m
 Abstract: Synchronizes motion samples with media samples
  Version: 2.1
 
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

#import "MotionSynchronizer.h"
#import <CoreMotion/CoreMotion.h>

#define MOTION_DEFAULT_SAMPLES_PER_SECOND 60
#define MEDIA_ARRAY_SIZE 5
#define MOTION_ARRAY_SIZE 10

CFStringRef const VIDEOSNAKE_REMAPPED_PTS = CFSTR("RemappedPTS");

BOOL LOG = YES;

@interface MotionSynchronizer () {
	id<MotionSynchronizationDelegate> _delegate;
	dispatch_queue_t _delegateCallbackQueue;
}

@property(nonatomic, retain) __attribute__((NSObject)) CMClockRef motionClock;
@property(nonatomic, retain) NSOperationQueue *motionQueue;
@property(nonatomic, retain) CMMotionManager *motionManager;
@property(nonatomic, retain) NSMutableArray *mediaSamples;
@property(nonatomic, retain) NSMutableArray *motionSamples;

@end

@implementation MotionSynchronizer

- (id)init
{
    self = [super init];
    if (self != nil) {
		
		_mediaSamples = [[NSMutableArray alloc] initWithCapacity:MEDIA_ARRAY_SIZE];
		_motionSamples = [[NSMutableArray alloc] initWithCapacity:MOTION_ARRAY_SIZE];
		
		_motionQueue = [[NSOperationQueue alloc] init];
		[_motionQueue setMaxConcurrentOperationCount:1]; // Serial queue
		
		_motionManager = [[CMMotionManager alloc] init];

		[self setMotionRate:MOTION_DEFAULT_SAMPLES_PER_SECOND];
		
		_motionClock = CMClockGetHostTimeClock();
		if (_motionClock)
			CFRetain(_motionClock);
	}
	
	return self;
}

- (void)dealloc
{	
	[_motionManager release];
	[_motionQueue release];
	[_motionSamples release];
	[_mediaSamples release];
	[_delegateCallbackQueue release];
	
	if (_sampleBufferClock)
		CFRelease(_sampleBufferClock);
	if (_motionClock)
		CFRelease(_motionClock);
	
	[super dealloc];
}

- (void)start
{
	if ( !self.motionManager.deviceMotionActive ) {
		if ( self.sampleBufferClock == NULL ) {
			@throw [NSException exceptionWithName:NSInternalInconsistencyException reason:@"No sample buffer clock. Please set one before calling start." userInfo:nil];
			return;
		}
		
		if ( self.motionManager.deviceMotionAvailable ) {
			CMDeviceMotionHandler motionHandler = ^(CMDeviceMotion *motion, NSError *error) {
				if ( !error )
					[self appendMotionSampleForSynchronization:motion];
				else
					NSLog(@"%@", error);
			};
			
			[self.motionManager startDeviceMotionUpdatesToQueue:self.motionQueue withHandler:motionHandler];
		}
	}
}

- (void)stop
{
	if ( self.motionManager.deviceMotionActive ) {
		[self.motionManager stopDeviceMotionUpdates]; // no new blocks will be enqueued to self.motionQueue
		[self.motionQueue addOperationWithBlock:^{
			@synchronized(self) {
				[self.motionSamples removeAllObjects];
			}
		}];
		@synchronized(self) {
			[self.mediaSamples removeAllObjects];
		}
	}
}

- (int)motionRate
{
	int motionHz = 1.0 / self.motionManager.deviceMotionUpdateInterval;
	return motionHz;
}

- (void)setMotionRate:(int)motionRate
{
	NSTimeInterval updateIntervalSeconds = 1.0 / motionRate;
	[self.motionManager setDeviceMotionUpdateInterval:updateIntervalSeconds];
}

- (void)outputSampleBuffer:(CMSampleBufferRef)sampleBuffer withSynchronizedMotionSample:(CMDeviceMotion *)motion
{
	CFRetain(sampleBuffer);
	dispatch_async(_delegateCallbackQueue, ^{
		@autoreleasepool {
			[_delegate motionSynchronizer:self didOutputSampleBuffer:sampleBuffer withMotion:motion];
			CFRelease(sampleBuffer);
		}
	});
}

/*
 Outputs media samples with synchronized motion samples
 
 The media and motion arrays function like queues, with newer samples toward the end of the array. For each media sample, starting with the oldest, we look for the motion sample with the closest possible timestamp.
 
 We output a media sample in two cases:
 1) The difference between media sample and motion sample timestamps are getting larger, indicating that we've found the closest possible motion sample for a media sample.
 2) The media array has grown too large, in which case we sync with the closest motion sample we've found so far.
 */
- (void)sync
{
	int mediaIndex;
	int lastSyncedMediaIndex = -1;

	for ( mediaIndex = 0; mediaIndex < [self.mediaSamples count]; mediaIndex++ ) {
		CMSampleBufferRef mediaSample = (CMSampleBufferRef)[self.mediaSamples objectAtIndex:mediaIndex];
		CFDictionaryRef mediaTimeDict = CMGetAttachment(mediaSample, VIDEOSNAKE_REMAPPED_PTS, NULL);
		CMTime mediaTime = (mediaTimeDict) ? CMTimeMakeFromDictionary(mediaTimeDict) : CMSampleBufferGetPresentationTimeStamp(mediaSample);
		double mediaTimeSeconds = CMTimeGetSeconds(mediaTime);
		double closestDifference = DBL_MAX;
		int motionIndex;
		int closestMotionIndex = 0;
		
		for ( motionIndex = 0; motionIndex < [self.motionSamples count]; motionIndex++ ) {
			CMDeviceMotion *motionSample = [self.motionSamples objectAtIndex:motionIndex];
			double motionTimeSeconds = [motionSample timestamp];
			double difference = fabs(mediaTimeSeconds - motionTimeSeconds);
			if ( difference > closestDifference ) {
				// Sync as soon as the timestamp difference begins to increase
				[self outputSampleBuffer:mediaSample withSynchronizedMotionSample:[self.motionSamples objectAtIndex:closestMotionIndex]];
				lastSyncedMediaIndex = mediaIndex;				
				break;
			}
			else {
				closestDifference = difference;
				closestMotionIndex = motionIndex;
			}
		}

		// If we haven't yet found the closest motion sample for this media sample, but the media array is too large, just sync with the closest motion sample we've seen so far
		if ( lastSyncedMediaIndex < mediaIndex && [self.mediaSamples count] > MEDIA_ARRAY_SIZE ) {
			[self outputSampleBuffer:mediaSample withSynchronizedMotionSample:(closestMotionIndex < [self.motionSamples count]) ? [self.motionSamples objectAtIndex:closestMotionIndex] : nil];
			lastSyncedMediaIndex = mediaIndex;
		}

		// If we synced this media sample with a motion sample, we won't need the motion samples that are older than the one we used; remove them
		if ( lastSyncedMediaIndex == mediaIndex && [self.motionSamples count] > 0 ) {
			[self.motionSamples removeObjectsInRange:NSMakeRange(0, closestMotionIndex)];
		}
	}
	
	// Remove synced media samples
	if ( lastSyncedMediaIndex >= 0 ) {
		[self.mediaSamples removeObjectsInRange:NSMakeRange(0, lastSyncedMediaIndex + 1)];
	}
	
	// If the motion array is too large, remove the oldest motion samples
	if ( [self.motionSamples count] > MOTION_ARRAY_SIZE ) {
		[self.motionSamples removeObjectsInRange:NSMakeRange(0, [self.motionSamples count] - MOTION_ARRAY_SIZE)];
	}
}

- (void)appendMotionSampleForSynchronization:(CMDeviceMotion*)motion
{
	@synchronized(self) {
		[self.motionSamples addObject:motion];
		[self sync];
	}
}

- (void)appendSampleBufferForSynchronization:(CMSampleBufferRef)sampleBuffer
{
	// Convert media timestamp to motion clock if necessary (i.e. we're recording audio, so media timestamps have been synced to the audio clock)
	if ( self.sampleBufferClock && self.motionClock ) {
		if ( !CFEqual(self.sampleBufferClock, self.motionClock) ) {
			[self convertSampleBufferTimeToMotionClock:sampleBuffer];
		}
	}
	
	@synchronized(self) {
		[self.mediaSamples addObject:(id)sampleBuffer];
		[self sync];
	}
}

- (void)setSynchronizedSampleBufferDelegate:(id<MotionSynchronizationDelegate>)sampleBufferDelegate queue:(dispatch_queue_t)sampleBufferCallbackQueue
{
	_delegate = sampleBufferDelegate;
	
	if ( sampleBufferCallbackQueue != _delegateCallbackQueue ) {
		dispatch_queue_t oldQueue = _delegateCallbackQueue;
		_delegateCallbackQueue = sampleBufferCallbackQueue;
		
		if (sampleBufferCallbackQueue)
			[sampleBufferCallbackQueue retain];
		if (oldQueue)
			[oldQueue release];
	}
}

- (void)convertSampleBufferTimeToMotionClock:(CMSampleBufferRef)sampleBuffer
{
	CMTime originalPTS = CMSampleBufferGetPresentationTimeStamp(sampleBuffer);
	CMTime remappedPTS = CMSyncConvertTime(originalPTS, self.sampleBufferClock, self.motionClock);

	// Attach the remapped timestamp to the buffer for use in -sync
	CFDictionaryRef remappedPTSDict = CMTimeCopyAsDictionary(remappedPTS, kCFAllocatorDefault);
	CMSetAttachment(sampleBuffer, VIDEOSNAKE_REMAPPED_PTS, remappedPTSDict, kCMAttachmentMode_ShouldPropagate);

	CFRelease(remappedPTSDict);
}

@end
