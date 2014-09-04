/*
 
 
     File: APLCustomAVARLDelegate.m
 Abstract: Custom delegate class implementation. 
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
 
 Copyright (C) 2014 Apple Inc. All Rights Reserved.
 
 
 */
#import "APLCustomAVARLDelegate.h"

static NSString *redirectScheme = @"rdtp";
static NSString *customPlaylistScheme = @"cplp";
static NSString *customKeyScheme = @"ckey";
static NSString *httpScheme = @"http";

static NSString *customPlayListFormatPrefix = @"#EXTM3U\n"
"#EXT-X-PLAYLIST-TYPE:EVENT\n"
"#EXT-X-TARGETDURATION:10\n"
"#EXT-X-VERSION:3\n"
"#EXT-X-MEDIA-SEQUENCE:0\n";

static NSString *customPlayListFormatElementInfo = @"#EXTINF:10, no desc\n";
static NSString *customPlaylistFormatElementSegment = @"%@/fileSequence%d.ts\n";

static NSString *customEncryptionKeyInfo = @"#EXT-X-KEY:METHOD=AES-128,URI=\"%@/crypt0.key\", IV=0x3ff5be47e1cdbaec0a81051bcc894d63\n";
static NSString *customPlayListFormatEnd = @"#EXT-X-ENDLIST";
static int redirectErrorCode = 302;
static int badRequestErrorCode = 400;



@interface APLCustomAVARLDelegate ()
- (BOOL) schemeSupported:(NSString*) scheme;
- (void) reportError:(AVAssetResourceLoadingRequest *) loadingRequest withErrorCode:(int) error;
@end


@interface APLCustomAVARLDelegate (Redirect)
- (BOOL) isRedirectSchemeValid:(NSString*) scheme;
- (BOOL) handleRedirectRequest:(AVAssetResourceLoadingRequest*) loadingRequest;
- (NSURLRequest* ) generateRedirectURL:(NSURLRequest *)sourceURL;
@end

@interface APLCustomAVARLDelegate (CustomPlaylist)
- (BOOL) isCustomPlaylistSchemeValid:(NSString*) scheme;
- (NSString*) getCustomPlaylist:(NSString *) urlPrefix andKeyPrefix:(NSString*) keyPrefix totalElements:(NSInteger) elements;
- (BOOL) handleCustomPlaylistRequest:(AVAssetResourceLoadingRequest*) loadingRequest;
@end

@interface APLCustomAVARLDelegate (CustomKey)
- (BOOL) isCustomKeySchemeValid:(NSString*) scheme;
- (NSData*) getKey:(NSURL*) url;
- (BOOL) handleCustomKeyRequest:(AVAssetResourceLoadingRequest*) loadingRequest;
@end

#pragma mark - APLCustomAVARLDelegate

@implementation APLCustomAVARLDelegate
/*!
 *  is scheme supported
 */
- (BOOL) schemeSupported:(NSString *)scheme
{
    if ( [self isRedirectSchemeValid:scheme] ||
        [self isCustomKeySchemeValid:scheme] ||
        [self isCustomPlaylistSchemeValid:scheme])
        return YES;
    return NO;
}

-(APLCustomAVARLDelegate *) init
{
    self = [super init];
    return self;
}

- (void) reportError:(AVAssetResourceLoadingRequest *) loadingRequest withErrorCode:(int) error
{
    [loadingRequest finishLoadingWithError:[NSError errorWithDomain: NSURLErrorDomain code:error userInfo: nil]];
}
/*!
 *  AVARLDelegateDemo's implementation of the protocol.
 *  Check the given request for valid schemes:
 * 
 * 1) Redirect 2) Custom Play list 3) Custom key
 */
- (BOOL) resourceLoader:(AVAssetResourceLoader *)resourceLoader shouldWaitForLoadingOfRequestedResource:(AVAssetResourceLoadingRequest *)loadingRequest
{
    NSString* scheme = [[[loadingRequest request] URL] scheme];
    
    if ([self isRedirectSchemeValid:scheme])
        return [self handleRedirectRequest:loadingRequest];
    
    if ([self isCustomPlaylistSchemeValid:scheme]) {
        dispatch_async (dispatch_get_main_queue(),  ^ {
            [self handleCustomPlaylistRequest:loadingRequest];
        });
        return YES;
    }
    
    if ([self isCustomKeySchemeValid:scheme]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self handleCustomKeyRequest:loadingRequest];
        });
        return YES;
    }
    
    return NO;
}

@end

#pragma mark - APLCustomACARLDelegate Redirect

@implementation APLCustomAVARLDelegate (Redirect)
/*!
 * Validates the given redirect schme.
 */
- (BOOL) isRedirectSchemeValid:(NSString *)scheme
{
    return ([redirectScheme isEqualToString:scheme]);
}

