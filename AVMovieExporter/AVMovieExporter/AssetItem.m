/*
     File: AssetItem.m
 Abstract: Model object that stores information about an asset such as its metadata, track information, and allows it to be exported.
  Version: 1.0
 
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
 
 Copyright (C) 2011 Apple Inc. All Rights Reserved.
 
 */


#import "AssetItem.h"
#import "VideoLibrary.h"

#import <MobileCoreServices/MobileCoreServices.h>

@interface AssetItem ()

@property(readonly, strong) AVAssetImageGenerator *imageGenerator;

@property(readonly, strong) AVAsset *videoAsset;
@property(readonly, unsafe_unretained) dispatch_once_t titleToken;
@property(readonly, unsafe_unretained) dispatch_once_t thumbnailToken;
@property(readonly, unsafe_unretained) dispatch_once_t metadataToken;
@property(readonly, unsafe_unretained) dispatch_once_t tracksToken;

@property(readwrite, unsafe_unretained) BOOL writingFile;

@end

@implementation AssetItem

@synthesize imageGenerator = _imageGenerator;
@synthesize exportSession = _exportSession;
@synthesize progressLabel = _progressLabel;
@synthesize finishedExport = _finishedExport;
@synthesize assetURL = _assetURL;
@synthesize title = _title;
@synthesize videoAsset = _videoAsset;
@synthesize metadata = _metadata;
@synthesize tracks = _tracks;
@synthesize thumbnail = _thumbnail;

@synthesize titleToken = _titleToken;
@synthesize thumbnailToken = _thumbnailToken;
@synthesize metadataToken = _metadataToken;
@synthesize tracksToken = _tracksToken;

@synthesize writingFile = _writingFile;

- (id)initWithURL:(NSURL *)url
{
    self = [super init];
    if (self) 
	{
		_assetURL = url;
		_videoAsset = [[AVURLAsset alloc] initWithURL:self.assetURL options:nil];
		_imageGenerator = [[AVAssetImageGenerator alloc] initWithAsset:_videoAsset];
		
		_title = [[_assetURL lastPathComponent] copy];
		_metadata = [NSMutableArray array];
		_thumbnail = [UIImage imageNamed:@"Browser-ErrorLoading"];
		_writingFile = NO;
    }
    
    return self;
}

- (BOOL)isEqual:(id)anObject
{
	if ([anObject isKindOfClass:[AssetItem class]])
	{
		AssetItem *assetObject = (AssetItem *)anObject;
		return [self.assetURL isEqual:assetObject.assetURL];
	}
	else
	{
		return NO;
	}
}

- (NSUInteger)hash
{
	return [self.assetURL hash];
}

#pragma mark - Load Asset Information

- (void)loadMetadataWithCompletionHandler:(void (^)(void))completionHandler
{
	__unsafe_unretained __block AssetItem *weakSelf = (AssetItem *)self;
	dispatch_once(&_metadataToken, ^{
		// Add metadata from all metadata formats
		NSLog(@"Loading metadata...");
		NSArray *keys = [[NSArray alloc] initWithObjects:@"commonMetadata", nil];
		[weakSelf.videoAsset loadValuesAsynchronouslyForKeys:keys completionHandler:^{
			
			[weakSelf.metadata removeAllObjects];
			for (NSString *format in [weakSelf.videoAsset availableMetadataFormats])
				[weakSelf.metadata addObjectsFromArray:[weakSelf.videoAsset metadataForFormat:format]];
			
			dispatch_async(dispatch_get_main_queue(), ^{
				completionHandler();
			});
		}];
	});
}

- (void)loadTracksWithCompletionHandler:(void (^)(void))completionHandler
{
	__unsafe_unretained __block AssetItem *weakSelf = (AssetItem *)self;
	dispatch_once(&_tracksToken, ^{
		NSLog(@"Loading tracks for %@...", weakSelf.title);
		NSArray *keys = [[NSArray alloc] initWithObjects:@"tracks", nil];
		[weakSelf.videoAsset loadValuesAsynchronouslyForKeys:keys completionHandler:^{
			
			[weakSelf resetExport];
			
			dispatch_async(dispatch_get_main_queue(), ^{
				completionHandler();
			});
		}];
	});
}

