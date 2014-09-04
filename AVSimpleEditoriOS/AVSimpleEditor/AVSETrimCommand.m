/*
     File: AVSETrimCommand.m
 Abstract: A subclass of AVSECommand which uses AVMutableComposition to trim a movie. This tool trims a movie to half its original length.
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
 
 Copyright (C) 2013 Apple Inc. All Rights Reserved.
 
 */

#import "AVSETrimCommand.h"

@implementation AVSETrimCommand

- (void)performWithAsset:(AVAsset*)asset
{
	AVAssetTrack *assetVideoTrack = nil;
	AVAssetTrack *assetAudioTrack = nil;
	
	// Check if the asset contains video and audio tracks
	if ([[asset tracksWithMediaType:AVMediaTypeVideo] count] != 0) {
		assetVideoTrack = [asset tracksWithMediaType:AVMediaTypeVideo][0];
	}
	if ([[asset tracksWithMediaType:AVMediaTypeAudio] count] != 0) {
		assetAudioTrack = [asset tracksWithMediaType:AVMediaTypeAudio][0];
	}
	
	
	CMTime insertionPoint = kCMTimeZero;
	NSError *error = nil;
	
	// Trim to half duration
	double halfDuration = CMTimeGetSeconds([asset duration])/2.0;
	CMTime trimmedDuration = CMTimeMakeWithSeconds(halfDuration, 1);
	
	
	// Step 1
	//  Create a composition with the given asset and insert audio and video tracks for half the duration into it from the asset
	if(!self.mutableComposition) {
		
		// Check if a composition already exists, i.e., another tool has been applied
		// Create a new composition
		self.mutableComposition = [AVMutableComposition composition];
		
		// Insert half time range of the video and audio tracks from AVAsset
		if(assetVideoTrack != nil) {
			AVMutableCompositionTrack *compositionVideoTrack = [self.mutableComposition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
			[compositionVideoTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, trimmedDuration) ofTrack:assetVideoTrack atTime:insertionPoint error:&error];
		}
		if(assetAudioTrack != nil) {
			AVMutableCompositionTrack *compositionAudioTrack = [self.mutableComposition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
			[compositionAudioTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, trimmedDuration) ofTrack:assetAudioTrack atTime:insertionPoint error:&error];
		}
		
	}else {
		
		// Remove the second half of the existing composition to trim
		[self.mutableComposition removeTimeRange:CMTimeRangeMake(trimmedDuration, [self.mutableComposition duration])];
		
	}
	
	
	// Step 2
	// Notify AVSEViewController about trim operation completion
	[[NSNotificationCenter defaultCenter] postNotificationName:AVSEEditCommandCompletionNotification object:self];
}

@end
