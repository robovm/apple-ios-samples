/*
 Copyright (C) 2014 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 
  Helper class to read and decode a movie frame by frame, adjust each frame, then encode and write to a new movie file.
  
 */

#import <AVFoundation/AVFoundation.h>
#import "AAPLAVReaderWriter.h"

@protocol AAPLRWSampleBufferChannelDelegate;

@interface AAPLRWSampleBufferChannel : NSObject
{
@private
	dispatch_block_t completionHandler;
	dispatch_queue_t serializationQueue;
}

@property BOOL useAdaptor;
@property BOOL finished;  // only accessed on serialization queue;
@property AVAssetWriterInput* assetWriterInput;
@property AVAssetReaderOutput* assetReaderOutput;
@property AVAssetWriterInputPixelBufferAdaptor* adaptor;

- (instancetype)initWithAssetReaderOutput:(AVAssetReaderOutput *)assetReaderOutput assetWriterInput:(AVAssetWriterInput *)assetWriterInput useAdaptor:(BOOL)useAdaptor NS_DESIGNATED_INITIALIZER;

// delegate is retained until completion handler is called.
// Completion handler is guaranteed to be called exactly once, whether reading/writing finishes, fails, or is cancelled.
// Delegate may be nil.
//
- (void)startWithDelegate:(id <AAPLRWSampleBufferChannelDelegate>)delegate
        completionHandler:(dispatch_block_t)completionHandler;

- (void)cancel;

@end


@protocol AAPLRWSampleBufferChannelDelegate <NSObject>
@optional

- (void)sampleBufferChannel:(AAPLRWSampleBufferChannel *)sampleBufferChannel
        didReadSampleBuffer:(CMSampleBufferRef)sampleBuffer;

- (void)sampleBufferChannel:(AAPLRWSampleBufferChannel *)sampleBufferChannel
        didReadSampleBuffer:(CMSampleBufferRef)sampleBuffer
   andMadeWriteSampleBuffer:(CVPixelBufferRef)sampleBufferForWrite;

@end


@implementation AAPLRWSampleBufferChannel

- (instancetype)initWithAssetReaderOutput:(AVAssetReaderOutput *)localAssetReaderOutput
               assetWriterInput:(AVAssetWriterInput *)localAssetWriterInput
                     useAdaptor:(BOOL)useAdaptor

{
    self = [super init];
    
    if (self)
    {
        _assetReaderOutput = localAssetReaderOutput;
        _assetWriterInput = localAssetWriterInput;
        
        _finished = NO;
        
        // Pixel buffer attributes keys for the pixel buffer pool are defined in <CoreVideo/CVPixelBuffer.h>.
        // To specify the pixel format type, the pixelBufferAttributes dictionary should contain a value for kCVPixelBufferPixelFormatTypeKey.
        // For example, use [NSNumber numberWithInt:kCVPixelFormatType_32BGRA] for 8-bit-per-channel BGRA.
        // See the discussion under appendPixelBuffer:withPresentationTime: for advice on choosing a pixel format.
        //
        _useAdaptor = useAdaptor;
        NSDictionary* adaptorAttrs = @{ (id)kCVPixelBufferPixelFormatTypeKey : @(kCVPixelFormatType_32BGRA)};
        if (useAdaptor)
            _adaptor = [AVAssetWriterInputPixelBufferAdaptor assetWriterInputPixelBufferAdaptorWithAssetWriterInput:localAssetWriterInput
                                                                                        sourcePixelBufferAttributes:adaptorAttrs];
        
        serializationQueue = dispatch_queue_create("AAPLRWSampleBufferChannel queue", NULL);
    }
    
    return self;
}

// always called on the serialization queue
- (void)callCompletionHandlerIfNecessary
{
    // Set state to mark that we no longer need to call the completion handler, grab the completion handler, and clear out the ivar
    BOOL oldFinished = self.finished;
    self.finished = YES;
    
    if (oldFinished == NO)
    {
        [self.assetWriterInput markAsFinished];  // let the asset writer know that we will not be appending any more samples to this input
        
        dispatch_block_t localCompletionHandler = completionHandler;
        completionHandler = nil;
        
        if (localCompletionHandler)
            localCompletionHandler();
    }
}


