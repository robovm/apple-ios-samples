/*
 
 File: CASound.mm
 Abstract: n/a
 Version: 1.3
 
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
 
 Copyright (C) 2010 Apple Inc. All Rights Reserved.
 
 
 */

#import "CASound.h"
#import "libkern/OSAtomic.h"

#import <AudioToolbox/AudioToolbox.h>

NSString* const CASoundFormat_LPCM_8_bit_integer = @"CASoundFormat_LPCM_8_bit_integer";
NSString* const CASoundFormat_LPCM_16_bit_integer = @"CASoundFormat_LPCM_16_bit_integer";
NSString* const CASoundFormat_LPCM_24_bit_integer = @"CASoundFormat_LPCM_24_bit_integer";
NSString* const CASoundFormat_LPCM_32_bit_float = @"CASoundFormat_LPCM_32_bit_float";

static void CASoundAQOutputCallback(
								void *                  inUserData,
								AudioQueueRef           inAQ,
								AudioQueueBufferRef     inBuffer);
								
static void CASoundAQPropertyListenerProc(  
                                    void *                  inUserData,
                                    AudioQueueRef           inAQ,
                                    AudioQueuePropertyID    inID);

static OSStatus CASoundAFReadProc(
								void *		inClientData,
								SInt64		inPosition, 
								UInt32	requestCount, 
								void *		buffer, 
								UInt32 *	actualCount);

static SInt64 CASoundAFGetSizeProc(void * 		inClientData);

enum {
	kNumberOfAudioQueueBuffers = 4
};



struct CASoundImpl
{
    id<CASoundDelegate> _delegate;
	NSData *_data;
	NSURL *_url;

	AudioStreamBasicDescription _asbd;
	AudioFileID _afid;
	AudioQueueRef _queue;
	SInt64 _readPos;
	SInt64 _readStartPos;
	float _volume;

	NSInteger _numLoops;
	NSInteger _loopCount;
	
	bool _wasCued;
	bool _wasStarted;
	bool _isPlaying;
	bool _isSkipping;
	bool _isStopping;
	bool _outOfData;
	double _queueSampleTime;
	double _mediaSampleTime;
	double _queueStartSampleTime;
	double _mediaStartSampleTime;
	double _mediaEndSampleTime;

	bool _enableMetering;
	CASoundLevels* _meters;
	
	// skip mode
	float _playSeconds;
	float _periodLengthSeconds; // negative for rewind
	
	AudioQueueBufferRef _aqbuf[kNumberOfAudioQueueBuffers];
	AudioQueueBufferRef _lastBufferEnqueued;
};

static OSStatus allocAudioQueue(CASound* myself, CASoundImpl* impl)
{
	if (impl->_queue) return noErr;
	
	OSStatus err = AudioQueueNewOutput(&impl->_asbd, CASoundAQOutputCallback, myself, NULL, NULL, 0, &impl->_queue);
	if (err) return err;
	
	if (impl->_enableMetering) {
		UInt32 iflag = true;
		AudioQueueSetProperty(impl->_queue, kAudioQueueProperty_EnableLevelMetering, &iflag, sizeof(iflag));
	}
	
	AudioQueueAddPropertyListener(impl->_queue, kAudioQueueProperty_IsRunning, CASoundAQPropertyListenerProc, myself);
	
	for (UInt32 i = 0; i < kNumberOfAudioQueueBuffers; ++i) {
		err = AudioQueueAllocateBuffer(impl->_queue, 65536, impl->_aqbuf + i);
		if (err) return err;
	}
	
	return err;
}

