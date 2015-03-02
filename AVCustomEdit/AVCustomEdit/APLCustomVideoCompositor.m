/*
     File: APLCustomVideoCompositor.m
 Abstract: Custom video compositor class implementing the AVVideoCompositing protocol.
  Version: 1.2
 
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

#import "APLCustomVideoCompositor.h"
#import "APLCustomVideoCompositionInstruction.h"
#import "APLDiagonalWipeRenderer.h"
#import "APLCrossDissolveRenderer.h"

#import <CoreVideo/CoreVideo.h>

@interface APLCustomVideoCompositor()
{
	BOOL								_shouldCancelAllRequests;
	BOOL								_renderContextDidChange;
	dispatch_queue_t					_renderingQueue;
	dispatch_queue_t					_renderContextQueue;
	AVVideoCompositionRenderContext*	_renderContext;
    CVPixelBufferRef					_previousBuffer;
}

@property (nonatomic, strong) APLOpenGLRenderer *oglRenderer;

@end

@implementation APLCrossDissolveCompositor

- (id)init
{
	self = [super init];
	
	if (self) {
		self.oglRenderer = [[APLCrossDissolveRenderer alloc] init];
	}
	
	return self;
}

@end

@implementation APLDiagonalWipeCompositor

- (id)init
{
	self = [super init];
	
	if (self) {
		self.oglRenderer = [[APLDiagonalWipeRenderer alloc] init];
	}
	
	return self;
}

@end

@implementation APLCustomVideoCompositor

#pragma mark - AVVideoCompositing protocol

- (id)init
{
	self = [super init];
	if (self)
	{
		_renderingQueue = dispatch_queue_create("com.apple.aplcustomvideocompositor.renderingqueue", DISPATCH_QUEUE_SERIAL); 
		_renderContextQueue = dispatch_queue_create("com.apple.aplcustomvideocompositor.rendercontextqueue", DISPATCH_QUEUE_SERIAL);
        _previousBuffer = nil;
		_renderContextDidChange = NO;
	}
	return self;
}

- (NSDictionary *)sourcePixelBufferAttributes
{
	return @{ (NSString *)kCVPixelBufferPixelFormatTypeKey : [NSNumber numberWithUnsignedInt:kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange],
			  (NSString*)kCVPixelBufferOpenGLESCompatibilityKey : [NSNumber numberWithBool:YES]};
}

- (NSDictionary *)requiredPixelBufferAttributesForRenderContext
{
	return @{ (NSString *)kCVPixelBufferPixelFormatTypeKey : [NSNumber numberWithUnsignedInt:kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange],
			  (NSString*)kCVPixelBufferOpenGLESCompatibilityKey : [NSNumber numberWithBool:YES]};
}

- (void)renderContextChanged:(AVVideoCompositionRenderContext *)newRenderContext
{
	dispatch_sync(_renderContextQueue, ^() {
		_renderContext = newRenderContext;
		_renderContextDidChange = YES;
	});
}

- (void)startVideoCompositionRequest:(AVAsynchronousVideoCompositionRequest *)request
{
	@autoreleasepool {
		dispatch_async(_renderingQueue,^() {
			
			// Check if all pending requests have been cancelled
			if (_shouldCancelAllRequests) {
				[request finishCancelledRequest];
			} else {
				NSError *err = nil;
				// Get the next rendererd pixel buffer
				CVPixelBufferRef resultPixels = [self newRenderedPixelBufferForRequest:request error:&err];
				
				if (resultPixels) {
					// The resulting pixelbuffer from OpenGL renderer is passed along to the request
					[request finishWithComposedVideoFrame:resultPixels];
					CFRelease(resultPixels);
				} else {
					[request finishWithError:err];
				}
			}
		});
	}
}

- (void)cancelAllPendingVideoCompositionRequests
{
	// pending requests will call finishCancelledRequest, those already rendering will call finishWithComposedVideoFrame
	_shouldCancelAllRequests = YES;
	
	dispatch_barrier_async(_renderingQueue, ^() {
		// start accepting requests again
		_shouldCancelAllRequests = NO;
	});
}

#pragma mark - Utilities

static Float64 factorForTimeInRange(CMTime time, CMTimeRange range) /* 0.0 -> 1.0 */
{
	CMTime elapsed = CMTimeSubtract(time, range.start);
	return CMTimeGetSeconds(elapsed) / CMTimeGetSeconds(range.duration);
}

- (CVPixelBufferRef)newRenderedPixelBufferForRequest:(AVAsynchronousVideoCompositionRequest *)request error:(NSError **)errOut
{
	CVPixelBufferRef dstPixels = nil;
	
	// tweenFactor indicates how far within that timeRange are we rendering this frame. This is normalized to vary between 0.0 and 1.0.
	// 0.0 indicates the time at first frame in that videoComposition timeRange
	// 1.0 indicates the time at last frame in that videoComposition timeRange
	float tweenFactor = factorForTimeInRange(request.compositionTime, request.videoCompositionInstruction.timeRange);
	
	APLCustomVideoCompositionInstruction *currentInstruction = request.videoCompositionInstruction;
	
	// Source pixel buffers are used as inputs while rendering the transition
	CVPixelBufferRef foregroundSourceBuffer = [request sourceFrameByTrackID:currentInstruction.foregroundTrackID];
	CVPixelBufferRef backgroundSourceBuffer = [request sourceFrameByTrackID:currentInstruction.backgroundTrackID];
	
	// Destination pixel buffer into which we render the output
	dstPixels = [_renderContext newPixelBuffer];
	
	// Recompute normalized render transform everytime the render context changes
	if (_renderContextDidChange) {
		// The renderTransform returned by the renderContext is in X: [0, w] and Y: [0, h] coordinate system
		// But since in this sample we render using OpenGLES which has its coordinate system between [-1, 1] we compute a normalized transform
		CGSize renderSize = _renderContext.size;
		CGSize destinationSize = CGSizeMake(CVPixelBufferGetWidth(dstPixels), CVPixelBufferGetHeight(dstPixels));
		CGAffineTransform renderContextTransform = {renderSize.width/2, 0, 0, renderSize.height/2, renderSize.width/2, renderSize.height/2};
		CGAffineTransform destinationTransform = {2/destinationSize.width, 0, 0, 2/destinationSize.height, -1, -1};
		CGAffineTransform normalizedRenderTransform = CGAffineTransformConcat(CGAffineTransformConcat(renderContextTransform, _renderContext.renderTransform), destinationTransform);
		_oglRenderer.renderTransform = normalizedRenderTransform;
		
		_renderContextDidChange = NO;
	}
	
	[_oglRenderer renderPixelBuffer:dstPixels usingForegroundSourceBuffer:foregroundSourceBuffer andBackgroundSourceBuffer:backgroundSourceBuffer forTweenFactor:tweenFactor];
	
	return dstPixels;
}

@end
