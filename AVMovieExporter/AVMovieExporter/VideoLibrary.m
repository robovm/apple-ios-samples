/*
     File: VideoLibrary.m
 Abstract: Class that mediates the interaction between the controllers and the Media and Asset Library, as well as the contents of the app bundle.
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


#import "VideoLibrary.h"
#import "AssetItem.h"

#import <MediaPlayer/MediaPlayer.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import <MobileCoreServices/MobileCoreServices.h>


@interface VideoLibrary ()

- (void)buildMediaLibrary;
- (void)buildAssetLibrary;
- (void)buildApplicationBundleLibrary;

- (void)addURL:(NSURL *)url;


@property(readwrite, strong) NSMutableArray *assetItems;
@property(readonly, unsafe_unretained) dispatch_queue_t assetItemsQueue;

@property(readonly, unsafe_unretained) dispatch_group_t libraryGroup;
@property(readonly, unsafe_unretained) dispatch_queue_t libraryQueue;

@end

@implementation VideoLibrary

@synthesize assetItems = _assetItems;
@synthesize assetItemsQueue = _assetItemsQueue;

@synthesize libraryGroup = _libraryGroup;
@synthesize libraryQueue = _libraryQueue;

- (id)initWithLibraryChangedHandler:(void (^)(void))libraryChangedHandler
{
    self = [super init];
    if (self) 
	{
		_assetItems = [NSMutableArray array];
		_assetItemsQueue = dispatch_queue_create("com.apple.avmovieexporter.assetItemLibraryQueue", DISPATCH_QUEUE_SERIAL);
		
		_libraryGroup = dispatch_group_create();
		_libraryQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0);
		
		// Update the table view whenever the library changes
		[[NSNotificationCenter defaultCenter] addObserverForName:ALAssetsLibraryChangedNotification 
														  object:nil 
														   queue:[NSOperationQueue mainQueue] 
													  usingBlock:^(NSNotification *block){
															   libraryChangedHandler();
														   }];
    }
    
    return self;
}

- (void)dealloc
{
	dispatch_release(_assetItemsQueue);
	
	dispatch_release(_libraryQueue);
	dispatch_release(_libraryGroup);
	
	[[NSNotificationCenter defaultCenter] removeObserver:self name:ALAssetsLibraryChangedNotification object:nil];
}

- (void)loadLibraryWithCompletionBlock:(void (^)(void))completionHandler
{
	// Load content using the Media Library and AssetLibrary APIs, also check for content included in the application bundle
	[self.assetItems removeAllObjects];
	
	[self buildMediaLibrary];
	[self buildAssetLibrary];
	[self buildApplicationBundleLibrary];
	
	dispatch_group_notify(self.libraryGroup, self.libraryQueue, ^{
		dispatch_async(dispatch_get_main_queue(), ^{
			completionHandler();
		});
	});
}

- (void)addURL:(NSURL *)url
{
	__unsafe_unretained __block VideoLibrary *weakSelf = (VideoLibrary *)self;
	
	if (url == nil)
		return;
	
	dispatch_async(self.assetItemsQueue, ^{
		[weakSelf.assetItems addObject:[[AssetItem alloc] initWithURL:url]];
	});
}

#pragma mark - iPod Library

- (void)buildMediaLibrary
{
	__unsafe_unretained __block VideoLibrary *weakSelf = (VideoLibrary *)self;
	dispatch_group_async(self.libraryGroup, self.libraryQueue, ^{
		NSLog(@"started building media library...");
		
		// Search for video content in the Media Library
#if  __IPHONE_OS_VERSION_MAX_ALLOWED >= 50000
		NSNumber *videoTypeNum = [NSNumber numberWithInteger:MPMediaTypeAnyVideo];
#else
		NSNumber *videoTypeNum = [NSNumber numberWithInteger:(MPMediaTypeAny ^ MPMediaTypeAnyAudio)];
#endif
		MPMediaPropertyPredicate *videoPredicate = [MPMediaPropertyPredicate predicateWithValue:videoTypeNum forProperty:MPMediaItemPropertyMediaType];
		MPMediaQuery *videoQuery = [[MPMediaQuery alloc] init];
		[videoQuery addFilterPredicate: videoPredicate];
		NSArray *items = [videoQuery items];
		
		for (MPMediaItem *mediaItem in items) 
			[weakSelf addURL:[mediaItem valueForProperty:MPMediaItemPropertyAssetURL]];
		
		NSLog(@"done building media library...");
	});
}

- (void)buildAssetLibrary
{
	NSLog(@"started building asset library...");
	
	__unsafe_unretained __block VideoLibrary *weakSelf = (VideoLibrary *)self;
	dispatch_group_enter(weakSelf.libraryGroup);
	
	ALAssetsLibrary *assetLibrary = [[ALAssetsLibrary alloc] init];
	
	// Enumerate through all the groups in the Asset Library
	[assetLibrary enumerateGroupsWithTypes:ALAssetsGroupAll 
								usingBlock:
	 ^(ALAssetsGroup *group, BOOL *stop)
	 {
		 if (group != nil)
		 {
			 // Filter by groups that contain video
			 [group setAssetsFilter:[ALAssetsFilter allVideos]];
			 [group enumerateAssetsUsingBlock:
			  ^(ALAsset *asset, NSUInteger index, BOOL *stop)
			  {
				  if (asset)
					  [weakSelf addURL:[[asset defaultRepresentation] url]];
			  }];
		 }
		 else
		 {
			 dispatch_group_leave(weakSelf.libraryGroup);
			 NSLog(@"done building asset library...");
		 }
	 }
							  failureBlock:^(NSError *error)
	 {
		 dispatch_group_leave(weakSelf.libraryGroup);
		 NSLog(@"error enumerating AssetLibrary groups %@\n", error);
	 }];
	
}

- (void)buildApplicationBundleLibrary
{
	__unsafe_unretained __block VideoLibrary *weakSelf = (VideoLibrary *)self;
	dispatch_group_async(self.libraryGroup, self.libraryQueue, ^{
		NSLog(@"started building bundle library...");
		NSString *appBundleDirectory = [[NSBundle mainBundle] bundlePath];
		
		// Search for audio/video content in the app bundle
		NSArray *subPaths = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:appBundleDirectory error:nil];
		if (subPaths)
		{
			for (NSString *subPath in subPaths)
			{
				NSString *pathExtension = [subPath pathExtension];
				CFStringRef preferredUTI = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, (__bridge CFStringRef)pathExtension, NULL);
				BOOL fileConformsToUTI = UTTypeConformsTo(preferredUTI, kUTTypeAudiovisualContent);
				CFRelease(preferredUTI);
				NSString *path = [appBundleDirectory stringByAppendingPathComponent:subPath];
				
				if (fileConformsToUTI)
					[weakSelf addURL:[NSURL fileURLWithPath:path]];
			}
		}
		NSLog(@"done building bundle library...");
	});
}

+ (BOOL)saveMovieAtPathToAssetLibrary:(NSURL *)path withCompletionHandler:(void (^)(NSError *))completionHandler
{
	// Write a movie back to the asset library so it can be viewed by other apps
    BOOL success = YES;
    ALAssetsLibrary *assetLibrary = [[ALAssetsLibrary alloc] init];
    [assetLibrary writeVideoAtPathToSavedPhotosAlbum:path completionBlock:^(NSURL *assetURL, NSError *error){
        if (error != nil)
		{
			dispatch_async(dispatch_get_main_queue(), ^{
				completionHandler(error);
			});
		}
		else
		{
			NSError *removeError = nil;
			[[NSFileManager defaultManager] removeItemAtURL:path error:&removeError];
			
			dispatch_async(dispatch_get_main_queue(), ^{
				completionHandler(error);
			});
		}
    }];
    
    return success;
}

@end