static OSStatus stopQueue(CASoundImpl* impl)
{
	if (!impl->_wasStarted) 
		return noErr;

	impl->_isStopping = true;
	OSMemoryBarrier(); // make sure _isStopping is written
	OSStatus err = AudioQueueStop(impl->_queue, true);
	impl->_wasStarted = false;
	impl->_isPlaying = false;
	impl->_isSkipping = false;
	impl->_isStopping = false;
	impl->_queueSampleTime = 0.;
	impl->_queueStartSampleTime = 0.;
	impl->_mediaSampleTime = impl->_mediaStartSampleTime;
	impl->_readPos = impl->_readStartPos;
	OSMemoryBarrier();
	return err;
}

static OSStatus disposeQueue(CASound* myself, CASoundImpl* impl)
{
	if (!impl->_queue) 
		return noErr;
	
	AudioQueueRemovePropertyListener(impl->_queue, kAudioQueueProperty_IsRunning, CASoundAQPropertyListenerProc, myself);
	impl->_isStopping = true;
	OSMemoryBarrier(); // make sure _isStopping is written
	OSStatus err = AudioQueueDispose(impl->_queue, true);
	impl->_queue = NULL;
	impl->_wasStarted = false;
	impl->_isPlaying = false;
	impl->_isSkipping = false;
	impl->_isStopping = false;
	impl->_queueSampleTime = 0.;
	impl->_queueStartSampleTime = 0.;
	impl->_mediaSampleTime = impl->_mediaStartSampleTime;
	impl->_readPos = impl->_readStartPos;
	OSMemoryBarrier();
	return err;
}

static double getQueueTime(CASoundImpl* impl)
{
	AudioTimeStamp timeStamp;
	OSStatus err = AudioQueueGetCurrentTime(impl->_queue, NULL, &timeStamp, NULL);
	if (err) 
		return impl->_queueSampleTime; // last known position
	return impl->_queueSampleTime = timeStamp.mSampleTime;
}

@implementation CASound

+ (CASound*)soundWithContentsOfURL:(NSURL *)url
{
	return [[CASound alloc] initWithContentsOfURL: url];
}

+ (CASound*)soundWithContentsOfFile:(NSString *)path
{
	return [[CASound alloc] initWithContentsOfFile: path];
}

+ (CASound*)soundWithData:(NSData *)data
{
	return [[CASound alloc] initWithData: data];
}

+ (CASound*)soundWithDataCallback:(CASoundDataCallback)aCallback userData:(void*) clientPtr
{
	return [[CASound alloc] initWithDataCallback: aCallback userData: clientPtr];
}


- (CASoundImpl*)impl
{
	return (CASoundImpl*)_impl;
}


- (void)finalize
{
	@synchronized(self) {
		CASoundImpl* impl = (CASoundImpl*)_impl;
		disposeQueue(self, impl);
		if (impl->_afid) AudioFileClose(impl->_afid);
		free(impl->_meters);
		free(_impl);
	}
	[super finalize];
}

- (void)dealloc
{
	@synchronized(self) {
		CASoundImpl* impl = (CASoundImpl*)_impl;
		disposeQueue(self, impl);
		if (impl->_afid) AudioFileClose(impl->_afid);
		free(impl->_meters);
		[impl->_data release];
		[impl->_url release];
		[impl->_delegate release];
		free(_impl);
	}
	[super dealloc];
}

- (id)baseInit
{
#if TARGET_OS_IPHONE
	_impl = calloc(1, sizeof(CASoundImpl));
#else
	_impl = NSAllocateCollectable(sizeof(CASoundImpl), NSScannedOption);
	memset(_impl, 0, sizeof(CASoundImpl));
#endif
	CASoundImpl* impl = (CASoundImpl*)_impl;

	impl->_mediaEndSampleTime = 1e100;
	impl->_volume = 1.0;

	return self;
}

- (CASound*)initWithSound:(CASound *)other
{
	CASoundImpl* otherImpl = (CASoundImpl*)other->_impl;

	if (otherImpl->_url) {
		return [self initWithContentsOfURL: otherImpl->_url];
	} else if (otherImpl->_data) {
		return [self initWithData: otherImpl->_data];
	} else {
		return NULL;
	}
}

