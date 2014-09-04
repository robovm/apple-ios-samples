/*
     File: FavoriteAssets.m 
 Abstract: n/a 
  Version: 1.2 
  
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
  
 Copyright (C) 2012 Apple Inc. All Rights Reserved. 
  
*/

#import "ApplicationConstants.h"
#import "AssetsList.h"
#import "FavoriteAssets.h"

#import <AssetsLibrary/AssetsLibrary.h>

NSString * const kFavoriteAssetsChanged = @"FavoriteAssetsChanged";

static NSString * const kFavoriteAssetsTitle = @"Favorites";


@interface FavoriteAssets (Serialization)
- (void)readFavoriteAssets;
- (void)saveFavoriteAssets;
@end

@implementation FavoriteAssets

- (id)init {
    self = [super init];
    if (self) {
        [self readFavoriteAssets];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(toggleFavoriteStatus:) name:kToggleFavoriteStatusNotification object:nil];
    }
    
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [favoriteAssetsURLs release];
    
    [super dealloc];
}

- (BOOL)isFavorite:(ALAsset *)asset {

    NSURL *representationURL = [[asset defaultRepresentation] url];
    if ([favoriteAssetsURLs containsObject:representationURL]) {
        return YES;
    } else {
        return NO;
    }

}

- (AssetsList *)assetsList {

    AssetsList *result = [[AssetsList alloc] initWithAssetsURLs:[favoriteAssetsURLs allObjects]];
    result.title = kFavoriteAssetsTitle;
    return [result autorelease];
}

- (NSUInteger) count {
    return [favoriteAssetsURLs count];
}

- (CGImageRef)posterImage {
    UIImage *posterImage = [UIImage imageNamed:@"gold-star.png"];
    return [posterImage CGImage];
}

- (id)valueForProperty:(NSString *)propertyName {
    if ([propertyName isEqualToString:ALAssetsGroupPropertyName]) {
        return kFavoriteAssetsTitle;
    } else {
        return @"";
    }
}

#pragma mark -
#pragma mark Toggle Favorite Status Notification
- (void)toggleFavoriteStatus:(NSNotification *)notification {
    NSDictionary *userInfo = [notification userInfo];
    NSURL *assetURL = [userInfo objectForKey:kToggleFavoriteStatusNotificationAssetURLKey];
    
    if ([favoriteAssetsURLs containsObject:assetURL]) {
        [favoriteAssetsURLs removeObject:assetURL];
    } else {
        [favoriteAssetsURLs addObject:assetURL];
    }
    
    [self saveFavoriteAssets];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:kFavoriteAssetsChanged object:nil];
}

@end

@implementation FavoriteAssets (Serialization)
- (void)readFavoriteAssets {
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectoryPath = [paths objectAtIndex:0];

    NSArray *favoriteURLsAsStrings = [[NSArray alloc] initWithContentsOfFile:[documentsDirectoryPath stringByAppendingPathComponent:@"FavoriteAssets.plist"]];
    
    favoriteAssetsURLs = [[NSMutableSet alloc] initWithCapacity:[favoriteURLsAsStrings count]];
    for (NSString *urlAsString in favoriteURLsAsStrings) {
        NSURL *url = [[NSURL alloc] initWithString:urlAsString];
        [favoriteAssetsURLs addObject:url];
        [url release];
    }
    
    [favoriteURLsAsStrings release];
    
}

- (void)saveFavoriteAssets {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectoryPath = [paths objectAtIndex:0];
    
    NSMutableArray *urlsAsStrings = [[NSMutableArray alloc] initWithCapacity:[favoriteAssetsURLs count]];
    for (NSURL *url in [favoriteAssetsURLs allObjects]) {
        NSString *urlString = [url absoluteString];
        [urlsAsStrings addObject:urlString];
    }

    BOOL success = [urlsAsStrings writeToFile:[documentsDirectoryPath stringByAppendingPathComponent:@"FavoriteAssets.plist"] atomically:YES];
    if (!success) {
        NSLog(@"error writing to the favorite assets file");
    }
    [urlsAsStrings release];
     
}
@end
