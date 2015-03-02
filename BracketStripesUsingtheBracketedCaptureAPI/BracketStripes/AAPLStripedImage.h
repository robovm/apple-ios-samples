/*
 Copyright (C) 2014 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 
         Implements a composite image constructed of CMSampleBuffer stripes.
     
 */

@import CoreMedia;

@interface AAPLStripedImage : NSObject

// Designated initializer
- (instancetype)initForSize:(CGSize)size stripWidth:(CGFloat)stripWidth stride:(NSUInteger)stride;

// Add an image to the strip
// sampleBuffer must be a JPEG or BGRA image
- (void)addSampleBuffer:(CMSampleBufferRef)sampleBuffer;

// The final rendered strip
- (UIImage *)imageWithOrientation:(UIImageOrientation)orientation;

@end