/* support NSCopying */
- (id)copyWithZone:(NSZone *)zone
{
	CASound* copy = NSCopyObject(self, 0, zone);
	
	copy->_impl = NULL;
	[copy initWithSound: self];
	return copy;
}

- (CASound*)initWithContentsOfURL:(NSURL *)nsurl
{
	[self baseInit];
	
	CASoundImpl* impl = (CASoundImpl*)_impl;
	const CFURLRef cfurl = (const CFURLRef)nsurl;
	OSStatus err = AudioFileOpenURL(cfurl, kAudioFileReadPermission, 0, &impl->_afid);
	if (err) {
//		NSException *exception = [NSException exceptionWithName:@"AudioFileOpenURL failed" 
//			reason:@"AudioFileOpenURL failed" userInfo:nil]; 
//		@throw exception; 
		return NULL;
	}
	impl->_url = nsurl;
	[nsurl retain];

	UInt32 propSize = sizeof(AudioStreamBasicDescription);
	AudioFileGetProperty(impl->_afid, kAudioFilePropertyDataFormat, &propSize, &impl->_asbd);

	return self;
}

- (CASound*)initWithContentsOfFile:(NSString *)path
{
	NSURL* url = [[NSURL alloc] initFileURLWithPath: path];
	id result = [self initWithContentsOfURL: url];
	[url release];
	return result;
}

- (CASound*)initWithData:(NSData *)data
{
	[self baseInit];

	CASoundImpl* impl = (CASoundImpl*)_impl;
	impl->_data = data;
	[impl->_data retain];
	
	OSStatus err = AudioFileOpenWithCallbacks(self, CASoundAFReadProc, NULL, CASoundAFGetSizeProc, NULL, 0, &impl->_afid);
	if (err) {
		return NULL;
	}
	return self;
}

- (CASound*)initWithDataCallback:(CASoundDataCallback)aCallback userData:(void*) userData
{
	return NULL;
}

//
//// Pasteboard support
//+ (BOOL)canInitWithPasteboard:(NSPasteboard *)pasteboard
//{
//	return NO;
//}
//
//+ (NSArray*)soundUnfilteredTypes
//{
//	return NULL;
//}
//
//
//- (id)initWithPasteboard:(NSPasteboard *)pasteboard
//{
//	return NULL;
//}
//
//- (void)writeToPasteboard:(NSPasteboard *)pasteboard
//{
//}


// Sound operations
- (BOOL)prepareForPlay
{
	@synchronized(self) {
		CASoundImpl* impl = (CASoundImpl*)_impl;
		OSStatus err = allocAudioQueue(self, impl);
		if (err) return NO;
		
		if (impl->_wasStarted) return YES;
		if (impl->_wasCued) return NO;
		impl->_outOfData = false;
		impl->_lastBufferEnqueued = NULL;
		for (int i = 0; i < kNumberOfAudioQueueBuffers; ++i) {
			CASoundAQOutputCallback(self, impl->_queue, impl->_aqbuf[i]);
		}
		impl->_wasCued = true;
	}
	return YES;
}

//- (BOOL)resume
//{
//	return [self play];
//}

- (BOOL)play
{
	OSStatus err = noErr;
	@synchronized(self) {
		CASoundImpl* impl = (CASoundImpl*)_impl;
		if (impl->_isPlaying) 
			return NO;

		[self prepareForPlay];
		if (impl->_wasStarted) {
			// find out where we left off last time.
			double prevQueueStartTime = impl->_queueStartSampleTime;
			double queueTime = getQueueTime(impl);
			impl->_queueStartSampleTime = queueTime;
			impl->_mediaSampleTime += queueTime - prevQueueStartTime;
		} else {
			impl->_mediaSampleTime = impl->_mediaStartSampleTime;
		}
		impl->_wasStarted = true;
		impl->_isPlaying = true;
		impl->_isSkipping = false;
		impl->_wasCued = false;
		impl->_loopCount = 0;
		/* err =*/ AudioQueueSetParameter(impl->_queue, kAudioQueueParam_Volume, impl->_volume);
		err = AudioQueueStart(impl->_queue, NULL);
	}
	return err == noErr;
}

