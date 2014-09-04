/*
     File: APLSimpleEditor.m
 Abstract: Simple editor setups an AVMutableComposition using supplied clips and time ranges. It also setups AVVideoComposition to add a crossfade transition.
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

#import "APLSimpleEditor.h"
#import <CoreMedia/CoreMedia.h>

@interface APLSimpleEditor ()

@property (nonatomic, readwrite, retain) AVMutableComposition *composition;
@property (nonatomic, readwrite, retain) AVMutableVideoComposition *videoComposition;
@property (nonatomic, readwrite, retain) AVMutableAudioMix *audioMix;

@end

@implementation APLSimpleEditor

- (void)buildTransitionComposition:(AVMutableComposition *)composition andVideoComposition:(AVMutableVideoComposition *)videoComposition andAudioMix:(AVMutableAudioMix *)audioMix
{
	CMTime nextClipStartTime = kCMTimeZero;
	NSInteger i;
	NSUInteger clipsCount = [self.clips count];
	
	// Make transitionDuration no greater than half the shortest clip duration.
	CMTime transitionDuration = self.transitionDuration;
	for (i = 0; i < clipsCount; i++ ) {
		NSValue *clipTimeRange = [self.clipTimeRanges objectAtIndex:i];
		if (clipTimeRange) {
			CMTime halfClipDuration = [clipTimeRange CMTimeRangeValue].duration;
			halfClipDuration.timescale *= 2; // You can halve a rational by doubling its denominator.
			transitionDuration = CMTimeMinimum(transitionDuration, halfClipDuration);
		}
	}
	
	// Add two video tracks and two audio tracks.
	AVMutableCompositionTrack *compositionVideoTracks[2];
	AVMutableCompositionTrack *compositionAudioTracks[2];
	compositionVideoTracks[0] = [composition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
	compositionVideoTracks[1] = [composition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
	compositionAudioTracks[0] = [composition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
	compositionAudioTracks[1] = [composition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
	
	CMTimeRange *passThroughTimeRanges = alloca(sizeof(CMTimeRange) * clipsCount);
	CMTimeRange *transitionTimeRanges = alloca(sizeof(CMTimeRange) * clipsCount);
	
	// Place clips into alternating video & audio tracks in composition, overlapped by transitionDuration.
	for (i = 0; i < clipsCount; i++ ) {
		NSInteger alternatingIndex = i % 2; // alternating targets: 0, 1, 0, 1, ...
		AVURLAsset *asset = [self.clips objectAtIndex:i];
		NSValue *clipTimeRange = [self.clipTimeRanges objectAtIndex:i];
		CMTimeRange timeRangeInAsset;
		if (clipTimeRange)
			timeRangeInAsset = [clipTimeRange CMTimeRangeValue];
		else
			timeRangeInAsset = CMTimeRangeMake(kCMTimeZero, [asset duration]);
		
		AVAssetTrack *clipVideoTrack = [[asset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0];
		[compositionVideoTracks[alternatingIndex] insertTimeRange:timeRangeInAsset ofTrack:clipVideoTrack atTime:nextClipStartTime error:nil];
		
		AVAssetTrack *clipAudioTrack = [[asset tracksWithMediaType:AVMediaTypeAudio] objectAtIndex:0];
		[compositionAudioTracks[alternatingIndex] insertTimeRange:timeRangeInAsset ofTrack:clipAudioTrack atTime:nextClipStartTime error:nil];
		
		// Remember the time range in which this clip should pass through.
		// Second clip begins with a transition.
		// First clip ends with a transition.
		// Exclude those transitions from the pass through time ranges.
		passThroughTimeRanges[i] = CMTimeRangeMake(nextClipStartTime, timeRangeInAsset.duration);
		if (i > 0) {
			passThroughTimeRanges[i].start = CMTimeAdd(passThroughTimeRanges[i].start, transitionDuration);
			passThroughTimeRanges[i].duration = CMTimeSubtract(passThroughTimeRanges[i].duration, transitionDuration);
		}
		if (i+1 < clipsCount) {
			passThroughTimeRanges[i].duration = CMTimeSubtract(passThroughTimeRanges[i].duration, transitionDuration);
		}
		
		// The end of this clip will overlap the start of the next by transitionDuration.
		// (Note: this arithmetic falls apart if timeRangeInAsset.duration < 2 * transitionDuration.)
		nextClipStartTime = CMTimeAdd(nextClipStartTime, timeRangeInAsset.duration);
		nextClipStartTime = CMTimeSubtract(nextClipStartTime, transitionDuration);
		
		// Remember the time range for the transition to the next item.
		if (i+1 < clipsCount) {
			transitionTimeRanges[i] = CMTimeRangeMake(nextClipStartTime, transitionDuration);
		}
	}
	
	// Set up the video composition if we are to perform crossfade transitions between clips.
	NSMutableArray *instructions = [NSMutableArray array];
	NSMutableArray *trackMixArray = [NSMutableArray array];
	
	// Cycle between "pass through A", "transition from A to B", "pass through B"
	for (i = 0; i < clipsCount; i++ ) {
		NSInteger alternatingIndex = i % 2; // alternating targets
		
		// Pass through clip i.
		AVMutableVideoCompositionInstruction *passThroughInstruction = [AVMutableVideoCompositionInstruction videoCompositionInstruction];
		passThroughInstruction.timeRange = passThroughTimeRanges[i];
		AVMutableVideoCompositionLayerInstruction *passThroughLayer = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:compositionVideoTracks[alternatingIndex]];
		
		passThroughInstruction.layerInstructions = [NSArray arrayWithObject:passThroughLayer];
		[instructions addObject:passThroughInstruction];
		
		if (i+1 < clipsCount) {
			AVMutableVideoCompositionInstruction *transitionInstruction = [AVMutableVideoCompositionInstruction videoCompositionInstruction];
			transitionInstruction.timeRange = transitionTimeRanges[i];
			AVMutableVideoCompositionLayerInstruction *fromLayer = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:compositionVideoTracks[alternatingIndex]];
			AVMutableVideoCompositionLayerInstruction *toLayer = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:compositionVideoTracks[1-alternatingIndex]];
			// Fade in the toLayer by setting a ramp from 0.0 to 1.0.
			[toLayer setOpacityRampFromStartOpacity:0.0 toEndOpacity:1.0 timeRange:transitionTimeRanges[i]];
			
			transitionInstruction.layerInstructions = [NSArray arrayWithObjects:toLayer, fromLayer, nil];
			[instructions addObject:transitionInstruction];
			
			// Add AudioMix to fade in the volume ramps
			AVMutableAudioMixInputParameters *trackMix1 = [AVMutableAudioMixInputParameters audioMixInputParametersWithTrack:compositionAudioTracks[0]];
			
			[trackMix1 setVolumeRampFromStartVolume:1.0 toEndVolume:0.0 timeRange:transitionTimeRanges[0]];
			
			[trackMixArray addObject:trackMix1];
			
			AVMutableAudioMixInputParameters *trackMix2 = [AVMutableAudioMixInputParameters audioMixInputParametersWithTrack:compositionAudioTracks[1]];
			
			[trackMix2 setVolumeRampFromStartVolume:0.0 toEndVolume:1.0 timeRange:transitionTimeRanges[0]];
			[trackMix2 setVolumeRampFromStartVolume:1.0 toEndVolume:1.0 timeRange:passThroughTimeRanges[1]];
			
			[trackMixArray addObject:trackMix2];
		}
		
	}
	
	audioMix.inputParameters = trackMixArray;
	videoComposition.instructions = instructions;
}

- (void)buildCompositionObjectsForPlayback
{
	if ( (self.clips == nil) || [self.clips count] == 0 ) {
		self.composition = nil;
		self.videoComposition = nil;
		return;
	}
	
	CGSize videoSize = [[self.clips objectAtIndex:0] naturalSize];
	AVMutableComposition *composition = [AVMutableComposition composition];
	AVMutableVideoComposition *videoComposition = nil;
	AVMutableAudioMix *audioMix = nil;
	
	composition.naturalSize = videoSize;
	
	// With transitions:
	// Place clips into alternating video & audio tracks in composition, overlapped by transitionDuration.
	// Set up the video composition to cycle between "pass through A", "transition from A to B",
	// "pass through B"
	
	videoComposition = [AVMutableVideoComposition videoComposition];
	audioMix = [AVMutableAudioMix audioMix];
	
	[self buildTransitionComposition:composition andVideoComposition:videoComposition andAudioMix:audioMix];
	
	if (videoComposition) {
		// Every videoComposition needs these properties to be set:
		videoComposition.frameDuration = CMTimeMake(1, 30); // 30 fps
		videoComposition.renderSize = videoSize;
	}
	
	self.composition = composition;
	self.videoComposition = videoComposition;
	self.audioMix = audioMix;
}

- (AVPlayerItem *)playerItem
{
	AVPlayerItem *playerItem = [AVPlayerItem playerItemWithAsset:self.composition];
	playerItem.videoComposition = self.videoComposition;
	playerItem.audioMix = self.audioMix;
	
	return playerItem;
}

@end

