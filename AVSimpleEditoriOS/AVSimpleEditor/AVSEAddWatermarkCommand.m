/*
     File: AVSEAddWatermarkCommand.m
 Abstract: A subclass of AVSECommand which handles CALayer. This tool adds a title layer (CALayer) on top of an existing AVMutableComposition or an AVAsset.
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

#import "AVSEAddWatermarkCommand.h"

@interface AVSEAddWatermarkCommand (Internal)

-(CALayer*)watermarkLayerForSize:(CGSize)videoSize;

@end

@implementation AVSEAddWatermarkCommand

- (void)performWithAsset:(AVAsset*)asset
{
	self.watermarkLayer = nil;
	CGSize videoSize;
	
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
	if(!self.mutableComposition) {
		
		// Check if a composition already exists, else create a composition using the input asset
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
	// Create a water mark layer of the same size as that of a video frame from the asset
	if ([[self.mutableComposition tracksWithMediaType:AVMediaTypeVideo] count] != 0) {
		
		if(!self.mutableVideoComposition) {
			
			// build a pass through video composition
			self.mutableVideoComposition = [AVMutableVideoComposition videoComposition];
			self.mutableVideoComposition.frameDuration = CMTimeMake(1, 30); // 30 fps
			self.mutableVideoComposition.renderSize = assetVideoTrack.naturalSize;
			
			AVMutableVideoCompositionInstruction *passThroughInstruction = [AVMutableVideoCompositionInstruction videoCompositionInstruction];
			passThroughInstruction.timeRange = CMTimeRangeMake(kCMTimeZero, [self.mutableComposition duration]);
			
			AVAssetTrack *videoTrack = [self.mutableComposition tracksWithMediaType:AVMediaTypeVideo][0];
			AVMutableVideoCompositionLayerInstruction *passThroughLayer = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:videoTrack];
			
			passThroughInstruction.layerInstructions = @[passThroughLayer];
			self.mutableVideoComposition.instructions = @[passThroughInstruction];
			
		}
		
		videoSize = self.mutableVideoComposition.renderSize;
		self.watermarkLayer = [self watermarkLayerForSize:videoSize];
	
	}
	
	
	// Step 3
	// Notify AVSEViewController about add watermark operation completion
	[[NSNotificationCenter defaultCenter] postNotificationName:AVSEEditCommandCompletionNotification object:self];
}

- (CALayer*)watermarkLayerForSize:(CGSize)videoSize
{
	// Create a layer for the title
	CALayer *_watermarkLayer = [CALayer layer];
	
	// Create a layer for the text of the title.
	CATextLayer *titleLayer = [CATextLayer layer];
	titleLayer.string = @"AVSE";
	titleLayer.foregroundColor = [[UIColor whiteColor] CGColor];
	titleLayer.shadowOpacity = 0.5;
	titleLayer.alignmentMode = kCAAlignmentCenter;
	titleLayer.bounds = CGRectMake(0, 0, videoSize.width/2, videoSize.height/2);
	
	// Add it to the overall layer.
	[_watermarkLayer addSublayer:titleLayer];
	
	return _watermarkLayer;
}

@end
