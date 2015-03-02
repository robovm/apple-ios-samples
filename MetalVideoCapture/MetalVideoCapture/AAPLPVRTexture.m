/*
 Copyright (C) 2015 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 PVRTC Texture Loading classes for Metal. Based on the Apple Sample PVRTextureLoader, but ported to Metal.
  http://developer.apple.com/library/ios/#samplecode/PVRTextureLoader
 */

#import "AAPLPVRTexture.h"

#define PVR_TEXTURE_FLAG_TYPE_MASK	0xff

static char gPVRTexIdentifier[4] = "PVR!";

enum
{
	kPVRTextureFlagTypePVRTC_2 = 24,
	kPVRTextureFlagTypePVRTC_4
};

typedef struct _PVRTexHeader
{
	uint32_t headerLength;
	uint32_t height;
	uint32_t width;
	uint32_t numMipmaps;
	uint32_t flags;
	uint32_t dataLength;
	uint32_t bpp;
	uint32_t bitmaskRed;
	uint32_t bitmaskGreen;
	uint32_t bitmaskBlue;
	uint32_t bitmaskAlpha;
	uint32_t pvrTag;
	uint32_t numSurfs;
} PVRTexHeader;

@interface AAPLTexture ()
@property (readwrite) id <MTLTexture> texture;
@property (readwrite) uint32_t width;
@property (readwrite) uint32_t height;
@property (readwrite) uint32_t pixelFormat;
@property (readwrite) uint32_t target;
@property (readwrite) BOOL hasAlpha;
@end

@implementation AAPLPVRTexture
{
    // The original compressed data
    NSData* _data;
	NSMutableArray *_imageData;
}

- (BOOL)unpack
{
	BOOL success = FALSE;
	PVRTexHeader *header = NULL;
	uint32_t flags, pvrTag;
	uint32_t dataLength = 0, dataOffset = 0, dataSize = 0;
	uint32_t blockSize = 0, widthBlocks = 0, heightBlocks = 0;
	uint32_t width = 0, height = 0, bpp = 4;
	uint8_t *bytes = NULL;
	uint32_t formatFlags;
	
	header = (PVRTexHeader *)[_data bytes];
	
	pvrTag = CFSwapInt32LittleToHost(header->pvrTag);

	if (gPVRTexIdentifier[0] != ((pvrTag >>  0) & 0xff) ||
		gPVRTexIdentifier[1] != ((pvrTag >>  8) & 0xff) ||
		gPVRTexIdentifier[2] != ((pvrTag >> 16) & 0xff) ||
		gPVRTexIdentifier[3] != ((pvrTag >> 24) & 0xff))
	{
		return FALSE;
	}
	
	flags = CFSwapInt32LittleToHost(header->flags);
	formatFlags = flags & PVR_TEXTURE_FLAG_TYPE_MASK;
	
	if (formatFlags == kPVRTextureFlagTypePVRTC_4 || formatFlags == kPVRTextureFlagTypePVRTC_2)
	{
		[_imageData removeAllObjects];
		
		if (formatFlags == kPVRTextureFlagTypePVRTC_4)
			self.pixelFormat = MTLPixelFormatPVRTC_RGBA_4BPP;
		else if (formatFlags == kPVRTextureFlagTypePVRTC_2)
			self.pixelFormat = MTLPixelFormatPVRTC_RGBA_2BPP;
	
		self.width = width = CFSwapInt32LittleToHost(header->width);
		self.height = height = CFSwapInt32LittleToHost(header->height);

		if (CFSwapInt32LittleToHost(header->bitmaskAlpha))
			self.hasAlpha = TRUE;
		else
			self.hasAlpha = FALSE;
		
		dataLength = CFSwapInt32LittleToHost(header->dataLength);
		
		bytes = ((uint8_t *)[_data bytes]) + sizeof(PVRTexHeader);
		
		// Calculate the data size for each texture level and respect the minimum number of blocks
		while (dataOffset < dataLength)
		{
			if (formatFlags == kPVRTextureFlagTypePVRTC_4)
			{
				blockSize = 4 * 4; // Pixel by pixel block size for 4bpp
				widthBlocks = width / 4;
				heightBlocks = height / 4;
				bpp = 4;
			}
			else
			{
				blockSize = 8 * 4; // Pixel by pixel block size for 2bpp
				widthBlocks = width / 8;
				heightBlocks = height / 4;
				bpp = 2;
			}
			
			// Clamp to minimum number of blocks
			if (widthBlocks < 2)
				widthBlocks = 2;
			if (heightBlocks < 2)
				heightBlocks = 2;

			dataSize = widthBlocks * heightBlocks * ((blockSize  * bpp) / 8);
			
			[_imageData addObject:[NSData dataWithBytes:bytes+dataOffset length:dataSize]];
			
			dataOffset += dataSize;
			
			width = MAX(width >> 1, 1);
			height = MAX(height >> 1, 1);
		}
				  
		success = TRUE;
	}
	
	return success;
}

- (BOOL)loadIntoTextureWithDevice:(id <MTLDevice>)device
{
    _data = [NSData dataWithContentsOfFile:self.pathToTextureFile];
    _imageData = [[NSMutableArray alloc] initWithCapacity:10];
    
    [self unpack];
    
	int width = self.width;
	int height = self.height;
	NSData *data;
	
    MTLTextureDescriptor *texDesc = [MTLTextureDescriptor texture2DDescriptorWithPixelFormat:self.pixelFormat
                                                                                     width:width
                                                                                    height:height
                                                                                 mipmapped:YES];
    self.texture = [device newTextureWithDescriptor:texDesc];
    if (!self.texture)
        return FALSE;
    
    self.target = texDesc.textureType;
    texDesc.mipmapLevelCount = [_imageData count];
	for (int i=0; i < [_imageData count]; i++)
	{
		data = [_imageData objectAtIndex:i];
        
        [self.texture replaceRegion:MTLRegionMake2D(0, 0, width, height)
                        mipmapLevel:i
                          withBytes:[data bytes]
                        bytesPerRow:0 ];
        
		width = MAX(width >> 1, 1);
		height = MAX(height >> 1, 1);
	}
	
	[_imageData removeAllObjects];
	
	return TRUE;
}

@end
