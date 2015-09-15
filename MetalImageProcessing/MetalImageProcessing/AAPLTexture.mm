/*
 Copyright (C) 2015 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 Simple Utility class for creating a 2d texture
 */

#import <UIKit/UIKit.h>

#import "AAPLTexture.h"

@implementation AAPLTexture
{
@private
    id <MTLTexture>  _texture;
    MTLTextureType   _target;
    uint32_t         _width;
    uint32_t         _height;
    uint32_t         _depth;
    uint32_t         _format;
    BOOL             _flip;
    NSString        *_path;
}

- (instancetype) initWithResourceName:(NSString *)name
                            extension:(NSString *)ext
{
    NSString *path = [[NSBundle mainBundle] pathForResource:name
                                                     ofType:ext];
    
    if(!path)
    {
        return nil;
    } // if
    
    self = [super init];
    
    if(self)
    {
        _path     = path;
        _width    = 0;
        _height   = 0;
        _depth    = 1;
        _format   = MTLPixelFormatRGBA8Unorm;
        _target   = MTLTextureType2D;
        _texture  = nil;
        _flip     = YES;
    } // if
    
    return self;
} // initWithResourceName

- (void) dealloc
{
    _path    = nil;
    _texture = nil;
} // dealloc

- (void) setFlip:(BOOL)flip
{
    _flip = flip;
} // setFlip

// assumes png file
- (BOOL) finalize:(id <MTLDevice>)device
{
    if(_texture)
    {
        return YES;
    } // if
    
    UIImage *pImage = [UIImage imageWithContentsOfFile:_path];
    
    if(!pImage)
    {
        return NO;
    } // if
    
    CGColorSpaceRef pColorSpace = CGColorSpaceCreateDeviceRGB();
    
    if(!pColorSpace)
    {
        return NO;
    } // if
    
    _width  = uint32_t(CGImageGetWidth(pImage.CGImage));
    _height = uint32_t(CGImageGetHeight(pImage.CGImage));
    
    uint32_t width    = _width;
    uint32_t height   = _height;
    uint32_t rowBytes = width * 4;
    
    CGContextRef pContext = CGBitmapContextCreate(NULL,
                                                  width,
                                                  height,
                                                  8,
                                                  rowBytes,
                                                  pColorSpace,
                                                  CGBitmapInfo(kCGImageAlphaPremultipliedLast));
    
    CGColorSpaceRelease(pColorSpace);
    
    if(!pContext)
    {
        return NO;
    } // if
    
    CGRect bounds = CGRectMake(0.0f, 0.0f, width, height);
    
    CGContextClearRect(pContext, bounds);
    
    // Vertical Reflect
    if(_flip)
    {
        CGContextTranslateCTM(pContext, width, height);
        CGContextScaleCTM(pContext, -1.0, -1.0);
    } // if
    
    CGContextDrawImage(pContext, bounds, pImage.CGImage);
    
    MTLTextureDescriptor *pTexDesc = [MTLTextureDescriptor texture2DDescriptorWithPixelFormat:MTLPixelFormatRGBA8Unorm
                                                                                        width:width
                                                                                       height:height
                                                                                    mipmapped:NO];
    if(!pTexDesc)
    {
        CGContextRelease(pContext);

        return NO;
    } // if
    
    _target  = pTexDesc.textureType;
    _texture = [device newTextureWithDescriptor:pTexDesc];
    
    if(!_texture)
    {
        CGContextRelease(pContext);
        
        return NO;
    } // if
    
    const void *pPixels = CGBitmapContextGetData(pContext);
    
    if(pPixels != NULL)
    {
        MTLRegion region = MTLRegionMake2D(0, 0, width, height);
        
        [_texture replaceRegion:region
                    mipmapLevel:0
                      withBytes:pPixels
                    bytesPerRow:rowBytes];
    } // if
    
    CGContextRelease(pContext);
    
    return YES;
} // finalize

@end
