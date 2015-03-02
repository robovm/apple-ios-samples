/*
 Copyright (C) 2014 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 
  Helper class to read and decode a movie frame by frame, adjust each frame, then encode and write to a new movie file.
  
 */

#import <AVFoundation/AVFoundation.h>
#import <Foundation/Foundation.h>

@protocol AAPLAVReaderWriterAdjustDelegate
@optional
- (void) adjustPixelBuffer:(CVPixelBufferRef)inputOutputBuffer;

- (void) adjustPixelBuffer:(CVPixelBufferRef)inputBuffer
            toOutputBuffer:(CVPixelBufferRef)outputBuffer;
@end


@interface AAPLAVReaderWriter : NSObject

@property id<AAPLAVReaderWriterAdjustDelegate> delegate;

- (instancetype) initWithAsset:(AVAsset*)asset NS_DESIGNATED_INITIALIZER;

- (void)writeToURL:(NSURL *)localOutputURL
          progress:(void (^)(float)) progress
        completion:(void (^)(NSError *)) completion;

@end