- (void)startWithDelegate:(id <AAPLRWSampleBufferChannelDelegate>)delegate completionHandler:(dispatch_block_t)localCompletionHandler
{
    completionHandler = [localCompletionHandler copy];  // released in -callCompletionHandlerIfNecessary
    
    [self.assetWriterInput requestMediaDataWhenReadyOnQueue:serializationQueue usingBlock:^{
        
        if (self.finished)
            return;
        
        BOOL completedOrFailed = NO;
        
        // Read samples in a loop as long as the asset writer input is ready
        while ([self.assetWriterInput isReadyForMoreMediaData] && !completedOrFailed)
        {
            @autoreleasepool {
                
                CMSampleBufferRef sampleBuffer = [self.assetReaderOutput copyNextSampleBuffer];
                if (sampleBuffer != NULL)
                {
                    BOOL success = NO;
                    
                    if (self.adaptor && [delegate respondsToSelector:@selector(sampleBufferChannel:didReadSampleBuffer:andMadeWriteSampleBuffer:)])
                    {
                        CVPixelBufferRef writerBuffer = NULL;
                        CVPixelBufferPoolCreatePixelBuffer (NULL, self.adaptor.pixelBufferPool, &writerBuffer);
                        CMTime presentationTime = CMSampleBufferGetPresentationTimeStamp(sampleBuffer);
                        
                        [delegate sampleBufferChannel:self didReadSampleBuffer:sampleBuffer andMadeWriteSampleBuffer:writerBuffer];
                        success = [self.adaptor appendPixelBuffer:writerBuffer withPresentationTime:presentationTime];
                        
                        CFRelease(writerBuffer);
                    }
                    else if ([delegate respondsToSelector:@selector(sampleBufferChannel:didReadSampleBuffer:)])
                    {
                        [delegate sampleBufferChannel:self didReadSampleBuffer:sampleBuffer];
                        success = [self.assetWriterInput appendSampleBuffer:sampleBuffer];
                    }
                    
                    CFRelease(sampleBuffer);
                    sampleBuffer = NULL;
                    
                    completedOrFailed = !success;
                }
                else
                    completedOrFailed = YES;
                
            }
        }
        
        if (completedOrFailed)
            [self callCompletionHandlerIfNecessary];
    }];
}

- (void)cancel
{
    dispatch_async(serializationQueue, ^{
        [self callCompletionHandlerIfNecessary];
    });
}

@end


#pragma mark -


typedef void (^AVReaderWriterProgressProc)(float);
typedef void (^AVReaderWriterCompletionProc)(NSError*);


@interface AAPLAVReaderWriter() <AAPLRWSampleBufferChannelDelegate>

@property AVAsset*    asset;
@property CMTimeRange timeRange;
@property NSURL*      outputURL;

@end

@implementation AAPLAVReaderWriter
{
    dispatch_queue_t			_serializationQueue;
    
    // All of these are createed, accessed, and torn down exclusively on the serializaton queue
    AVAssetReader*            assetReader;
    AVAssetWriter*            assetWriter;
    AAPLRWSampleBufferChannel*    audioSampleBufferChannel;
    AAPLRWSampleBufferChannel*    videoSampleBufferChannel;
    BOOL	                      cancelled;
    AVReaderWriterProgressProc    _progressProc;
    AVReaderWriterCompletionProc  _completionProc;
}

- (instancetype) initWithAsset: (AVAsset*) asset
{
	self = [super init];
	
	_asset = asset;
	_serializationQueue = dispatch_queue_create("AVReaderWriter Queue", NULL);
	return self;
}

- (void)writeToURL:(NSURL *)localOutputURL
          progress:(void (^)(float)) progress
        completion:(void (^)(NSError *)) completion
{
	[self setOutputURL:localOutputURL];
    
	AVAsset *localAsset = [self asset];
    
	_completionProc = completion;
    _progressProc = progress;
    
	[localAsset loadValuesAsynchronouslyForKeys:@[@"tracks", @"duration"] completionHandler:^{
        
		// Dispatch the setup work to the serialization queue, to ensure this work is serialized with potential cancellation
		dispatch_async(_serializationQueue, ^{
            
			// Since we are doing these things asynchronously, the user may have already cancelled on the main thread.  In that case, simply return from this block
			if (cancelled)
				return;
			
			BOOL success = YES;
			NSError *localError = nil;
			
			success = ([localAsset statusOfValueForKey:@"tracks" error:&localError] == AVKeyValueStatusLoaded);
			if (success)
				success = ([localAsset statusOfValueForKey:@"duration" error:&localError] == AVKeyValueStatusLoaded);
			
			if (success)
			{
				self.timeRange = CMTimeRangeMake(kCMTimeZero, [localAsset duration]);
				
				// AVAssetWriter does not overwrite files for us, so remove the destination file if it already exists
				NSFileManager *fm = [NSFileManager new];
				NSString *localOutputPath = [localOutputURL path];
				if ([fm fileExistsAtPath:localOutputPath])
					success = [fm removeItemAtPath:localOutputPath error:&localError];
			}
			
			// Set up the AVAssetReader and AVAssetWriter, then begin writing samples or flag an error
			if (success)
				success = [self setUpReaderAndWriterReturningError:&localError];
			if (success)
				success = [self startReadingAndWritingReturningError:&localError];
            
			if (!success)
			{
				[self readingAndWritingDidFinishSuccessfully:success withError:localError];
			}
		});
	}];
}

