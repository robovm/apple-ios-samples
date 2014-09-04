/*
     File: AssetBrowserSource.m
 Abstract: Represents a source like the camera roll and vends AssetBrowserItems.
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

#import "AssetBrowserSource.h"

#import "DirectoryWatcher.h"

#import <MobileCoreServices/UTCoreTypes.h>
#import <MobileCoreServices/UTType.h>

#import <MediaPlayer/MediaPlayer.h>
#import <AssetsLibrary/AssetsLibrary.h>

@interface AssetBrowserSource () <DirectoryWatcherDelegate>

@property (nonatomic, copy) NSArray *items; // NSArray of AssetBrowserItems

@end


@implementation AssetBrowserSource

@synthesize name = sourceName, items = assetBrowserItems, delegate, type = sourceType;

- (NSString*)nameForSourceType
{
	NSString *name = nil;
	
	switch (sourceType) {
		case AssetBrowserSourceTypeFileSharing:
			name = NSLocalizedString(@"File Sharing", nil);
			break;
		case AssetBrowserSourceTypeCameraRoll:
			name = NSLocalizedString(@"Camera Roll", nil);
			break;
		case AssetBrowserSourceTypeIPodLibrary:
			name = NSLocalizedString(@"iPod Library", nil);
			break;
		default:
			name = nil;
			break;
	}
	
	return name;
}

+ (AssetBrowserSource*)assetBrowserSourceOfType:(AssetBrowserSourceType)sourceType
{
	return [[self alloc] initWithSourceType:sourceType];
}

- (id)initWithSourceType:(AssetBrowserSourceType)type
{
	if ((self = [super init])) {
		sourceType = type;
		sourceName = [self nameForSourceType];
		assetBrowserItems = [NSArray array];
		
		enumerationQueue = dispatch_queue_create("Browser Enumeration Queue", DISPATCH_QUEUE_SERIAL);
		dispatch_set_target_queue(enumerationQueue, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0));
	}
	return self;
}

- (void)updateBrowserItemsAndSignalDelegate:(NSArray*)newItems
{	
	self.items = newItems;

	/* Ideally we would reuse the AssetBrowserItems which remain unchanged between updates.
	 This could be done by maintaining a dictionary of assetURLs -> AssetBrowserItems.
	 This would also allow us to more easily tell our delegate which indices were added/removed
	 so that it could animate the table view updates. */
	
	if (self.delegate && [self.delegate respondsToSelector:@selector(assetBrowserSourceItemsDidChange:)]) {
		[self.delegate assetBrowserSourceItemsDidChange:self];
	}
}

- (void)dealloc 
{
	if (receivingIPodLibraryNotifications) {
		MPMediaLibrary *iPodLibrary = [MPMediaLibrary defaultMediaLibrary];
		[iPodLibrary endGeneratingLibraryChangeNotifications];
		[[NSNotificationCenter defaultCenter] removeObserver:self name:MPMediaLibraryDidChangeNotification object:nil];
	}
	
	if (assetsLibrary) {
		[[NSNotificationCenter defaultCenter] removeObserver:self name:ALAssetsLibraryChangedNotification object:nil];	
	}
	
	[directoryWatcher invalidate];
	directoryWatcher.delegate = nil;
}

#pragma mark -
#pragma mark iPod Library

- (void)updateIPodLibrary
{
	dispatch_async(enumerationQueue, ^(void) {
		// Grab videos from the iPod Library
		MPMediaQuery *videoQuery = [[MPMediaQuery alloc] init];
		
		NSMutableArray *items = [NSMutableArray arrayWithCapacity:0];
		NSArray *mediaItems = [videoQuery items];
		for (MPMediaItem *mediaItem in mediaItems) {
			NSURL *URL = (NSURL*)[mediaItem valueForProperty:MPMediaItemPropertyAssetURL];
			
			if (URL) {
				NSString *title = (NSString*)[mediaItem valueForProperty:MPMediaItemPropertyTitle];
				AssetBrowserItem *item = [[AssetBrowserItem alloc] initWithURL:URL title:title];
				[items addObject:item];
			}
		}
		
		dispatch_async(dispatch_get_main_queue(), ^(void) {
			[self updateBrowserItemsAndSignalDelegate:items];
		});
	});
}

- (void)iPodLibraryDidChange:(NSNotification*)changeNotification
{
	[self updateIPodLibrary];
}

- (void)buildIPodLibrary
{
	MPMediaLibrary *iPodLibrary = [MPMediaLibrary defaultMediaLibrary];
	receivingIPodLibraryNotifications = YES;
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(iPodLibraryDidChange:) 
												 name:MPMediaLibraryDidChangeNotification object:nil];
	[iPodLibrary beginGeneratingLibraryChangeNotifications];
	
	[self updateIPodLibrary];	
}

#pragma mark -
#pragma mark Assets Library

