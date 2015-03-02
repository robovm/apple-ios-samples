/*
 Copyright (C) 2015 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 Texture Loading classes for Metal. Includes examples of how to load a 2D, and Cubemap textures.
 */

#import "AAPLTexture.h"

@interface AAPLTexture ()
@property (readwrite) id <MTLTexture> texture;
@property (readwrite) uint32_t width;
@property (readwrite) uint32_t height;
@property (readwrite) uint32_t pixelFormat;
@property (readwrite) uint32_t target;
@property (readwrite) BOOL hasAlpha;
@end

@implementation AAPLTexture

- (instancetype)initWithResourceName:(NSString *)name extension:(NSString *)ext
{
    NSString *path = [[NSBundle mainBundle] pathForResource:name ofType:ext];
    if (!path)
        return nil;
    
    self = [super init];
    if (self) {
        _pathToTextureFile = path;
        _width = _height = 0;
        _depth = 1;
    }
    return self;
}

- (BOOL)loadIntoTextureWithDevice:(id <MTLDevice>)device
{
    // to be implemented by subclasses
    assert(0);
}
@end

@implementation AAPLTexture2D

// assumes png file
- (BOOL)loadIntoTextureWithDevice:(id <MTLDevice>)device
{
    UIImage *image = [UIImage imageWithContentsOfFile:self.pathToTextureFile];
    if (!image)
        return NO;
    
    self.width = (uint32_t)CGImageGetWidth(image.CGImage);
    self.height = (uint32_t)CGImageGetHeight(image.CGImage);
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate( NULL, self.width, self.height, 8, 4 * self.width, colorSpace, (CGBitmapInfo)kCGImageAlphaPremultipliedLast );
    CGContextDrawImage( context, CGRectMake( 0, 0, self.width, self.height ), image.CGImage );
    
    MTLTextureDescriptor *texDesc = [MTLTextureDescriptor texture2DDescriptorWithPixelFormat:MTLPixelFormatRGBA8Unorm
                                                                                     width:self.width
                                                                                    height:self.height
                                                                                 mipmapped:NO];
    self.target = texDesc.textureType;
    self.texture = [device newTextureWithDescriptor:texDesc];
    if (!self.texture)
        return NO;
    
    [self.texture replaceRegion:MTLRegionMake2D(0, 0, self.width, self.height)
                    mipmapLevel:0
                      withBytes:CGBitmapContextGetData(context)
                    bytesPerRow:4 * self.width];
    
    CGColorSpaceRelease( colorSpace );
    CGContextRelease(context);
    
    return YES;
}

@end

@implementation AAPLTextureCubeMap

// assumes png file
- (BOOL)loadIntoTextureWithDevice:(id <MTLDevice>)device
{
    UIImage *image = [UIImage imageWithContentsOfFile:self.pathToTextureFile];
    if (!image)
        return NO;
    
    self.width = (uint32_t)CGImageGetWidth(image.CGImage);
    self.height = (uint32_t)CGImageGetHeight(image.CGImage);
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate( NULL, self.width, self.height, 8, 4 * self.width, colorSpace, (CGBitmapInfo)kCGImageAlphaPremultipliedLast );
    CGContextDrawImage( context, CGRectMake( 0, 0, self.width, self.height ), image.CGImage );
    
	unsigned Npixels = self.width * self.width;
    MTLTextureDescriptor *texDesc = [MTLTextureDescriptor textureCubeDescriptorWithPixelFormat:MTLPixelFormatRGBA8Unorm size:self.width mipmapped:NO];
    self.target = texDesc.textureType;
    self.texture = [device newTextureWithDescriptor:texDesc];
    if (!self.texture)
        return NO;
    
    void *imageData = CGBitmapContextGetData(context);
    for (int i = 0; i < 6; i++)
	{
        [self.texture replaceRegion:MTLRegionMake2D(0, 0, self.width, self.width)
                        mipmapLevel:0
                              slice:i
                          withBytes:imageData + (i * Npixels * 4)
                        bytesPerRow:4 * self.width
                      bytesPerImage:Npixels * 4];
    }
    
    CGColorSpaceRelease( colorSpace );
    CGContextRelease(context);
    
    return YES;
}

@end