- (BOOL) setUpReaderAndWriterReturningError:(NSError **)outError
{
	NSError *localError = nil;
	AVAsset *localAsset = [self asset];
	NSURL *localOutputURL = [self outputURL];
	
	// Create asset reader and asset writer
	assetReader = [[AVAssetReader alloc] initWithAsset:localAsset error:&localError];
    if (!assetReader)
    {
        if (outError)
            *outError = localError;
        return NO;
    }
    
    assetWriter = [[AVAssetWriter alloc] initWithURL:localOutputURL fileType:AVFileTypeQuickTimeMovie error:&localError];
    if (!assetReader)
    {
        if (outError)
            *outError = localError;
        return NO;
    }
    
	// Create asset reader outputs and asset writer inputs for the first audio track and first video track of the asset
    
    // Grab first audio track and first video track, if the asset has them
    AVAssetTrack *audioTrack = nil;
    NSArray *audioTracks = [localAsset tracksWithMediaType:AVMediaTypeAudio];
    if ([audioTracks count] > 0)
        audioTrack = audioTracks[0];
    
    AVAssetTrack *videoTrack = nil;
    NSArray *videoTracks = [localAsset tracksWithMediaType:AVMediaTypeVideo];
    if ([videoTracks count] > 0)
        videoTrack = videoTracks[0];
		
    if (audioTrack)
    {
        // Decompress to Linear PCM with the asset reader
        AVAssetReaderOutput *output = [AVAssetReaderTrackOutput assetReaderTrackOutputWithTrack:audioTrack outputSettings:nil];
        [assetReader addOutput:output];
        
        AVAssetWriterInput *input = [AVAssetWriterInput assetWriterInputWithMediaType:audioTrack.mediaType outputSettings:nil];
        [assetWriter addInput:input];
        
        // Create and save an instance of AAPLRWSampleBufferChannel, which will coordinate the work of reading and writing sample buffers
        audioSampleBufferChannel = [[AAPLRWSampleBufferChannel alloc] initWithAssetReaderOutput:output assetWriterInput:input useAdaptor:NO];
    }
		
    if (videoTrack)
    {
        // Decompress to ARGB with the asset reader
        NSDictionary *decompSettings = @{
                                         (id)kCVPixelBufferPixelFormatTypeKey : @(kCVPixelFormatType_32BGRA),
                                         (id)kCVPixelBufferIOSurfacePropertiesKey : @{}
                                         };
        AVAssetReaderOutput *output = [AVAssetReaderTrackOutput assetReaderTrackOutputWithTrack:videoTrack
                                                                                 outputSettings:decompSettings];
        [assetReader addOutput:output];
        
        // Get the format description of the track, to fill in attributes of the video stream that we don't want to change
        CMFormatDescriptionRef formatDescription = NULL;
        NSArray *formatDescriptions = [videoTrack formatDescriptions];
        if ([formatDescriptions count] > 0)
            formatDescription = (__bridge CMFormatDescriptionRef)formatDescriptions[0];
        
        // Grab track dimensions from format description
        CGSize trackDimensions = CGSizeZero;
        if (formatDescription)
            trackDimensions = CMVideoFormatDescriptionGetPresentationDimensions(formatDescription, false, false);
        else
            trackDimensions = [videoTrack naturalSize];
        
        // Grab clean aperture, pixel aspect ratio from format description
        NSDictionary *compressionSettings = nil;
        if (formatDescription)
        {
            NSDictionary *cleanAperture = nil;
            CFDictionaryRef cleanApertureDescr = CMFormatDescriptionGetExtension(formatDescription, kCMFormatDescriptionExtension_CleanAperture);
            if (cleanApertureDescr)
            {
                cleanAperture = @{
                                  AVVideoCleanApertureWidthKey :
                                      (id)CFDictionaryGetValue(cleanApertureDescr, kCMFormatDescriptionKey_CleanApertureWidth),
                                  AVVideoCleanApertureHeightKey :
                                      (id)CFDictionaryGetValue(cleanApertureDescr, kCMFormatDescriptionKey_CleanApertureHeight),
                                  AVVideoCleanApertureHorizontalOffsetKey :
                                      (id)CFDictionaryGetValue(cleanApertureDescr, kCMFormatDescriptionKey_CleanApertureHorizontalOffset),
                                  AVVideoCleanApertureVerticalOffsetKey :
                                      (id)CFDictionaryGetValue(cleanApertureDescr, kCMFormatDescriptionKey_CleanApertureVerticalOffset),
                                  };
            }
            
            NSDictionary *pixelAspectRatio = nil;
            CFDictionaryRef pixelAspectRatioDescr = CMFormatDescriptionGetExtension(formatDescription, kCMFormatDescriptionExtension_PixelAspectRatio);
            if (pixelAspectRatioDescr)
            {
                pixelAspectRatio = @{
                                     AVVideoPixelAspectRatioHorizontalSpacingKey :
                                         (id)CFDictionaryGetValue(pixelAspectRatioDescr, kCMFormatDescriptionKey_PixelAspectRatioHorizontalSpacing),
                                     AVVideoPixelAspectRatioVerticalSpacingKey :
                                         (id)CFDictionaryGetValue(pixelAspectRatioDescr, kCMFormatDescriptionKey_PixelAspectRatioVerticalSpacing),
                                     };
            }
            
            if (cleanAperture || pixelAspectRatio)
            {
                NSMutableDictionary *mutableCompressionSettings = [NSMutableDictionary dictionary];
                if (cleanAperture)
                    mutableCompressionSettings[AVVideoCleanApertureKey] = cleanAperture;
                if (pixelAspectRatio)
                    mutableCompressionSettings[AVVideoPixelAspectRatioKey] = pixelAspectRatio;
                compressionSettings = mutableCompressionSettings;
            }
        }
        
        // Compress to H.264 with the asset writer
        NSMutableDictionary *videoSettings = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                              AVVideoCodecH264, AVVideoCodecKey,
                                              @(trackDimensions.width), AVVideoWidthKey,
                                              @(trackDimensions.height), AVVideoHeightKey,
                                              nil];
        if (compressionSettings)
            videoSettings[AVVideoCompressionPropertiesKey] = compressionSettings;
        
        AVAssetWriterInput *input = [AVAssetWriterInput assetWriterInputWithMediaType:videoTrack.mediaType outputSettings:videoSettings];
        input.transform = [videoTrack preferredTransform];
        [assetWriter addInput:input];
        
        // Create and save an instance of AAPLRWSampleBufferChannel, which will coordinate the work of reading and writing sample buffers
        videoSampleBufferChannel = [[AAPLRWSampleBufferChannel alloc] initWithAssetReaderOutput:output assetWriterInput:input useAdaptor:YES];
    }
    
    return YES;
}

