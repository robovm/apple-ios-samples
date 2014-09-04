/*
    File:       RecursiveDeleteOperation.h

    Contains:   Recursively deletes an array of file paths.

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

#import "RecursiveDeleteOperation.h"

@interface RecursiveDeleteOperation ()

// read/write versions of public properties

@property (copy,   readwrite) NSError *     error;

@end

@implementation RecursiveDeleteOperation

- (id)initWithPaths:(NSArray *)paths
    // See comment in header.
{
    assert(paths != nil);
    self = [super init];
    if (self != nil) {
        self->_paths = [paths copy];
        assert(self->_paths != nil);
    }
    return self;
}

- (void)dealloc
{
    [self->_paths release];
    [self->_error release];
    [super dealloc];
}

@synthesize paths = _paths;
@synthesize error = _error;

- (void)main
{
    BOOL                success;
    NSFileManager *     fileManager;
    NSError *           error;
    
    fileManager = [NSFileManager defaultManager];
    assert(fileManager != nil);
    
    success = YES;  // necessary when self.paths is empty, which is a wacky corner case but I decided to allow it
    for (NSString * path in self.paths) {
        success = [fileManager removeItemAtPath:path error:&error];
        if ( ! success ) {
            break;
        }
    }
    
    if ( ! success ) {
        self.error = error;
    }
}

@end