- (BOOL)skipForwardPlaying:(NSTimeInterval)playSeconds ofEvery:(NSTimeInterval)periodSeconds;
{
	/* skipping style fast forward mode */
	OSStatus err = noErr;
	@synchronized(self) {
		CASoundImpl* impl = (CASoundImpl*)_impl;
		impl->_isSkipping = true;
		impl->_playSeconds = playSeconds;
		impl->_periodLengthSeconds = periodSeconds;
		
	}
	return err == noErr;
}

- (BOOL)skipBackwardPlaying:(NSTimeInterval)playSeconds ofEvery:(NSTimeInterval)periodSeconds
{
	/* skipping style fast reverse mode */
	OSStatus err = noErr;
	@synchronized(self) {
		CASoundImpl* impl = (CASoundImpl*)_impl;
		impl->_isSkipping = true;
		impl->_playSeconds = playSeconds;
		impl->_periodLengthSeconds = -periodSeconds;
		
	}
	return err == noErr;
}

- (BOOL)pause
{
	OSStatus err = noErr;
	@synchronized(self) {
		CASoundImpl* impl = (CASoundImpl*)_impl;
		if (impl->_isPlaying) {
			err = AudioQueuePause(impl->_queue);
			impl->_isPlaying = false;
			impl->_isSkipping = false;
		}
	}
	return err == noErr;
}


- (BOOL)stop
{
	OSStatus err = noErr;
	@synchronized(self) {
		CASoundImpl* impl = (CASoundImpl*)_impl;
		if (impl->_wasStarted) {
			err = disposeQueue(self, impl);
		}
	}
	return err == noErr;
}

@dynamic isPlaying;

- (BOOL)isPlaying
{
	CASoundImpl* impl = (CASoundImpl*)_impl;
	return impl->_isPlaying ? YES : NO;
}

@dynamic delegate;

- (id <CASoundDelegate>)delegate
{
	CASoundImpl* impl = (CASoundImpl*)_impl;
	return impl->_delegate;
}

- (void)setDelegate:(id <CASoundDelegate>)aDelegate
{
	CASoundImpl* impl = (CASoundImpl*)_impl;
	if (aDelegate == impl->_delegate) return;
	id prev = impl->_delegate;
	impl->_delegate = aDelegate;
	[impl->_delegate retain];
	[prev release];
}

/* Returns the duration of the sound in seconds.
*/
- (NSTimeInterval)duration
{
	CASoundImpl* impl = (CASoundImpl*)_impl;
	NSTimeInterval dur = 0.;
	if (impl->_afid) {
		Float64 durf;
		UInt32 propSize = sizeof(durf);
		/*OSStatus err =*/ AudioFileGetProperty(impl->_afid, kAudioFilePropertyEstimatedDuration, &propSize, &dur);
	}
	return dur;
}

@dynamic volume;

/* Sets and gets the volume for the sound without affecting the system-wide volume. The valid range is between 0. and 1., inclusive.
*/
- (void)setVolume:(float)volume
{
	CASoundImpl* impl = (CASoundImpl*)_impl;
	impl->_volume = volume;
	@synchronized(self) {
		if (impl->_queue) {
			/*OSStatus err =*/ AudioQueueSetParameter(impl->_queue, kAudioQueueParam_Volume, impl->_volume);
		}
	}
}

- (float)volume
{
	return ((CASoundImpl*)_impl)->_volume;
}

@dynamic sampleRate, channelCount, formatID, bitratePerChannel;

- (double)sampleRate
{	
	return ((CASoundImpl*)_impl)->_asbd.mSampleRate;
}