- (BOOL)startReadingAndWritingReturningError:(NSError **)outError
{
	// Instruct the asset reader and asset writer to get ready to do work
	if ([assetReader startReading]==NO)
    {
        if (outError) *outError = [assetReader error];
        return NO;
    }
    
	if ([assetWriter startWriting] == NO)
	{
        if (outError) *outError = [assetWriter error];
        return NO;
	}
	
    
    dispatch_group_t dispatchGroup = dispatch_group_create();
    
    // Start a sample-writing session
    [assetWriter startSessionAtSourceTime:self.timeRange.start];
    
    // Start reading and writing samples
    if (audioSampleBufferChannel)
    {
        // Only set audio delegate for audio-only assets, else let the video channel drive progress
        id <AAPLRWSampleBufferChannelDelegate> delegate = nil;
        if (!videoSampleBufferChannel)
            delegate = self;
        
        dispatch_group_enter(dispatchGroup);
        [audioSampleBufferChannel startWithDelegate:delegate
                                  completionHandler:^{
            dispatch_group_leave(dispatchGroup);
        }];
    }
    if (videoSampleBufferChannel)
    {
        dispatch_group_enter(dispatchGroup);
        [videoSampleBufferChannel startWithDelegate:self
                                  completionHandler:^{
            dispatch_group_leave(dispatchGroup);
        }];
    }
    
    // Set up a callback for when the sample writing is finished
    dispatch_group_notify(dispatchGroup, _serializationQueue, ^{
        BOOL finalSuccess = YES;
        __block NSError *finalError = nil;
        
        if (cancelled)
        {
            [assetReader cancelReading];
            [assetWriter cancelWriting];
        }
        else
        {
            if ([assetReader status] == AVAssetReaderStatusFailed)
            {
                finalSuccess = NO;
                finalError = [assetReader error];
            }
            
            if (finalSuccess)
            {
                [assetWriter finishWritingWithCompletionHandler:^{
                    BOOL success = (assetWriter.status == AVAssetWriterStatusCompleted);
                    [self readingAndWritingDidFinishSuccessfully:success withError:[assetWriter error]];
                }];
            }
        }
        
    });
    
	return YES;
}