// Load the first frame of the video for a thumbnail
- (UIImage *)loadThumbnailWithCompletionHandler:(void (^)(void))completionHandler
{
	__unsafe_unretained __block AssetItem *weakSelf = (AssetItem *)self;
	dispatch_once(&_thumbnailToken, ^{
		[weakSelf.imageGenerator generateCGImagesAsynchronouslyForTimes:[NSArray arrayWithObject:[NSValue valueWithCMTime:kCMTimeZero]] 
													  completionHandler:^(CMTime requestedTime, CGImageRef image, CMTime actualTime, AVAssetImageGeneratorResult result, NSError *error) {
			if (result == AVAssetImageGeneratorSucceeded)
			{
				weakSelf.thumbnail = [UIImage imageWithCGImage:image];
				dispatch_async(dispatch_get_main_queue(), ^{
					NSLog(@"Loaded thumbnail for %@", weakSelf.title);
					completionHandler();
				});
			}
			else if (result == AVAssetImageGeneratorFailed)
			{
				NSLog(@"couldn't generate thumbnail, error:%@", error);
			}
		}];
	});
	
	return self.thumbnail;
}

- (NSString *)loadTitleWithCompletionHandler:(void (^)(void))completionHandler
{
	__unsafe_unretained __block AssetItem *weakSelf = (AssetItem *)self;
	dispatch_once(&_titleToken, ^{
		// Load the title from AVMetadataCommonKeyTitle
		NSLog(@"Loading title...");
		NSArray *key = [[NSArray alloc] initWithObjects:@"commonMetadata", nil];
		[weakSelf.videoAsset loadValuesAsynchronouslyForKeys:key 
									   completionHandler:^{
			NSArray *titles = [AVMetadataItem metadataItemsFromArray:weakSelf.videoAsset.commonMetadata withKey:AVMetadataCommonKeyTitle keySpace:AVMetadataKeySpaceCommon];
			if ([titles count] > 0)
			{
				// If there is only one title, then use it
				if ([titles count] == 1)
				{
					AVMetadataItem *titleItem = [titles objectAtIndex:0];
					weakSelf.title = [titleItem stringValue];
					dispatch_async(dispatch_get_main_queue(), ^{
						NSLog(@"Loaded title for %@", weakSelf.title);
						completionHandler();
					});
				}
				else
				{
					// If there are more than one, search for the proper locale
					NSArray *preferredLanguages = [NSLocale preferredLanguages];
					for (NSString *currentLanguage in preferredLanguages)
					{
						NSLocale *locale = [[NSLocale alloc] initWithLocaleIdentifier:currentLanguage];
						NSArray *titlesForLocale = [AVMetadataItem metadataItemsFromArray:titles withLocale:locale];
						if ([titlesForLocale count] > 0)
						{
							weakSelf.title = [[titlesForLocale objectAtIndex:0] stringValue];
							dispatch_async(dispatch_get_main_queue(), ^{
								NSLog(@"Loaded title for %@", weakSelf.title);
								completionHandler();
							});
							break;
						}
					}
				}
			}
		}];
	});

	return self.title;
}

#pragma mark - Metadata

// Report the metadata status while it is loading
- (NSString *)metadataLabelAtIndex:(NSUInteger)index
{
	NSString *metadataLabel = nil;
	
	// Get the status of the commonMetadata key
	NSError *error = nil;
	AVKeyValueStatus metadataLoadingStatus = [self.videoAsset statusOfValueForKey:@"commonMetadata" error:&error];
	if (metadataLoadingStatus == AVKeyValueStatusLoading)
	{
		metadataLabel = @"Loading metadata...";
	}
	else if (metadataLoadingStatus == AVKeyValueStatusFailed)
	{
		metadataLabel = @"Loading metadata failed!";
		NSLog(@"%@", error);
	}
	else if (metadataLoadingStatus == AVKeyValueStatusLoaded)
	{
		// When the metadata is loaded
		if (self.metadata.count > 0)
		{
			AVMetadataItem *metadataItem = [self.metadata objectAtIndex:index];
			
			if (metadataItem.commonKey != nil)
				metadataLabel = metadataItem.commonKey;
			else
				metadataLabel = [AssetItem stringFromKeyOfMetadataItem:metadataItem];
		}
	}
	
	return metadataLabel;
}