- (NSUInteger)channelCount
{
	return ((CASoundImpl*)_impl)->_asbd.mChannelsPerFrame;
}

- (NSString*)formatID
{
	CASoundImpl* impl = (CASoundImpl*)_impl;
	UInt32 fid = impl->_asbd.mFormatID;
	if (fid == kAudioFormatLinearPCM) {
		bool isFloat = impl->_asbd.mFormatFlags & kAudioFormatFlagIsFloat;
		UInt32 bitDepth = impl->_asbd.mBitsPerChannel;
		if (isFloat && bitDepth == 32) {
			return CASoundFormat_LPCM_32_bit_float;
		} else {
			switch (bitDepth) {
				case 8 : return CASoundFormat_LPCM_8_bit_integer;
				case 16 : return CASoundFormat_LPCM_16_bit_integer;
				case 24 : return CASoundFormat_LPCM_24_bit_integer;
			}
		}
	}

	char sfid[6];
	sfid[0] = (fid >> 24) & 255;
	sfid[1] = (fid >> 16) & 255;
	sfid[2] = (fid >>  8) & 255;
	sfid[3] = (fid >>  0) & 255;
	sfid[4] = 0;
	
	return [NSString stringWithUTF8String: sfid];
}

- (NSUInteger)bitratePerChannel
{
	CASoundImpl* impl = (CASoundImpl*)_impl;
	UInt32 numChannels = impl->_asbd.mSampleRate;
	UInt32 bitRate = 0;
	UInt32 propSize = sizeof(bitRate);
	
	if (impl->_afid) {
		AudioFileGetProperty(impl->_afid, kAudioFilePropertyBitRate, &propSize, &bitRate);
	}
	
	return bitRate / numChannels;
}


@dynamic currentTime;

/* If the sound is playing, currentTime returns the number of  seconds into the sound where playing is occurring.  If the sound is not playing, currentTime returns the number of seconds into the sound where playing would start.
*/
- (NSTimeInterval)currentTime
{
	CASoundImpl* impl = (CASoundImpl*)_impl;
	NSTimeInterval time = 0.;
	@synchronized(self) 
	{		
		if (impl->_wasStarted) {
			double queueTime = getQueueTime(impl);
			time = (queueTime + impl->_mediaStartSampleTime) / impl->_asbd.mSampleRate;
		} else {
			time =  impl->_mediaSampleTime / impl->_asbd.mSampleRate;
		}
	}
	return time;
}


/* Sets the location of the currently playing audio to seconds. If the sound is not playing, this sets the number of seconds into the sound where playing would begin. The currentTime is not archived, copied, or stored on the pasteboard - all new sounds start with a currentTime of 0.
*/
- (void)setCurrentTime:(NSTimeInterval)seconds
{
	CASoundImpl* impl = (CASoundImpl*)_impl;
	@synchronized(self) {
		double packetsPerSecond = impl->_asbd.mSampleRate / impl->_asbd.mFramesPerPacket;
		impl->_readStartPos = (SInt64)floor(seconds * packetsPerSecond + .5);
		impl->_readPos = impl->_readStartPos;
		impl->_mediaStartSampleTime = impl->_readPos * impl->_asbd.mFramesPerPacket;
		if (impl->_wasStarted || impl->_wasCued) {
			if (impl->_isPlaying) {
				stopQueue(impl);
			} else {
//				impl->_isStopping = true;
//				OSMemoryBarrier();
				AudioQueueReset(impl->_queue);
//				impl->_isStopping = false;
			}
			impl->_wasStarted = false;
		}
		[self play];
	}
}

@dynamic numberOfLoops;

/* Sets whether the sound should automatically restart when it is finished playing.  If the sound is currently playing, this takes effect immediately. The default is NO.  A looping sound does not send soundDidFinishPlaying: to its delegate unless it is sent a stop message.
*/
- (void)setNumberOfLoops:(NSInteger)numLoops
{
	CASoundImpl* impl = (CASoundImpl*)_impl;
	impl->_numLoops = numLoops;		
}