- (void)updateAssetsLibrary
{
	NSMutableArray *assetItems = [NSMutableArray arrayWithCapacity:0];
	ALAssetsLibrary *assetLibrary = assetsLibrary;
	
	[assetLibrary enumerateGroupsWithTypes:ALAssetsGroupAll usingBlock:^(ALAssetsGroup *group, BOOL *stop) {
		 if (group) {
			 [group setAssetsFilter:[ALAssetsFilter allVideos]];
			 [group enumerateAssetsUsingBlock:
			  ^(ALAsset *asset, NSUInteger index, BOOL *stopIt)
			  {
				  if (asset) {
					  ALAssetRepresentation *defaultRepresentation = [asset defaultRepresentation];
					  NSString *uti = [defaultRepresentation UTI];
					  NSURL *URL = [[asset valueForProperty:ALAssetPropertyURLs] valueForKey:uti];
					  NSString *title = [NSString stringWithFormat:@"%@ %lu", NSLocalizedString(@"Video", nil), [assetItems count]+1];
					  AssetBrowserItem *item = [[AssetBrowserItem alloc] initWithURL:URL title:title];
					  
					  [assetItems addObject:item];
				  }
			  }];
		 }
		// group == nil signals we are done iterating.
		else {
			dispatch_async(dispatch_get_main_queue(), ^{
				[self updateBrowserItemsAndSignalDelegate:assetItems];
			});
		}
	}
	failureBlock:^(NSError *error) {
		NSLog(@"error enumerating AssetLibrary groups %@\n", error);
	}];
}

- (void)assetsLibraryDidChange:(NSNotification*)changeNotification
{
	[self updateAssetsLibrary];
}

- (void)buildAssetsLibrary
{
	assetsLibrary = [[ALAssetsLibrary alloc] init];
	ALAssetsLibrary *notificationSender = nil;
	
	NSString *minimumSystemVersion = @"4.1";
	NSString *systemVersion = [[UIDevice currentDevice] systemVersion];
	if ([systemVersion compare:minimumSystemVersion options:NSNumericSearch] != NSOrderedAscending)
		notificationSender = assetsLibrary;
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(assetsLibraryDidChange:) 
												 name:ALAssetsLibraryChangedNotification object:notificationSender];
	[self updateAssetsLibrary];
}

#pragma mark -
#pragma mark iTunes File Sharing

- (NSArray*)browserItemsInDirectory:(NSString*)directoryPath
{
	NSMutableArray *paths = [NSMutableArray arrayWithCapacity:0];
	NSArray *subPaths = [[[NSFileManager alloc] init] contentsOfDirectoryAtPath:directoryPath error:nil];
	if (subPaths) {
		for (NSString *subPath in subPaths) {
			NSString *pathExtension = [subPath pathExtension];
			CFStringRef preferredUTI = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, (__bridge CFStringRef)pathExtension, NULL);
			BOOL fileConformsToUTI = UTTypeConformsTo(preferredUTI, kUTTypeAudiovisualContent);
			CFRelease(preferredUTI);
			NSString *path = [directoryPath stringByAppendingPathComponent:subPath];
			
			if (fileConformsToUTI) {
				[paths addObject:path];
			}
		}
	}
	
	NSMutableArray *browserItems = [NSMutableArray arrayWithCapacity:0];
	for (NSString *path in paths) {
		AssetBrowserItem *item = [[AssetBrowserItem alloc] initWithURL:[NSURL fileURLWithPath:path]];
		[browserItems addObject:item];
	}
	return browserItems;
}

- (void)directoryDidChange:(DirectoryWatcher *)folderWatcher
{
	NSString *documentsDirectory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
	dispatch_async(enumerationQueue, ^(void) {
		NSArray *browserItems = [self browserItemsInDirectory:documentsDirectory];
		dispatch_async(dispatch_get_main_queue(), ^(void) {
			[self updateBrowserItemsAndSignalDelegate:browserItems];
		});
	});
}

- (void)buildFileSharingLibrary
{
	NSString *documentsDirectory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
	NSArray *browserItems = [self browserItemsInDirectory:documentsDirectory];
	[self updateBrowserItemsAndSignalDelegate:browserItems];
	directoryWatcher = [DirectoryWatcher watchFolderWithPath:documentsDirectory delegate:self];
}

- (void)buildSourceLibrary
{
	if (haveBuiltSourceLibrary)
		return;
	
	switch (sourceType) {
		case AssetBrowserSourceTypeFileSharing:
			[self buildFileSharingLibrary];
			break;
		case AssetBrowserSourceTypeCameraRoll:
			[self buildAssetsLibrary];
			break;
		case AssetBrowserSourceTypeIPodLibrary:
			[self buildIPodLibrary];
			break;
		default:
			break;
	}
	
	haveBuiltSourceLibrary = YES;
}

@end
