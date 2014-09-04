/*
     File: AVSECropCommand.m
 Abstract: A subclass of AVSECommand which uses AVMutableVideoComposition to achieve a crop effect. This tool crops the bottom right quadrant of a composition. This is achieved by reducing the video composition's render size to half of original and then applying a CGAffineTransformMakeTranslation transform to move the appropriate quadrant into view.
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

#import "AVSECropCommand.h"

@implementation AVSECropCommand

- (void)performWithAsset:(AVAsset*)asset
{
	AVMutableVideoCompositionInstruction *instruction = nil;
	AVMutableVideoCompositionLayerInstruction *layerInstruction = nil;
	CGAffineTransform t1;
	
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
	
	
	// Step 1
	// Create a composition with the given asset and insert audio and video tracks into it from the asset
	if (!self.mutableComposition) {
		
		// Check whether a composition has already been created, i.e, some other tool has already been applied.
		// Create a new composition
		self.mutableComposition = [AVMutableComposition composition];
		
		// Insert the video and audio tracks from AVAsset
		if (assetVideoTrack != nil) {
			AVMutableCompositionTrack *compositionVideoTrack = [self.mutableComposition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
			[compositionVideoTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, [asset duration]) ofTrack:assetVideoTrack atTime:insertionPoint error:&error];
		}
		if (assetAudioTrack != nil) {
			AVMutableCompositionTrack *compositionAudioTrack = [self.mutableComposition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
			[compositionAudioTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, [asset duration]) ofTrack:assetAudioTrack atTime:insertionPoint error:&error];
		}
		
	}
	
	
	// Step 2
	// Set the appropriate render sizes and transforms to achieve cropping 
	if (!self.mutableVideoComposition) {
		
		// Create a new video composition
		self.mutableVideoComposition = [AVMutableVideoComposition videoComposition];
		
		// Render size reduced to half to achieve the crop effect
		self.mutableVideoComposition.renderSize = CGSizeMake(assetVideoTrack.naturalSize.width/2, assetVideoTrack.naturalSize.height/2);
		self.mutableVideoComposition.frameDuration = CMTimeMake(1, 30);
		
		// The crop transform is set on a layer instruction
		instruction = [AVMutableVideoCompositionInstruction videoCompositionInstruction];
		instruction.timeRange = CMTimeRangeMake(kCMTimeZero, [self.mutableComposition duration]);
		layerInstruction = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:(self.mutableComposition.tracks)[0]];
		
		// Crop transformation (translation to move the bottom right half into the view)
		t1 = CGAffineTransformMakeTranslation(-1*assetVideoTrack.naturalSize.width/2, -1*assetVideoTrack.naturalSize.height/2);
		[layerInstruction setTransform:t1 atTime:kCMTimeZero];
		
	} else {
		
		self.mutableVideoComposition.renderSize = CGSizeMake(self.mutableVideoComposition.renderSize.width/2, self.mutableVideoComposition.renderSize.height/2);
		
		// Extract the existing layer instruction on the mutableVideoComposition
		instruction = (self.mutableVideoComposition.instructions)[0];
		layerInstruction = (instruction.layerInstructions)[0];
	
		// Check if a transform already exists on this layer instruction, this is done to add the current transform on top of previous edits
		CGAffineTransform existingTransform;
		if (![layerInstruction getTransformRampForTime:[self.mutableComposition duration] startTransform:&existingTransform endTransform:NULL timeRange:NULL]) {
			t1 = CGAffineTransformMakeTranslation(-1*assetVideoTrack.naturalSize.width/2, -1*assetVideoTrack.naturalSize.height/2);
			[layerInstruction setTransform:t1 atTime:kCMTimeZero];
		} else {
			t1 = CGAffineTransformMakeTranslation(-1*assetVideoTrack.naturalSize.height/2, -1*assetVideoTrack.naturalSize.width/2);
			CGAffineTransform newTransform = CGAffineTransformConcat(existingTransform, t1);
			[layerInstruction setTransform:newTransform atTime:kCMTimeZero];
		}
		
	}
	
	
	// Step 3
	// Add the instructions to the video composition
	instruction.layerInstructions = @[layerInstruction];
	self.mutableVideoComposition.instructions = @[instruction];
	
	
	// Step 4
	// Notify AVSEViewController class about crop operation completion
	[[NSNotificationCenter defaultCenter] postNotificationName:AVSEEditCommandCompletionNotification object:self];
}

@end
