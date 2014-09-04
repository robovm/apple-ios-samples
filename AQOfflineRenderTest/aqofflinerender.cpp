/*
    File: aqofflinerender.cpp
Abstract: Demonstrates the use of AudioQueueOfflineRender
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

Copyright (C) 2009 Apple Inc. All Rights Reserved.

*/

// standard includes
#include <AudioToolbox/AudioQueue.h>
#include <AudioToolbox/AudioFile.h>
#include <AudioToolbox/ExtendedAudioFile.h>

// helpers
#include "CAXException.h"
#include "CAStreamBasicDescription.h"

// the application specific info we keep track of
struct AQTestInfo
{
	AudioFileID						mAudioFile;
	CAStreamBasicDescription		mDataFormat;
	AudioQueueRef					mQueue;
	AudioQueueBufferRef				mBuffer;
	SInt64							mCurrentPacket;
	UInt32							mNumPacketsToRead;
	AudioStreamPacketDescription    *mPacketDescs;
	bool							mFlushed;
	bool							mDone;
};

#pragma mark- Helper Functions
// ***********************
// CalculateBytesForTime Utility Function

	// we only use time here as a guideline
	// we are really trying to get somewhere between 16K and 64K buffers, but not allocate too much if we don't need it
void CalculateBytesForTime (CAStreamBasicDescription & inDesc, UInt32 inMaxPacketSize, Float64 inSeconds, UInt32 *outBufferSize, UInt32 *outNumPackets)
{
	static const int maxBufferSize = 0x10000;   // limit size to 64K
	static const int minBufferSize = 0x4000;    // limit size to 16K

	if (inDesc.mFramesPerPacket) {
		Float64 numPacketsForTime = inDesc.mSampleRate / inDesc.mFramesPerPacket * inSeconds;
		*outBufferSize = numPacketsForTime * inMaxPacketSize;
	} else {
		// if frames per packet is zero, then the codec has no predictable packet == time
		// so we can't tailor this (we don't know how many Packets represent a time period
		// we'll just return a default buffer size
		*outBufferSize = maxBufferSize > inMaxPacketSize ? maxBufferSize : inMaxPacketSize;
	}
	
		// we're going to limit our size to our default
	if (*outBufferSize > maxBufferSize && *outBufferSize > inMaxPacketSize) {
		*outBufferSize = maxBufferSize;
	} else {
		// also make sure we're not too small - we don't want to go the disk for too small chunks
		if (*outBufferSize < minBufferSize) {
			*outBufferSize = minBufferSize;
        }
	}
    
	*outNumPackets = *outBufferSize / inMaxPacketSize;
}

#pragma mark- AQOutputCallback
// ***********************
// AudioQueueOutputCallback function used to push data into the audio queue

static void AQTestBufferCallback(void *inUserData, AudioQueueRef inAQ, AudioQueueBufferRef inCompleteAQBuffer) 
{
	AQTestInfo * myInfo = (AQTestInfo *)inUserData;
	if (myInfo->mDone) return;
		
	UInt32 numBytes;
	UInt32 nPackets = myInfo->mNumPacketsToRead;
	OSStatus result = AudioFileReadPackets(myInfo->mAudioFile,      // The audio file from which packets of audio data are to be read.
                                           false,                   // Set to true to cache the data. Otherwise, set to false.
                                           &numBytes,               // On output, a pointer to the number of bytes actually returned.
                                           myInfo->mPacketDescs,    // A pointer to an array of packet descriptions that have been allocated.
                                           myInfo->mCurrentPacket,  // The packet index of the first packet you want to be returned.
                                           &nPackets,               // On input, a pointer to the number of packets to read. On output, the number of packets actually read.
                                           inCompleteAQBuffer->mAudioData); // A pointer to user-allocated memory.
	if (result) {
		DebugMessageN1 ("Error reading from file: %d\n", (int)result);
		exit(1);
	}
    
    // we have some data
	if (nPackets > 0) {
		inCompleteAQBuffer->mAudioDataByteSize = numBytes;
        
		result = AudioQueueEnqueueBuffer(inAQ,                                  // The audio queue that owns the audio queue buffer.
                                         inCompleteAQBuffer,                    // The audio queue buffer to add to the buffer queue.
                                         (myInfo->mPacketDescs ? nPackets : 0), // The number of packets of audio data in the inBuffer parameter. See Docs.
                                         myInfo->mPacketDescs);                 // An array of packet descriptions. Or NULL. See Docs.
		if (result) {
			DebugMessageN1 ("Error enqueuing buffer: %d\n", (int)result);
			exit(1);
		}
        
		myInfo->mCurrentPacket += nPackets;
        
	} else {
        // **** This ensures that we flush the queue when done -- ensures you get all the data out ****
		
        if (!myInfo->mFlushed) {
			result = AudioQueueFlush(myInfo->mQueue);
			
            if (result) {
				DebugMessageN1("AudioQueueFlush failed: %d", (int)result);
				exit(1);
			}
            
			myInfo->mFlushed = true;
		}
		
		result = AudioQueueStop(myInfo->mQueue, false);
		if (result) {
			DebugMessageN1("AudioQueueStop(false) failed: %d", (int)result);
			exit(1);
		}
        
		// reading nPackets == 0 is our EOF condition
		myInfo->mDone = true;
	}
}

