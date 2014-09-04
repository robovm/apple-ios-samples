/*
     File: AssetBrowserItem.m
 Abstract: Represents an asset in AssetBrowserController.
  Version: 1.3
 
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


#import "AssetBrowserItem.h"

#import <AVFoundation/AVFoundation.h>

#include <AssertMacros.h>

@interface AssetBrowserItem ()

- (AVAsset*)copyAssetIfCreated;

@property (nonatomic, copy) NSString *title;
@property (nonatomic, strong) UIImage *thumbnailImage;
@property (nonatomic, readonly) BOOL canGenerateThumbnails;
@property (nonatomic, readonly) BOOL audioOnly;

@end

@implementation AssetBrowserItem

@synthesize URL = assetURL, title = assetTitle, haveRichestTitle;
@synthesize thumbnailImage, canGenerateThumbnails, audioOnly;

- (id)initWithURL:(NSURL*)URL
{
	return [self initWithURL:URL title:nil];
}

- (id)initWithURL:(NSURL*)URL title:(NSString*)title
{
	if ((self = [super init])) {
		assetURL = URL;
		if (assetURL == nil) {
			return nil;
		}
		haveRichestTitle = title ? YES : NO;
		assetTitle = title ? [title copy] : [[URL lastPathComponent] stringByDeletingPathExtension];
		
		// Assume we can generate a thumb unless we have loaded the assets or tried already and know otherwise.
		canGenerateThumbnails = YES;
		
		// Assets can only be accessed from one thread at a time.
		assetQueue = dispatch_queue_create("Asset Queue", DISPATCH_QUEUE_SERIAL);
	}
	return self;
}

- (id)initWithAssetItem:(AssetBrowserItem*)browserItem
{
	if ((self = [super init])) {
		// Inititialization time properties.
		assetURL = browserItem.URL;

		// May have been an initialization time property.
		assetTitle = browserItem.title;
		haveRichestTitle = browserItem.haveRichestTitle;
		
		thumbnailImage = browserItem.thumbnailImage;
		asset = [browserItem copyAssetIfCreated];
		
		canGenerateThumbnails = browserItem.canGenerateThumbnails;
		audioOnly = browserItem.audioOnly;
		
		assetQueue = dispatch_queue_create("Asset Queue", DISPATCH_QUEUE_SERIAL);
	}
	return self;
}

- (id)copyWithZone:(NSZone *)zone
{
	AssetBrowserItem *copy = [[AssetBrowserItem allocWithZone:zone] initWithAssetItem:self];
	return copy;
}

// Do simple equality based on the item's URL.
- (BOOL)isEqual:(id)anObject
{
	if (self == anObject)
		return YES;
	
	if ([anObject isKindOfClass:[AssetBrowserItem class]]) {
		AssetBrowserItem *item = anObject;
		NSURL *myURL = self.URL;
		NSURL *theirURL = item.URL;
		if (myURL && theirURL) {
			return [myURL isEqual:theirURL];
		}
		return NO;
	}
	return NO;
}

- (NSUInteger)hash
{
	if (self.URL) {
		return [self.URL hash];
	}
	else {
		return [super hash];
	}
}


// Must be called on assetQueue. Will handle lazy asset creation.
- (AVAsset*)getAssetInternal
{
	check( dispatch_get_current_queue() == assetQueue );
	
	if (asset == nil) {
		asset = [[AVURLAsset alloc] initWithURL:assetURL options:nil];
	}
	return  asset;
}

// Our public accessor always copies the asset since assets can only safely be accessed from one thread at a time.
- (AVAsset*)asset
{	
	__block AVAsset *theAsset = nil;
	dispatch_sync(assetQueue, ^(void) {
		theAsset = [[self getAssetInternal] copy];
	});
	
	return theAsset;
}

- (AVAsset*)copyAssetIfCreated
{	
	__block AVAsset *theAsset = nil;
	dispatch_sync(assetQueue, ^(void) {
		theAsset = [asset copy];
	});
	return theAsset;
}

- (void)generateTitleFromMetadataAsynchronouslyWithCompletionHandler:(void (^)(NSString *title))handler
{
	if (haveRichestTitle) {
		dispatch_async(dispatch_get_main_queue(), ^(void) {
			if (handler)
				handler(self.title);
		});
		return;
	}
	dispatch_async(assetQueue, ^(void) {
		
		AVAsset *titleAsset = [self getAssetInternal];
		
		[titleAsset loadValuesAsynchronouslyForKeys:[NSArray arrayWithObject:@"commonMetadata"] completionHandler:^{
			dispatch_async(assetQueue, ^(void) {
				NSString* title = nil;
				
				NSArray *titles = [AVMetadataItem metadataItemsFromArray:[titleAsset commonMetadata] withKey:AVMetadataCommonKeyTitle keySpace:AVMetadataKeySpaceCommon];
				if ([titles count] > 0)
				{
					// Try to get a title that matches one of the user's preferred languages.
					NSArray *preferredLanguages = [NSLocale preferredLanguages];
					
					for (NSString *thisLanguage in preferredLanguages)
					{
						NSLocale *locale = [[NSLocale alloc] initWithLocaleIdentifier:thisLanguage];
						NSArray *titlesForLocale = [AVMetadataItem metadataItemsFromArray:titles withLocale:locale];
						if ([titlesForLocale count] > 0)
						{
							title = [[titlesForLocale objectAtIndex:0] stringValue];
							break;
						}
					}
					
					// No matches in any of the preferred languages. Just use the primary title metadata we find.
					if (title == nil)
					{
						title = [[titles objectAtIndex:0] stringValue];
					}
				}
				
				dispatch_async(dispatch_get_main_queue(), ^{
					haveRichestTitle = YES;
					if (title)
						self.title = title;
					if (handler)
						handler(self.title);
				});
			});
		}];
	});
}

CGRect makeRectWithAspectRatioOutsideRect(CGSize aspectRatio, CGRect containerRect)
{
	CGSize scale = CGSizeMake(containerRect.size.width / aspectRatio.width, containerRect.size.height / aspectRatio.height);
	CGFloat maxScale = fmax(scale.width, scale.height);
	
	CGPoint centerPoint = CGPointMake(CGRectGetMidX(containerRect), CGRectGetMidY(containerRect));
	CGSize size = CGSizeMake(aspectRatio.width * maxScale, aspectRatio.height * maxScale);
	return CGRectMake(centerPoint.x - 0.5f * size.width, centerPoint.y - 0.5f * size.height, size.width, size.height);
}

- (CGSize)maxSizeForImageGeneratorToCropAsset:(AVAsset*)thumbnailAsset toSize:(CGSize)size
{
	CGSize naturalSize = CGSizeZero;
	CGSize naturalSizeTransformed = CGSizeZero;
	
	NSArray *videoTracks = [thumbnailAsset tracksWithMediaType:AVMediaTypeVideo];
	if ( ([videoTracks count] > 0) ) {
		AVAssetTrack *videoTrack = [videoTracks objectAtIndex:0];
		NSArray *formatDescriptions = [videoTrack formatDescriptions];
		if ([formatDescriptions count] > 0) {
			CMVideoFormatDescriptionRef videoFormatDescription = (__bridge CMFormatDescriptionRef)[formatDescriptions objectAtIndex:0];
			naturalSize = CMVideoFormatDescriptionGetPresentationDimensions(videoFormatDescription, YES, YES);
			naturalSizeTransformed = CGSizeApplyAffineTransform (naturalSize, videoTrack.preferredTransform);
			naturalSizeTransformed.width = fabs(naturalSizeTransformed.width);
			naturalSizeTransformed.height = fabs(naturalSizeTransformed.height);
		}
		else {
			return CGSizeZero;
		}
	}
	else {
		return CGSizeZero;
	}
	
	CGRect croppedRect = CGRectZero;
	croppedRect.size = size;
	CGRect containerRect = makeRectWithAspectRatioOutsideRect(naturalSizeTransformed, croppedRect);
	containerRect.origin = CGPointZero;
	containerRect = CGRectIntegral(containerRect);
	
	return containerRect.size;
}

- (UIImage*)copyImageFromCGImage:(CGImageRef)image croppedToSize:(CGSize)size
{
	UIImage *thumbUIImage = nil;
	
	CGRect thumbRect = CGRectMake(0.0, 0.0, CGImageGetWidth(image), CGImageGetHeight(image));
	CGRect cropRect = AVMakeRectWithAspectRatioInsideRect(size, thumbRect);
	cropRect.origin.x = round(cropRect.origin.x);
	cropRect.origin.y = round(cropRect.origin.y);
	cropRect = CGRectIntegral(cropRect);
	CGImageRef croppedThumbImage = CGImageCreateWithImageInRect(image, cropRect);
	thumbUIImage = [[UIImage alloc] initWithCGImage:croppedThumbImage];
	CGImageRelease(croppedThumbImage);
	
	return thumbUIImage;
}

// Must be called on assetQueue.
- (BOOL)assetHasVideoTrack:(AVAsset*)thumbnailAsset
{	
	check( dispatch_get_current_queue() == assetQueue );
	
	NSArray *videoTracks = [thumbnailAsset tracksWithMediaType:AVMediaTypeVideo];
	if ([videoTracks count] == 0) {
		canGenerateThumbnails = NO;
		NSArray *audioTracks = [thumbnailAsset tracksWithMediaType:AVMediaTypeAudio];
		if ([audioTracks count] != 0) {
			audioOnly = YES;
		}
		return NO;
	}
	return YES;
}

// Must be called on assetQueue.
- (void)generateNonVideoThumbnailWithSize:(CGSize)size fillMode:(AssetBrowserItemFillMode)mode completionHandler:(void (^)(UIImage *thumbnail))handler
{	
	check( dispatch_get_current_queue() == assetQueue );
	
	UIImage *thumb = nil;
	if (audioOnly) {
		thumb = [UIImage imageNamed:@"Browser-AudioOnly"];
	}
	else {
		thumb = [UIImage imageNamed:@"Browser-ErrorLoading"];
	}
	
	if ( mode == AssetBrowserItemFillModeCrop ) {
		CGRect boundingRect = CGRectZero;
		boundingRect.size = thumb.size;
		boundingRect.size.width *= thumb.scale;
		boundingRect.size.height *= thumb.scale;
		
		CGSize cropSize = AVMakeRectWithAspectRatioInsideRect(size, boundingRect).size;
		if ( !CGSizeEqualToSize(cropSize, size) ) {
			thumb = [self copyImageFromCGImage:[thumb CGImage] croppedToSize:cropSize];
		}
	}
	
	dispatch_async(dispatch_get_main_queue(), ^(void) {
		self.thumbnailImage = thumb;
		
		if (handler) {		
			handler(thumb);
		}	
	});
}

// Must be called on assetQueue.
- (void)generateThumbnailFromAsset:(AVAsset*)thumbnailAsset withSize:(CGSize)size fillMode:(AssetBrowserItemFillMode)mode completionHandler:(void (^)(UIImage *thumbnail))handler
{	
	check( dispatch_get_current_queue() == assetQueue );
	
	AVAssetImageGenerator *imageGenerator = [[AVAssetImageGenerator alloc] initWithAsset:thumbnailAsset];
	
	imageGenerator.appliesPreferredTrackTransform = YES;
	
	if ( mode == AssetBrowserItemFillModeAspectFit )
		imageGenerator.maximumSize = size;
	if ( mode == AssetBrowserItemFillModeCrop )
		imageGenerator.maximumSize = [self maxSizeForImageGeneratorToCropAsset:thumbnailAsset toSize:size];
	
	NSValue *imageTimeValue = [NSValue valueWithCMTime:CMTimeMake(2, 1)];
	
	[imageGenerator generateCGImagesAsynchronouslyForTimes:[NSArray arrayWithObject:imageTimeValue] completionHandler:
	 ^(CMTime requestedTime, CGImageRef image, CMTime actualTime, AVAssetImageGeneratorResult result, NSError *error) 
	 {	
		 if (result == AVAssetImageGeneratorFailed) {
			 dispatch_sync(assetQueue, ^(void) {
				 canGenerateThumbnails = NO;
				 [self generateNonVideoThumbnailWithSize:size fillMode:mode completionHandler:handler];
			 });
		 }
		 else {
			 UIImage *thumbUIImage = nil;
			 if (image) {
				 if (mode == AssetBrowserItemFillModeCrop) {
					 thumbUIImage = [self copyImageFromCGImage:image croppedToSize:size];
				 }
				 else {
					 thumbUIImage = [[UIImage alloc] initWithCGImage:image];
				 }
			 }
			 dispatch_async(dispatch_get_main_queue(), ^{
				 self.thumbnailImage = thumbUIImage;
				 
				 if (handler) {
					 handler(self.thumbnailImage);
				 }
			 });
		 }
		 
	 }];
}

- (void)generateThumbnailAsynchronouslyWithSize:(CGSize)size fillMode:(AssetBrowserItemFillMode)mode completionHandler:(void (^)(UIImage *thumbnail))handler
{	
	dispatch_async(assetQueue, ^(void) {
		if (!canGenerateThumbnails) {
			[self generateNonVideoThumbnailWithSize:size fillMode:mode completionHandler:handler];
			return;
		}
		
		AVAsset *thumbnailAsset = [self getAssetInternal];
		
		[thumbnailAsset loadValuesAsynchronouslyForKeys:[NSArray arrayWithObject:@"tracks"] completionHandler:^(void) {
			dispatch_async(assetQueue, ^(void) {
				AVKeyValueStatus postLoadingStatus = [thumbnailAsset statusOfValueForKey:@"tracks" error:NULL];
				if ((postLoadingStatus == AVKeyValueStatusLoaded) && [self assetHasVideoTrack:thumbnailAsset]) {
					[self generateThumbnailFromAsset:thumbnailAsset withSize:size fillMode:mode completionHandler:handler];
				}
				else {
					canGenerateThumbnails = NO;
					[self generateNonVideoThumbnailWithSize:size fillMode:mode completionHandler:handler];
				}
			});
		}];
	});
}

- (UIImage*)placeHolderImage
{
	return [UIImage imageNamed:@"Browser-Placeholder"];
}

- (void)clearThumbnailCache
{
	self.thumbnailImage = nil;
}

- (void)clearAssetCache
{
	dispatch_sync(assetQueue, ^(void) {
		asset = nil;
	});
}

- (NSString*)description
{
	return [NSString stringWithFormat:@"<AssetBrowserItem: %p, '%@'>", self, self.title];
}

@end