// Convert a four character code to an NSString
+ (NSString *)stringFromKeyOfMetadataItem:(AVMetadataItem *)metadataItem
{
	NSString *key = nil;
	if ([metadataItem.key isKindOfClass:[NSNumber class]])
	{
		NSInteger longValue = [(NSNumber *)metadataItem.key longValue];
		char *charSource = (char *)&longValue;
		char charValue[4] = {0};
		charValue[0] = charSource[3];
		charValue[1] = charSource[2];
		charValue[2] = charSource[1];
		charValue[3] = charSource[0];
		key = [[NSString alloc] initWithBytes:charValue length:4 encoding:NSASCIIStringEncoding];
	}
	else
	{
		key = [metadataItem.key description];
	}
	
	return key;
}

#pragma mark - Tracks

- (NSArray *)tracks
{
	return self.videoAsset.tracks;
}

// Report the track status while it is loading
- (NSString *)trackLabelAtIndex:(NSUInteger)index
{
	NSString *trackLabel = nil;
	
	// Get the status of the tracks key
	NSError *error = nil;
	AVKeyValueStatus trackLoadingStatus = [self.videoAsset statusOfValueForKey:@"tracks" error:&error];
	if (trackLoadingStatus == AVKeyValueStatusLoading)
	{
		trackLabel = @"Loading track...";
	}
	else if (trackLoadingStatus == AVKeyValueStatusFailed)
	{
		trackLabel = @"Loading track failed!";
		NSLog(@"%@", error);
	}
	else if (trackLoadingStatus == AVKeyValueStatusLoaded)
	{
		// When the tracks are loaded
		if (self.tracks.count > 0)
		{
			AVAssetTrack *track = [self.tracks objectAtIndex:index];
			trackLabel = NSLocalizedString(track.mediaType , nil);
		}
	}
	
	return trackLabel;
}

#pragma mark - Export Information

// Get the presets that are compatible with the AVAsset
- (NSArray *)supportedPresets
{
	NSMutableArray *presets = [NSMutableArray arrayWithArray:[AVAssetExportSession exportPresetsCompatibleWithAsset:self.videoAsset]];
	[presets removeObject:AVAssetExportPresetAppleM4A]; // Remove M4A because we are writing to the AssetLibrary.
	return [presets sortedArrayUsingComparator:^(id obj1, id obj2) {
		NSString *string1 = (NSString *)obj1;
		NSString *string2 = (NSString *)obj2;
		return [string1 compare:string2];
	}];
}

// Get the file types that are compatible with the preset and AVAsset combination
- (NSArray *)supportedFileTypes
{
	return [[self.exportSession supportedFileTypes] sortedArrayUsingComparator:^(id obj1, id obj2) {
		NSString *string1 = (NSString *)obj1;
		NSString *string2 = (NSString *)obj2;
		return [string1 compare:string2];
	}];
}

- (NSString *)preset
{
	return self.exportSession.presetName;
}

// When we change the preset we have to re-create the AVAssetExportSession
- (void)setPreset:(NSString *)preset
{
	if (self.exportSession == nil || ![self.exportSession.presetName isEqualToString:preset])
	{
		AVAssetExportSession *oldExportSession = self.exportSession;
		[oldExportSession cancelExport];
		
		// Create the new AVAssetExportSession and copy over the old properties
		AVAssetExportSession *temp = [[AVAssetExportSession alloc] initWithAsset:self.videoAsset presetName:preset];
		self.exportSession = temp;
		if (oldExportSession != nil)
		{
			NSArray *supportedFileTypes = self.supportedFileTypes;
			if ([supportedFileTypes containsObject:oldExportSession.outputFileType])
				self.exportSession.outputFileType = oldExportSession.outputFileType;
			else
				self.exportSession.outputFileType = [supportedFileTypes objectAtIndex:0];
				
			self.exportSession.shouldOptimizeForNetworkUse = oldExportSession.shouldOptimizeForNetworkUse;
		}
	}
}

