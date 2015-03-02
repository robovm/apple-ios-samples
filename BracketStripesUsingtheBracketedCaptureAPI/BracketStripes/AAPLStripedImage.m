/*
 Copyright (C) 2014 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 
         Implements a composite image constructed of CMSampleBuffer stripes.
     
 */

@import ImageIO;

#import "AAPLStripedImage.h"


@implementation AAPLStripedImage {

    // Size of the rendered striped image
    CGSize _imageSize;

    // Size of a stripe
    CGSize _stripeSize;

    // Number of stripes before they repeat in the rendered image
    NSUInteger _stride;

    // Current stripe index
    int _stripeIndex;

    // Bitmap context we render into
    CGContextRef _renderContext;
}


- (void)_prepareImageOfSize:(CGSize)size
{
    const size_t bitsPerComponent = 8;
    const size_t width = (size_t)size.width;
    const size_t paddedWidth = (width + 15) & ~15;
    const size_t bytesPerPixel = 4;
    const size_t bytesPerRow = paddedWidth * bytesPerPixel;

    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();

    _renderContext = CGBitmapContextCreate(NULL, size.width, size.height, bitsPerComponent, bytesPerRow, colorSpace, (CGBitmapInfo)kCGImageAlphaPremultipliedFirst);

    CGColorSpaceRelease(colorSpace);
}


- (CGImageRef)_createImageFromSampleBuffer:(CMSampleBufferRef)sampleBuffer
{
    CGImageRef image = NULL;

    CMFormatDescriptionRef formatDescription = CMSampleBufferGetFormatDescription(sampleBuffer);
    const FourCharCode subType = CMFormatDescriptionGetMediaSubType(formatDescription);

    CMBlockBufferRef blockBuffer = CMSampleBufferGetDataBuffer(sampleBuffer);

    if (blockBuffer) {

        NSAssert(subType == kCMVideoCodecType_JPEG, @"Block buffer must be JPEG encoded.");

        // Sample buffer is a JPEG compressed image
        size_t lengthAtOffset;
        size_t length;
        char *jpegBytes;

        if ( (CMBlockBufferGetDataPointer(blockBuffer, 0, &lengthAtOffset, &length, &jpegBytes) == kCMBlockBufferNoErr) &&
             (lengthAtOffset == length) ) {

            NSData *jpegData = [NSData dataWithBytes:jpegBytes length:length];
            CGImageSourceRef imageSource = CGImageSourceCreateWithData((__bridge CFDataRef)jpegData, NULL);

            NSDictionary *decodeOptions = @{
                (id)kCGImageSourceShouldAllowFloat: @NO,
                (id)kCGImageSourceShouldCache: @NO,
            };
            image = CGImageSourceCreateImageAtIndex(imageSource, 0, (__bridge CFDictionaryRef)decodeOptions);

            CFRelease(imageSource);
        }
    }
    else {

        NSAssert(subType == kCVPixelFormatType_32BGRA, @"Image buffer must be BGRA encoded.");

        // Sample buffer is a BGRA uncompressed image
        CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);

        CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();

        CVPixelBufferLockBaseAddress(imageBuffer, 0);

        void *baseAddress = (void *)CVPixelBufferGetBaseAddressOfPlane(imageBuffer, 0);

        const size_t bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer);
        const size_t bitsPerComponent = 8;
        const size_t width = CVPixelBufferGetWidth(imageBuffer);
        const size_t height = CVPixelBufferGetHeight(imageBuffer);

        CGContextRef bitmapContext = CGBitmapContextCreate(baseAddress, width, height, bitsPerComponent, bytesPerRow, colorSpace, (CGBitmapInfo)(kCGBitmapByteOrder32Little | kCGImageAlphaNoneSkipFirst));
        image = CGBitmapContextCreateImage(bitmapContext);

        CVPixelBufferUnlockBaseAddress(imageBuffer, 0);

        CGContextRelease(bitmapContext);
        CGColorSpaceRelease(colorSpace);
    }

    return image;
}


- (instancetype)initForSize:(CGSize)size stripWidth:(CGFloat)stripWidth stride:(NSUInteger)stride
{
    self = [super init];
    if (self) {

        _imageSize = size;
        _stride = stride;

        _stripeSize = CGSizeMake(
            stripWidth,
            size.height
        );

        [self _prepareImageOfSize:size];
    }
    return self;
}


- (void)dealloc
{
    if (_renderContext) {
        CGContextRelease(_renderContext);
    }
}


- (UIImage *)imageWithOrientation:(UIImageOrientation)orientation
{
    const CGFloat scale = [[UIScreen mainScreen] scale];

    CGImageRef cgImage = CGBitmapContextCreateImage(_renderContext);
    UIImage *image = [UIImage imageWithCGImage:cgImage scale:scale orientation:orientation];
    CGImageRelease(cgImage);

    return image;
}


- (void)addSampleBuffer:(CMSampleBufferRef)sampleBuffer
{
    NSDate *renderStartTime = [NSDate date];

    CGImageRef image = [self _createImageFromSampleBuffer:sampleBuffer];

    const CGRect imageRect = CGRectMake(
        0, 0,
        CGImageGetWidth(image), CGImageGetHeight(image)
    );

    NSMutableArray *maskRects = [[NSMutableArray alloc] init];
    CGRect maskRect = CGRectMake(
        _stripeSize.width * _stripeIndex, 0,
        _stripeSize.width, _stripeSize.height
    );

    // Scan the input sample buffer across the rendered image until we can't squeeze in any more...
    while (maskRect.origin.x < _imageSize.width) {

        [maskRects addObject:[NSValue valueWithCGRect:maskRect]];

        // Move the mask to the right
        maskRect.origin.x += _stripeSize.width * _stride;
    }

    // Convert maskRects NSMutableArray to something Core Graphics can use
    const int maskCount = (int)[maskRects count];
    CGRect *masks = malloc(sizeof(CGRect)*maskCount);

    for (int index = 0; index < maskCount; ++index) {
        masks[index] = [maskRects[index] CGRectValue];
    }

    // Perform the render
    CGContextSaveGState(_renderContext);

    CGContextClipToRects(_renderContext, masks, maskCount);
    CGContextDrawImage(_renderContext, imageRect, image);

    CGContextRestoreGState(_renderContext);

    free(masks);
    CGImageRelease(image);

    const NSTimeInterval renderDuration = [[NSDate date] timeIntervalSinceDate:renderStartTime];
    NSLog(@"Render time for contributor %d: %.3f msec", _stripeIndex, renderDuration * 1e3);

    // Move to the next stripe, allowing wrapping
    _stripeIndex = (_stripeIndex + 1) % _stride;
}

@end