- (void)cancel:(id)sender
{
	// Dispatch cancellation tasks to the serialization queue to avoid races with setup and teardown
	dispatch_async(_serializationQueue, ^{
		[audioSampleBufferChannel cancel];
		[videoSampleBufferChannel cancel];
		cancelled = YES;
	});
}

- (void)readingAndWritingDidFinishSuccessfully:(BOOL)success withError:(NSError *)error
{
	if (!success)
	{
		[assetReader cancelReading];
		[assetWriter cancelWriting];
	}
	
	// Tear down ivars
	assetReader = nil;
	assetWriter = nil;
	audioSampleBufferChannel = nil;
	videoSampleBufferChannel = nil;
	cancelled = NO;
	
    _completionProc(error);
}

static double progressOfSampleBufferInTimeRange(CMSampleBufferRef sampleBuffer, CMTimeRange timeRange)
{
	CMTime progressTime = CMSampleBufferGetPresentationTimeStamp(sampleBuffer);
	progressTime = CMTimeSubtract(progressTime, timeRange.start);
	CMTime sampleDuration = CMSampleBufferGetDuration(sampleBuffer);
	if (CMTIME_IS_NUMERIC(sampleDuration))
		progressTime= CMTimeAdd(progressTime, sampleDuration);
	return CMTimeGetSeconds(progressTime) / CMTimeGetSeconds(timeRange.duration);
}


- (void)sampleBufferChannel:(AAPLRWSampleBufferChannel *)sampleBufferChannel
        didReadSampleBuffer:(CMSampleBufferRef)sampleBuffer
{
	// Calculate progress (scale of 0.0 to 1.0)
	double progress = progressOfSampleBufferInTimeRange(sampleBuffer, self.timeRange);
	
    _progressProc(progress * 100.0);
    
	// Grab the pixel buffer from the sample buffer, if possible
	CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    
	if (imageBuffer && (CFGetTypeID(imageBuffer) == CVPixelBufferGetTypeID()))
	{
		//pixelBuffer = (CVPixelBufferRef)imageBuffer;
		[self.delegate adjustPixelBuffer:imageBuffer];
	}
}

- (void)sampleBufferChannel:(AAPLRWSampleBufferChannel *)sampleBufferChannel
        didReadSampleBuffer:(CMSampleBufferRef)sampleBuffer
   andMadeWriteSampleBuffer:(CVPixelBufferRef)sampleBufferForWrite
{
    // Calculate progress (scale of 0.0 to 1.0)
    double progress = progressOfSampleBufferInTimeRange(sampleBuffer, self.timeRange);
    
    _progressProc(progress * 100.0);
    
    // Grab the pixel buffer from the sample buffer, if possible
    CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    CVImageBufferRef writerBuffer = (CVPixelBufferRef)sampleBufferForWrite;
    
    if (imageBuffer && (CFGetTypeID(imageBuffer) == CVPixelBufferGetTypeID()) &&
        writerBuffer )//&& (CFGetTypeID(writerBuffer) == CVPixelBufferGetTypeID()))
    {
        [self.delegate adjustPixelBuffer:imageBuffer toOutputBuffer:writerBuffer];
    }
}


@end