/* Returns whether the sound will automatically restart when it is finished playing. */
- (NSInteger)numberOfLoops
{
	CASoundImpl* impl = (CASoundImpl*)_impl;
	return impl->_numLoops;
}


- (NSData*)data
{
	CASoundImpl* impl = (CASoundImpl*)_impl;
	return impl->_data;
}

- (void)queue: (AudioQueueRef)inAQ propertyID: (AudioQueuePropertyID)inID
{

	if (inID == kAudioQueueProperty_IsRunning) {
//		CASoundImpl* impl = (CASoundImpl*)_impl;
//		UInt32 isRunning = 0;
//		UInt32 propSize = sizeof(isRunning);
//		OSStatus err = AudioQueueGetProperty(inAQ, inID, &isRunning, &propSize);
//		if (err) return;
//		if (isRunning) 
//		{
//			AudioTimeStamp timeStamp;
//			OSStatus err = AudioQueueGetCurrentTime(impl->_queue, NULL, &timeStamp, NULL);
//		}
	}
}

- (void)queue: (AudioQueueRef)inAQ buffer: (AudioQueueBufferRef)inBuffer
{
	CASoundImpl* impl = (CASoundImpl*)_impl;
	if (impl->_isStopping) 
		return;
	
	if (impl->_outOfData && impl->_lastBufferEnqueued == inBuffer) {	
		impl->_outOfData = false;
		impl->_lastBufferEnqueued = NULL;
		if (impl->_numLoops < 0) {
			impl->_readPos = impl->_readStartPos;
		} else {
			stopQueue(impl);
			if (impl->_delegate) {
				[impl->_delegate soundDidFinishPlaying: self];
			}
			return;
		}
	}
	
	if (impl->_asbd.mBytesPerPacket) {
		UInt32 bytesToFill = inBuffer->mAudioDataBytesCapacity;
		UInt32 packetsToFill = inBuffer->mAudioDataBytesCapacity / impl->_asbd.mBytesPerPacket;
		UInt8* fillPtr = (UInt8*)inBuffer->mAudioData;
		UInt32 bytesFilled = 0;
		
		while (true) {
		
			UInt32 ioNumBytes = bytesToFill;
			UInt32 ioNumPackets = packetsToFill;
			OSStatus err = AudioFileReadPackets(impl->_afid, false, &ioNumBytes, NULL, impl->_readPos, &ioNumPackets, fillPtr);
			if (err) 
				return;
		
			fillPtr += ioNumBytes;
			bytesFilled += ioNumBytes;
			bytesToFill -= ioNumBytes;
			packetsToFill -= ioNumPackets;
			impl->_readPos += ioNumPackets;
			
			if (packetsToFill != 0) {
				if (impl->_numLoops < 0 || impl->_loopCount+1 < impl->_numLoops) {
					impl->_loopCount++;
					if (impl->_readPos == impl->_readStartPos) {
						// we read zero bytes even though we're at the beginning of the loop.
						// we have to break out otherwise it is an infinite loop.
						break;
					}
					impl->_readPos = impl->_readStartPos;
				} else {
					impl->_outOfData = true;
					impl->_mediaEndSampleTime = impl->_readPos * impl->_asbd.mFramesPerPacket;
					break;
				}
			} else {
				break;
			}			
		}
		
		if (bytesFilled) {
			inBuffer->mAudioDataByteSize = bytesFilled;
			impl->_lastBufferEnqueued = inBuffer;
			/*OSStatus err =*/ AudioQueueEnqueueBuffer(impl->_queue, inBuffer, 0, NULL);
		}

	} else {
	
		const size_t kNumPacketDescs = 512;
		AudioStreamPacketDescription descs[kNumPacketDescs];
		UInt32 ioNumBytes = inBuffer->mAudioDataBytesCapacity;
		UInt32 ioNumPackets = kNumPacketDescs;
		OSStatus err = AudioFileReadPackets(impl->_afid, false, &ioNumBytes, descs, impl->_readPos, &ioNumPackets, inBuffer->mAudioData);
		if (err) 
			return;
		
		impl->_readPos += ioNumPackets;
		inBuffer->mAudioDataByteSize = ioNumBytes;

		if (ioNumPackets) {
			impl->_lastBufferEnqueued = inBuffer;
			err = AudioQueueEnqueueBuffer(impl->_queue, inBuffer, ioNumPackets, descs);
		} else {
			impl->_outOfData = true;
			impl->_mediaEndSampleTime = impl->_readPos * impl->_asbd.mFramesPerPacket;
		}
	}
}

