/*
     File: AssetsList.m 
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

#import "AssetsList.h"

@interface AssetsList ()
- (void)loadAssetsFromURLs:(NSArray *)assetURLs callerResultsBlock:(ALAssetsGroupEnumerationResultsBlock)callerResultsBlock callerFailureBlock:(ALAssetsLibraryAccessFailureBlock)callerFailureBlock;

- (void)loadAssetsFromAssetsGroup:(ALAssetsGroup *)assetsGroup callerResultsBlock:(ALAssetsGroupEnumerationResultsBlock)callerResultsBlock;
@end

@implementation AssetsList

@synthesize title;

- (id)initWithAssetsURLs:(NSArray *)URLs {
    
    self = [super init];
    if (self) {
        assetsURLs = [URLs retain];
    }
    
    return self;
}

- (id)initWithAssetsGroup:(ALAssetsGroup *)newAssetsGroup {
    
    self = [super init];
    if (self) {
        assetsGroup = [newAssetsGroup retain];
    }
    
    return self;
}

- (void)dealloc {
    stopQuery = YES;
    self.title = nil;
    [favoriteAssets release];
    [assetsGroup release];
    [assetsURLs release];
    [assetsLibrary release];
    
    [super dealloc];
}


#pragma mark -
#pragma mark AssetsListProtocol implementation

- (NSUInteger)count {
    return [favoriteAssets count];
}

- (id)objectAtIndex:(NSUInteger)index {
    id result = nil;
    
    if (index < [self count]) {
        result = [favoriteAssets objectAtIndex:index];
    }
    return result;
}

#pragma mark -
#pragma mark Assets Loading

- (void)loadAssets:(ALAssetsGroupEnumerationResultsBlock)resultsBlock failureBlock:(ALAssetsLibraryAccessFailureBlock)failureBlock {
    
    if (assetsGroup) {
        [self loadAssetsFromAssetsGroup:assetsGroup callerResultsBlock:resultsBlock];
    } else if ([assetsURLs count] > 0) {
        [self loadAssetsFromURLs:assetsURLs callerResultsBlock:resultsBlock callerFailureBlock:failureBlock];
    }
}

- (void)loadAssetsFromURLs:(NSArray *)assetURLs callerResultsBlock:(ALAssetsGroupEnumerationResultsBlock)callerResultsBlock callerFailureBlock:(ALAssetsLibraryAccessFailureBlock)callerFailureBlock {
    
    ALAssetsGroupEnumerationResultsBlock callerResultsBlockCopy = [callerResultsBlock copy];
    ALAssetsLibraryAccessFailureBlock    callerFailureBlockCopy = [callerFailureBlock copy];

    if (!assetsLibrary) {
        assetsLibrary = [[ALAssetsLibrary alloc] init];
    }
    
    ALAssetsLibraryAssetForURLResultBlock resultsBlock = ^(ALAsset *asset) {
        if (asset) {
            [favoriteAssets addObject:asset];
        }
        if (callerResultsBlockCopy) {
            callerResultsBlockCopy(asset, [favoriteAssets count], &stopQuery);
        }
        
        if (!asset) {
            if (callerResultsBlockCopy) [callerResultsBlockCopy release];
            if (callerFailureBlockCopy) [callerFailureBlockCopy release];
        }
    };

    ALAssetsLibraryAccessFailureBlock failureBlock = ^(NSError *error) {
        if (callerFailureBlockCopy) {
            callerFailureBlockCopy(error);
        }

        if (callerResultsBlockCopy) [callerResultsBlockCopy release];
        if (callerFailureBlockCopy) [callerFailureBlockCopy release];
        
    };
    
    for (NSURL *assetURL in assetsURLs) {
        if (!stopQuery) {
            [assetsLibrary assetForURL:assetURL resultBlock:resultsBlock failureBlock:failureBlock];
        }
    }
    
    resultsBlock(nil);

    if (stopQuery) {
        if (callerResultsBlockCopy) [callerResultsBlockCopy release];
        if (callerFailureBlockCopy) [callerFailureBlockCopy release];
    }    
}

- (void)loadAssetsFromAssetsGroup:(ALAssetsGroup *)group callerResultsBlock:(ALAssetsGroupEnumerationResultsBlock)callerResultsBlock {

    ALAssetsGroupEnumerationResultsBlock callerResultsBlockCopy = [callerResultsBlock copy];
    
    if (!assetsLibrary) {
        assetsLibrary = [[ALAssetsLibrary alloc] init];
    }
    
    ALAssetsGroupEnumerationResultsBlock resultsBlock = ^(ALAsset *asset, NSUInteger index, BOOL *stop) {
        if (stopQuery) {
            *stop = YES;
            if (callerResultsBlockCopy) [callerResultsBlockCopy release];
        }
        else if (asset) {
            [favoriteAssets addObject:asset];
        }

        if (callerResultsBlockCopy) {
            callerResultsBlockCopy(asset, [favoriteAssets count], &stopQuery);
        }
        
        if (!asset) {
            if (callerResultsBlockCopy) [callerResultsBlockCopy release];
        }
    };
    
    [group enumerateAssetsUsingBlock:resultsBlock];
}

@end