// ***********************
#pragma mark- Main Render Function

void DoAQOfflineRender(CFURLRef sourceURL, CFURLRef destinationURL) 
{
    // main audio queue code
	try {
		AQTestInfo myInfo;
        
		myInfo.mDone = false;
		myInfo.mFlushed = false;
		myInfo.mCurrentPacket = 0;
		
        // get the source file
        XThrowIfError(AudioFileOpenURL(sourceURL, 0x01/*fsRdPerm*/, 0/*inFileTypeHint*/, &myInfo.mAudioFile), "AudioFileOpen failed");
			
		UInt32 size = sizeof(myInfo.mDataFormat);
		XThrowIfError(AudioFileGetProperty(myInfo.mAudioFile, kAudioFilePropertyDataFormat, &size, &myInfo.mDataFormat), "couldn't get file's data format");
		
		printf ("File format: "); myInfo.mDataFormat.Print();

        // create a new audio queue output
		XThrowIfError(AudioQueueNewOutput(&myInfo.mDataFormat,      // The data format of the audio to play. For linear PCM, only interleaved formats are supported.
                                          AQTestBufferCallback,     // A callback function to use with the playback audio queue.
                                          &myInfo,                  // A custom data structure for use with the callback function.
                                          CFRunLoopGetCurrent(),    // The event loop on which the callback function pointed to by the inCallbackProc parameter is to be called.
                                                                    // If you specify NULL, the callback is invoked on one of the audio queue’s internal threads.
                                          kCFRunLoopCommonModes,    // The run loop mode in which to invoke the callback function specified in the inCallbackProc parameter. 
                                          0,                        // Reserved for future use. Must be 0.
                                          &myInfo.mQueue),          // On output, the newly created playback audio queue object.
                                          "AudioQueueNew failed");

		UInt32 bufferByteSize;
		
		// we need to calculate how many packets we read at a time and how big a buffer we need
		// we base this on the size of the packets in the file and an approximate duration for each buffer
		{
			bool isFormatVBR = (myInfo.mDataFormat.mBytesPerPacket == 0 || myInfo.mDataFormat.mFramesPerPacket == 0);
			
			// first check to see what the max size of a packet is - if it is bigger
			// than our allocation default size, that needs to become larger
			UInt32 maxPacketSize;
			size = sizeof(maxPacketSize);
			XThrowIfError(AudioFileGetProperty(myInfo.mAudioFile, kAudioFilePropertyPacketSizeUpperBound, &size, &maxPacketSize), "couldn't get file's max packet size");
			
			// adjust buffer size to represent about a second of audio based on this format
			CalculateBytesForTime(myInfo.mDataFormat, maxPacketSize, 1.0/*seconds*/, &bufferByteSize, &myInfo.mNumPacketsToRead);
			
			if (isFormatVBR) {
				myInfo.mPacketDescs = new AudioStreamPacketDescription [myInfo.mNumPacketsToRead];
			} else {
				myInfo.mPacketDescs = NULL; // we don't provide packet descriptions for constant bit rate formats (like linear PCM)
            }
				
			printf ("Buffer Byte Size: %d, Num Packets to Read: %d\n", (int)bufferByteSize, (int)myInfo.mNumPacketsToRead);
		}

		// if the file has a magic cookie, we should get it and set it on the AQ
		size = sizeof(UInt32);
		OSStatus result = AudioFileGetPropertyInfo (myInfo.mAudioFile, kAudioFilePropertyMagicCookieData, &size, NULL);

		if (!result && size) {
			char* cookie = new char [size];		
			XThrowIfError (AudioFileGetProperty (myInfo.mAudioFile, kAudioFilePropertyMagicCookieData, &size, cookie), "get cookie from file");
			XThrowIfError (AudioQueueSetProperty(myInfo.mQueue, kAudioQueueProperty_MagicCookie, cookie, size), "set cookie on queue");
			delete [] cookie;
		}

		// channel layout?
		OSStatus err = AudioFileGetPropertyInfo(myInfo.mAudioFile, kAudioFilePropertyChannelLayout, &size, NULL);
		AudioChannelLayout *acl = NULL;
		if (err == noErr && size > 0) {
			acl = (AudioChannelLayout *)malloc(size);
			XThrowIfError(AudioFileGetProperty(myInfo.mAudioFile, kAudioFilePropertyChannelLayout, &size, acl), "get audio file's channel layout");
			XThrowIfError(AudioQueueSetProperty(myInfo.mQueue, kAudioQueueProperty_ChannelLayout, acl, size), "set channel layout on queue");
		}

		//allocate the input read buffer
		XThrowIfError(AudioQueueAllocateBuffer(myInfo.mQueue, bufferByteSize, &myInfo.mBuffer), "AudioQueueAllocateBuffer");

		// prepare a canonical interleaved capture format
		CAStreamBasicDescription captureFormat;
		captureFormat.mSampleRate = myInfo.mDataFormat.mSampleRate;
		captureFormat.SetAUCanonical(myInfo.mDataFormat.mChannelsPerFrame, true); // interleaved
		XThrowIfError(AudioQueueSetOfflineRenderFormat(myInfo.mQueue, &captureFormat, acl), "set offline render format");			
		
		ExtAudioFileRef captureFile;
        
		// prepare a 16-bit int file format, sample channel count and sample rate
		CAStreamBasicDescription dstFormat;
		dstFormat.mSampleRate = myInfo.mDataFormat.mSampleRate;
		dstFormat.mChannelsPerFrame = myInfo.mDataFormat.mChannelsPerFrame;
		dstFormat.mFormatID = kAudioFormatLinearPCM;
		dstFormat.mFormatFlags = kLinearPCMFormatFlagIsPacked | kLinearPCMFormatFlagIsSignedInteger; // little-endian
		dstFormat.mBitsPerChannel = 16;
		dstFormat.mBytesPerPacket = dstFormat.mBytesPerFrame = 2 * dstFormat.mChannelsPerFrame;
		dstFormat.mFramesPerPacket = 1;
		
		// create the capture file
        XThrowIfError(ExtAudioFileCreateWithURL(destinationURL, kAudioFileCAFType, &dstFormat, acl, kAudioFileFlags_EraseFile, &captureFile), "ExtAudioFileCreateWithURL");
		
        // set the capture file's client format to be the canonical format from the queue
		XThrowIfError(ExtAudioFileSetProperty(captureFile, kExtAudioFileProperty_ClientDataFormat, sizeof(AudioStreamBasicDescription), &captureFormat), "set ExtAudioFile client format");
		
		// allocate the capture buffer, just keep it at half the size of the enqueue buffer
        // we don't ever want to pull any faster than we can push data in for render
        // this 2:1 ratio keeps the AQ Offline Render happy
		const UInt32 captureBufferByteSize = bufferByteSize / 2;
		
        AudioQueueBufferRef captureBuffer;
		AudioBufferList captureABL;
		
		XThrowIfError(AudioQueueAllocateBuffer(myInfo.mQueue, captureBufferByteSize, &captureBuffer), "AudioQueueAllocateBuffer");
		
        captureABL.mNumberBuffers = 1;
		captureABL.mBuffers[0].mData = captureBuffer->mAudioData;
		captureABL.mBuffers[0].mNumberChannels = captureFormat.mChannelsPerFrame;

		// lets start playing now - stop is called in the AQTestBufferCallback when there's
		// no more to read from the file
		XThrowIfError(AudioQueueStart(myInfo.mQueue, NULL), "AudioQueueStart failed");

		AudioTimeStamp ts;
		ts.mFlags = kAudioTimeStampSampleTimeValid;
		ts.mSampleTime = 0;

		// we need to call this once asking for 0 frames
		XThrowIfError(AudioQueueOfflineRender(myInfo.mQueue, &ts, captureBuffer, 0), "AudioQueueOfflineRender");

		// we need to enqueue a buffer after the queue has started
		AQTestBufferCallback(&myInfo, myInfo.mQueue, myInfo.mBuffer);

		while (true) {
			UInt32 reqFrames = captureBufferByteSize / captureFormat.mBytesPerFrame;
			
            XThrowIfError(AudioQueueOfflineRender(myInfo.mQueue, &ts, captureBuffer, reqFrames), "AudioQueueOfflineRender");
			
            captureABL.mBuffers[0].mData = captureBuffer->mAudioData;
			captureABL.mBuffers[0].mDataByteSize = captureBuffer->mAudioDataByteSize;
			UInt32 writeFrames = captureABL.mBuffers[0].mDataByteSize / captureFormat.mBytesPerFrame;
			
            printf("t = %.f: AudioQueueOfflineRender:  req %d fr/%d bytes, got %ld fr/%d bytes\n", ts.mSampleTime, (int)reqFrames, (int)captureBufferByteSize, writeFrames, (int)captureABL.mBuffers[0].mDataByteSize);
            
			XThrowIfError(ExtAudioFileWrite(captureFile, writeFrames, &captureABL), "ExtAudioFileWrite");
			
            if (myInfo.mFlushed) break;
			
			ts.mSampleTime += writeFrames;
		}

		CFRunLoopRunInMode(kCFRunLoopDefaultMode, 1, false);

		XThrowIfError(AudioQueueDispose(myInfo.mQueue, true), "AudioQueueDispose(true) failed");
		XThrowIfError(AudioFileClose(myInfo.mAudioFile), "AudioQueueDispose(false) failed");
		XThrowIfError(ExtAudioFileDispose(captureFile), "ExtAudioFileDispose failed");

		if (myInfo.mPacketDescs) delete [] myInfo.mPacketDescs;
		if (acl) free(acl);
	}
	catch (CAXException e) {
		char buf[256];
		fprintf(stderr, "Error: %s (%s)\n", e.mOperation, e.FormatError(buf));
	}
    
    return;
}