@dynamic enableMetering;

- (BOOL)enableMetering
{
	CASoundImpl* impl = (CASoundImpl*)_impl;
	return impl->_enableMetering;
}

/* turns level metering ON or OFF */
- (void)setEnableMetering:(BOOL)flag
{
	@synchronized(self) {
		CASoundImpl* impl = (CASoundImpl*)_impl;
		impl->_enableMetering = flag;
		if (impl->_queue) {
			UInt32 iflag = flag;
			AudioQueueSetProperty(impl->_queue, kAudioQueueProperty_EnableLevelMetering, &iflag, sizeof(iflag));
		}
	}
}

@dynamic meters;

- (CASoundLevels*)meters
{
	CASoundLevels* result = NULL;
	@synchronized(self) {
		CASoundImpl* impl = (CASoundImpl*)_impl;
		UInt32 numChannels = impl->_asbd.mChannelsPerFrame;
		if (!impl->_meters) {
			impl->_meters = (CASoundLevels*)calloc(numChannels, sizeof(CASoundLevels));
		}
		if (impl->_queue && impl->_enableMetering) {
			UInt32 propSize = sizeof(CASoundLevels) * numChannels;
			OSStatus err = AudioQueueGetProperty(impl->_queue, kAudioQueueProperty_CurrentLevelMeterDB, impl->_meters, &propSize);
			if (err) {
				memset(impl->_meters, 0, sizeof(float) * numChannels);
			}
		} else {
			memset(impl->_meters, 0, sizeof(float) * numChannels);
		}
		result = impl->_meters;
	}
	return result;
}


@end


static void CASoundAQPropertyListenerProc(  
                                    void *                  inUserData,
                                    AudioQueueRef           inAQ,
                                    AudioQueuePropertyID    inID)
{
	CASound* sound = (CASound*)inUserData;
	[sound queue: inAQ propertyID: inID];
	
}


static void CASoundAQOutputCallback(
								void *                  inUserData,
								AudioQueueRef           inAQ,
								AudioQueueBufferRef     inBuffer)
{
	CASound* sound = (CASound*)inUserData;
	[sound queue: inAQ buffer: inBuffer];
}

static OSStatus CASoundAFReadProc(
								void *		inClientData,
								SInt64		inPosition, 
								UInt32	requestCount, 
								void *		buffer, 
								UInt32 *	actualCount)
{
	CASound* sound = (CASound*)inClientData;
	NSData* data = [sound data];
	if (!data) {
		*actualCount = 0;
		return -50/*paramErr*/;
	}
	
	SInt64 length = [data length];
	if (requestCount > length) 
		requestCount = length;		

	NSRange range;
	range.location = inPosition;
	range.length = requestCount;

	[data getBytes: buffer range: range];
	
	*actualCount = requestCount;
	
	return noErr;
}

static SInt64 CASoundAFGetSizeProc(void * 		inClientData)
{
	CASound* sound = (CASound*)inClientData;
	NSData* data = [sound data];
	if (!data) return 0;
	return [data length];
}