-(NSURLRequest* ) generateRedirectURL:(NSURLRequest *)sourceURL
{
    NSURLRequest *redirect = [NSURLRequest requestWithURL:[NSURL URLWithString:[[[sourceURL URL] absoluteString] stringByReplacingOccurrencesOfString:redirectScheme withString:httpScheme]]];
    return redirect;
}
/*!
 *  The delegate handler, handles the received request:
 *
 *  1) Verifies its a redirect request, otherwise report an error.
 *  2) Generates the new URL 
 *  3) Create a reponse with the new URL and report success.
 */
- (BOOL) handleRedirectRequest:(AVAssetResourceLoadingRequest *)loadingRequest
{
    NSURLRequest *redirect = nil;
    
    redirect = [self generateRedirectURL:(NSURLRequest *)[loadingRequest request]];
    if (redirect)
    {
        [loadingRequest setRedirect:redirect];
        NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:[redirect URL] statusCode:redirectErrorCode HTTPVersion:nil headerFields:nil];
        [loadingRequest setResponse:response];
        [loadingRequest finishLoading];
    } else
    {
        [self reportError:loadingRequest withErrorCode:badRequestErrorCode];
    }
	return YES;
}

@end

#pragma mark - APLCustomAVARLDelegate CustomPlaylist

@implementation APLCustomAVARLDelegate (CustomPlaylist)

- (BOOL) isCustomPlaylistSchemeValid:(NSString *)scheme
{
    return ([customPlaylistScheme isEqualToString:scheme]);
}
/*!
 * create a play list based on the given prefix and total elements
 */
- (NSString*) getCustomPlaylist:(NSString *) urlPrefix andKeyPrefix:(NSString *) keyPrefix totalElements:(NSInteger) elements
{
    static NSMutableString  *customPlaylist = nil;
    
    if (customPlaylist)
        return customPlaylist;
    
    customPlaylist = [[NSMutableString alloc] init];
    [customPlaylist appendString:customPlayListFormatPrefix];
    for (int i = 0; i < elements; ++i)
    {
        [customPlaylist appendString:customPlayListFormatElementInfo];
        //We are using single key for all the segments but different IV, every 50 segments
        if (0 == i)
            [customPlaylist appendFormat:customEncryptionKeyInfo, keyPrefix];
        [customPlaylist appendFormat:customPlaylistFormatElementSegment, urlPrefix, i];
    }
    [customPlaylist appendString:customPlayListFormatEnd];
    return customPlaylist;
}
/*!
 *  Handles the custom play list scheme:
 *
 *  1) Verifies its a custom playlist request, otherwise report an error.
 *  2) Generates the play list.
 *  3) Create a reponse with the new URL and report success.
 */
- (BOOL) handleCustomPlaylistRequest:(AVAssetResourceLoadingRequest *)loadingRequest
{
    //Prepare the playlist with redirect scheme.
	NSString *prefix = [[[[loadingRequest request] URL] absoluteString] stringByReplacingOccurrencesOfString:customPlaylistScheme withString:redirectScheme];// stringByDeletingLastPathComponent];
    NSRange range = [prefix rangeOfString:@"/" options:NSBackwardsSearch];
    prefix = [prefix substringToIndex:range.location];
    NSString *keyPrefix = [prefix stringByReplacingOccurrencesOfString:redirectScheme withString:customKeyScheme];
    NSData *data = [[self getCustomPlaylist:prefix andKeyPrefix:keyPrefix totalElements:150] dataUsingEncoding:NSUTF8StringEncoding];
    
    if (data)
    {
        [loadingRequest.dataRequest respondWithData:data];
        [loadingRequest finishLoading];
    } else
    {
        [self reportError:loadingRequest withErrorCode:badRequestErrorCode];
    }
    
    return YES;
}
@end

#pragma mark - APLCustomAVARLDelegate CustomKey

@implementation APLCustomAVARLDelegate (CustomKey)
- (BOOL) isCustomKeySchemeValid:(NSString*) scheme
{
    return ([customKeyScheme isEqualToString:scheme]);
}


- (NSData*) getKey:(NSURL*) url
{
    NSURL *newURL = [NSURL URLWithString:[[url absoluteString] stringByReplacingOccurrencesOfString:customKeyScheme withString:httpScheme]];
    return [[NSData alloc] initWithContentsOfURL:newURL];
}
/*!
 *  Handles the custom key scheme:
 *
 *  1) Verifies its a custom key request, otherwise report an error.
 *  2) Creates the URL for the key
 *  3) Create a response with the new URL and report success.
 */
- (BOOL) handleCustomKeyRequest:(AVAssetResourceLoadingRequest*) loadingRequest
{
    NSData* data = [self getKey:[[loadingRequest request] URL]];
    if (data)
    {
        [loadingRequest.dataRequest respondWithData:data];
        [loadingRequest finishLoading];
    } else
    {
        [self reportError:loadingRequest withErrorCode:badRequestErrorCode];
    }
    return YES;

}
@end
