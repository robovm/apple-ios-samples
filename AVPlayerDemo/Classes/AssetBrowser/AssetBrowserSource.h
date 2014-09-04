/*
     File: AssetBrowserSource.h
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

#import <Foundation/Foundation.h>

#import "AssetBrowserItem.h"

@class ALAssetsLibrary;

enum {
	AssetBrowserSourceTypeFileSharing			= 1 << 0,
	AssetBrowserSourceTypeCameraRoll			= 1 << 1,
	AssetBrowserSourceTypeIPodLibrary			= 1 << 2,
	AssetBrowserSourceTypeAll					= 0xFFFFFFFF
};
typedef NSUInteger AssetBrowserSourceType;

@protocol AssetBrowserSourceDelegate;

@class ALAssetsLibrary, DirectoryWatcher;

@interface AssetBrowserSource : NSObject
{
@private	
	AssetBrowserSourceType sourceType;
	NSString *sourceName;
	NSArray *assetBrowserItems;
	
	id <AssetBrowserSourceDelegate> __weak delegate;
	
	BOOL haveBuiltSourceLibrary;
	ALAssetsLibrary *assetsLibrary;
	BOOL receivingIPodLibraryNotifications;
	dispatch_queue_t enumerationQueue;
	
	DirectoryWatcher *directoryWatcher;
}

+ (AssetBrowserSource*)assetBrowserSourceOfType:(AssetBrowserSourceType)sourceType;
- (id)initWithSourceType:(AssetBrowserSourceType)sourceType;

- (void)buildSourceLibrary;
@property (nonatomic, readonly) NSString *name;
@property (nonatomic, readonly, copy) NSArray *items; // NSArray of AssetBrowserItems
@property (nonatomic, readonly) AssetBrowserSourceType type;
@property (nonatomic, weak) id <AssetBrowserSourceDelegate> delegate;

@end

@protocol AssetBrowserSourceDelegate <NSObject>;
@optional
- (void)assetBrowserSourceItemsDidChange:(AssetBrowserSource*)source;
@end
