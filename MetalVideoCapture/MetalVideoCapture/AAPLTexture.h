/*
 Copyright (C) 2015 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 Texture Loading classes for Metal. Includes examples of how to load a 2D, and Cubemap textures.
 */

#import <UIKit/UIKit.h>
#import <Metal/Metal.h>

@interface AAPLTexture : NSObject

@property (readonly) id <MTLTexture> texture;
@property (readonly) uint32_t width;
@property (readonly) uint32_t height;
@property (readonly) uint32_t depth;
@property (readonly) uint32_t target;
@property (readonly) uint32_t pixelFormat;
@property (readonly) BOOL hasAlpha;
@property (readonly) NSString *pathToTextureFile;

- (id)initWithResourceName:(NSString *)name extension:(NSString *)ext;
- (BOOL)loadIntoTextureWithDevice:(id<MTLDevice>)device;

@end

@interface AAPLTexture2D : AAPLTexture
@end

@interface AAPLTextureCubeMap : AAPLTexture
@end