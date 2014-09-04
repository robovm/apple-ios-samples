/*
    File:       PhotoGalleryContext.m

    Contains:   A managed object context subclass that carries along some photo gallery info.

    Written by: DTS

    Copyright:  Copyright (c) 2010 Apple Inc. All Rights Reserved.

    Disclaimer: IMPORTANT: This Apple software is supplied to you by Apple Inc.
                ("Apple") in consideration of your agreement to the following
                terms, and your use, installation, modification or
                redistribution of this Apple software constitutes acceptance of
                these terms.  If you do not agree with these terms, please do
                not use, install, modify or redistribute this Apple software.

                In consideration of your agreement to abide by the following
                terms, and subject to these terms, Apple grants you a personal,
                non-exclusive license, under Apple's copyrights in this
                original Apple software (the "Apple Software"), to use,
                reproduce, modify and redistribute the Apple Software, with or
                without modifications, in source and/or binary forms; provided
                that if you redistribute the Apple Software in its entirety and
                without modifications, you must retain this notice and the
                following text and disclaimers in all such redistributions of
                the Apple Software. Neither the name, trademarks, service marks
                or logos of Apple Inc. may be used to endorse or promote
                products derived from the Apple Software without specific prior
                written permission from Apple.  Except as expressly stated in
                this notice, no other rights or licenses, express or implied,
                are granted by Apple herein, including but not limited to any
                patent rights that may be infringed by your derivative works or
                by other works in which the Apple Software may be incorporated.

                The Apple Software is provided by Apple on an "AS IS" basis. 
                APPLE MAKES NO WARRANTIES, EXPRESS OR IMPLIED, INCLUDING
                WITHOUT LIMITATION THE IMPLIED WARRANTIES OF NON-INFRINGEMENT,
                MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE, REGARDING
                THE APPLE SOFTWARE OR ITS USE AND OPERATION ALONE OR IN
                COMBINATION WITH YOUR PRODUCTS.

                IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT,
                INCIDENTAL OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED
                TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
                DATA, OR PROFITS; OR BUSINESS INTERRUPTION) ARISING IN ANY WAY
                OUT OF THE USE, REPRODUCTION, MODIFICATION AND/OR DISTRIBUTION
                OF THE APPLE SOFTWARE, HOWEVER CAUSED AND WHETHER UNDER THEORY
                OF CONTRACT, TORT (INCLUDING NEGLIGENCE), STRICT LIABILITY OR
                OTHERWISE, EVEN IF APPLE HAS BEEN ADVISED OF THE POSSIBILITY OF
                SUCH DAMAGE.

*/

#import "PhotoGalleryContext.h"

#import "NetworkManager.h"

@implementation PhotoGalleryContext

- (id)initWithGalleryURLString:(NSString *)galleryURLString galleryCachePath:(NSString *)galleryCachePath
{
    assert(galleryURLString != nil);
    assert(galleryCachePath != nil);
    
    self = [super init];
    if (self != nil) {
        self->_galleryURLString = [galleryURLString copy];
        self->_galleryCachePath = [galleryCachePath copy];
    }
    return self;
}

- (void)dealloc
{
    [self->_galleryCachePath release];
    [self->_galleryURLString release];
    [super dealloc];
}

@synthesize galleryURLString = _galleryURLString;
@synthesize galleryCachePath = _galleryCachePath;

- (NSString *)photosDirectoryPath
{
    // This comes from the PhotoGallery class.  I didn't really want to include it's header 
    // here (because we are 'lower' in the architecture than PhotoGallery), and I don't want 
    // the declaration in "PhotoGalleryContext.h" either (because our public clients have 
    // no need of this).  The best solution would be to have "PhotoGalleryPrivate.h", and 
    // put all the gallery cache structure strings into that file.  But having a whole separate 
    // file just to solve that problem seems like overkill.  So, for the moment, we just 
    // declare it extern here.
    extern NSString * kPhotosDirectoryName;
    return [self.galleryCachePath stringByAppendingPathComponent:kPhotosDirectoryName];
}

- (NSMutableURLRequest *)requestToGetGalleryRelativeString:(NSString *)path
    // See comment in header.
{
    NSMutableURLRequest *   result;
    NSURL *                 url;

    assert([NSThread isMainThread]);
    assert(self.galleryURLString != nil);

    result = nil;
    
    // Construct the URL.
    
    url = [NSURL URLWithString:self.galleryURLString];
    assert(url != nil);
    if (path != nil) {
        url = [NSURL URLWithString:path relativeToURL:url];
        // url may be nil because, while galleryURLString is guaranteed to be a valid 
        // URL, path may not be.
    }
    
    // Call down to the network manager so that it can set up its stuff 
    // (notably the user agent string).
    
    if (url != nil) {
        result = [[NetworkManager sharedManager] requestToGetURL:url];
        assert(result != nil);
    }
    
    return result;
}

@end
