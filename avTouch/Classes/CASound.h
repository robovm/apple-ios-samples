/*
 
 File: CASound.h
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

@class NSData, NSURL;
@class CASound;

/* format IDs */
extern NSString* const CASoundFormat_LPCM_8_bit_integer;
extern NSString* const CASoundFormat_LPCM_16_bit_integer;
extern NSString* const CASoundFormat_LPCM_24_bit_integer;
extern NSString* const CASoundFormat_LPCM_32_bit_float;
/* Formats other than linear PCM use four char format IDs from <CoreAudio/CoreAudioTypes.h> converted to a string */

/* constant for the numberOfLoops property */
enum {
	kCASound_LoopForever = -1
};

/* A callback function for soundWithCallback:userData:
   This function called when a new buffer of data is needed. 
        sound - the CASound
        userData - the userData that was supplied to soundWithCallback:userData:
        byteOffset - the byte offset into the data.
        bytesRequested - how many bytes are being requested.
        bytesSupplied - return how many bytes you are supplying. 
                        You may supply less than requested if necessary, but playback may not perform optimally.
                        You may not supply more than requested.
        dataPtr - you will copy your data to the address pointed to by dataPtr.
	
*/
typedef void (*CASoundDataCallback)(
	CASound* sound, 
	void* userData, 
	uint64_t byteOffset,
	NSUInteger bytesRequested, 
	NSUInteger* bytesSupplied, 
	void* dataPtr);

/* A struct for the meters and decibelMeters properties */
typedef struct CASoundLevels {
    float     averagePower;
    float     peakPower;
} CASoundLevels;

/* A protocol for delegates of CASound */
@protocol CASoundDelegate <NSObject>
	- (void)soundDidFinishPlaying:(CASound *)sound;
@end


@interface CASound : NSObject <NSCopying> {
@private
    __strong void* _impl;
}

/* all data must be in the form of an audio file understood by CoreAudio */
+ (CASound*)soundWithContentsOfURL:(NSURL *)url;
+ (CASound*)soundWithData:(NSData *)data;
+ (CASound*)soundWithDataCallback:(CASoundDataCallback)aCallback userData:(void*) userData; /* pull mode */

/* all data must be in the form of an audio file understood by CoreAudio */
- (CASound*)initWithContentsOfURL:(NSURL *)url;
- (CASound*)initWithData:(NSData *)data;
- (CASound*)initWithDataCallback:(CASoundDataCallback)aCallback userData:(void*) userData; /* pull mode */

/* transport control */

- (BOOL)prepareForPlay;	/* get ready to play the sound. happens automatically on play. returns NO if sound failed to load or was called while playing. */
- (BOOL)play;			/* sound is played asynchronously. returns NO if already playing or can't play. */
- (BOOL)skipForwardPlaying:(NSTimeInterval)playSeconds ofEvery:(NSTimeInterval)periodSeconds; /* skipping style fast forward mode */
- (BOOL)skipBackwardPlaying:(NSTimeInterval)playSeconds ofEvery:(NSTimeInterval)periodSeconds; /* skipping style fast reverse mode */
- (BOOL)pause;			/* pauses playback, but remains ready to play. returns NO if sound not paused */
- (BOOL)stop;			/* stops playback. no longer ready to play. */

/* properties */

@property(readonly) BOOL isPlaying;

@property(readonly) NSString* formatID; /* the format ID identifies the data format */
@property(readonly) double sampleRate; 
@property(readonly) NSUInteger channelCount; 
@property(readonly) NSUInteger bitratePerChannel;  /* bits per second per channel. For VBR this will be an average. */
@property(readonly) NSTimeInterval duration; /* the duration of the sound. */

@property(assign) id<CASoundDelegate> delegate; /* the delegate will be sent soundDidFinishPlaying: */ 

@property float volume; /* The volume for the sound. The valid range is between 0. and 1., inclusive. */

/*  If the sound is playing, currentTime is the offset into the sound of the current playback position.  
If the sound is not playing, currentTime is the offset into the sound where playing would start. */
@property NSTimeInterval currentTime;

/* "numberOfLoops" is the number of times that the sound will return to the beginning upon reaching the end. 
A value of zero means to play the sound just once.
A value of one will result in playing the sound twice, and so on..
A negative number will loop indefinitely until stopped.
*/
@property NSInteger numberOfLoops;

/* metering */

@property BOOL enableMetering; /* turns level metering ON or OFF. default is OFF. */

/* gets meter values in decibels. Returns a pointer to an array of CASoundLevels with size equal to channelCount.
The array is owned by the CASound object and its lifetime is the same as that of the CASound object. */
@property(readonly) CASoundLevels* meters;


@end


/*

CASound transport control state transition table

There are 5 transport states:  stopped, cued, playing, skipping, paused

There are 5 events that can change transport state:  cue, play, skip, pause, stop

The syntax for the state transitions is:   current_state + event -> new_state

* means it is a no-op. the operation is redundant or meaningless.

stopped + cue -> cued
stopped + play -> playing
stopped + skip -> skipping
stopped + pause -> stopped*
stopped + stop -> stopped*

cued + cue -> cued*
cued + play -> playing
cued + skip -> skipping
cued + pause -> cued*
cued + stop -> stopped

playing + cue -> playing*
playing + play -> playing*
playing + skip -> skipping
playing + pause -> paused
playing + stop -> stopped

skipping + cue -> skipping*
skipping + play -> playing
skipping + skip -> skipping
skipping + pause -> paused
skipping + stop -> stopped

paused + cue -> paused*
paused + play -> playing
paused + skip -> skipping
paused + pause -> paused*
paused + stop -> stopped

*/