#pragma mark - Performing Exports

- (void)exportAssetWithCompletionHandler:(void (^)(NSError *error))completionHandler
{
	// Choose a unique file name
    NSUInteger count = 0;
	NSString *filePath = nil;
	do {
		NSString *extension = (__bridge_transfer NSString *)UTTypeCopyPreferredTagWithClass((__bridge CFStringRef)self.exportSession.outputFileType, kUTTagClassFilenameExtension);
        NSString *fileNameNoExtension = [[self.assetURL URLByDeletingPathExtension] lastPathComponent];
		NSString *fileName = [NSString stringWithFormat:@"%@-%@-%lu",fileNameNoExtension , [self preset], count];
		filePath = NSTemporaryDirectory();
		filePath = [filePath stringByAppendingPathComponent:fileName];
		filePath = [filePath stringByAppendingPathExtension:extension];
        count++;
        
	} while ([[NSFileManager defaultManager] fileExistsAtPath:filePath]);
	
	NSURL *outputURL = [NSURL fileURLWithPath:filePath];
	
	// Set up the AVAssetExportSession
	self.exportSession.metadata = [self.metadata copy];
	self.exportSession.outputURL = outputURL;
	
	__unsafe_unretained __block AssetItem *weakSelf = (AssetItem *)self;
	[self.exportSession exportAsynchronouslyWithCompletionHandler:^{
		if (weakSelf.exportSession.status == AVAssetExportSessionStatusFailed)
		{
			completionHandler(weakSelf.exportSession.error);
		}
		else if (weakSelf.exportSession.status == AVAssetExportSessionStatusCompleted)
		{
			weakSelf.writingFile = YES;
			[VideoLibrary saveMovieAtPathToAssetLibrary:outputURL withCompletionHandler:^(NSError *error){
				dispatch_async(dispatch_get_main_queue(), ^{
					weakSelf.writingFile = NO;
					completionHandler(error);
				});
			}];
		}
	}];
}

- (void)resetExport
{
	[self.exportSession cancelExport];
	self.exportSession = nil;
	self.preset = AVAssetExportPresetMediumQuality;
	self.exportSession.outputFileType = AVFileTypeQuickTimeMovie;
	self.exportSession.shouldOptimizeForNetworkUse = NO;
}

- (NSString *)progressLabel
{
	NSString *label = nil;
	
	if (self.writingFile)
	{
		label = @"Writing file to Asset Library";
	}
	else
	{
		switch (self.exportSession.status) {
			case AVAssetExportSessionStatusCancelled:
				label = @"Export Cancelled";
				break;
			case AVAssetExportSessionStatusExporting:
				label = @"Exporting...";
				break;
			case AVAssetExportSessionStatusCompleted:
				label = @"Export Completed!";
				break;
			case AVAssetExportSessionStatusFailed:
				label = @"Export Failed!";
				break;
			case AVAssetExportSessionStatusWaiting:
				label = @"Waiting to export...";
				break;
			case AVAssetExportSessionStatusUnknown:
				label = @"Export has not started";
				break;
				
			default:
				break;
		}
	}
	
	return label;
}

- (BOOL)finishedExport
{
	BOOL finishedExport = NO;
	AVAssetExportSessionStatus status = self.exportSession.status;
	
	if (!self.writingFile && 
		(status == AVAssetExportSessionStatusCancelled || 
		status == AVAssetExportSessionStatusCompleted || 
		status == AVAssetExportSessionStatusFailed))
		finishedExport = YES;
	
	return finishedExport;
}

@end
