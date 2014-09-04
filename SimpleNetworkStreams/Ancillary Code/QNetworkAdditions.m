/*
    File:       QNetworkAdditions.m

    Contains:   Works around various NSNetService problems.

    Written by: DTS

    Copyright:  Copyright (c) 2012 Apple Inc. All Rights Reserved.

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

#import "QNetworkAdditions.h"

@implementation NSNetService (QNetworkAdditions)

- (BOOL)qNetworkAdditions_getInputStream:(out NSInputStream **)inputStreamPtr 
    outputStream:(out NSOutputStream **)outputStreamPtr
    // The following works around three problems with -[NSNetService getInputStream:outputStream:]:
    //
    // o <rdar://problem/6868813> -- Currently the returns the streams with 
    //   +1 retain count, which is counter to Cocoa conventions and results in 
    //   leaks when you use it in ARC code.
    //
    // o <rdar://problem/9821932> -- If you create two pairs of streams from 
    //   one NSNetService and then attempt to open all the streams simultaneously, 
    //   some of the streams might fail to open.
    //
    // o <rdar://problem/9856751> -- If you create streams using 
    //   -[NSNetService getInputStream:outputStream:], start to open them, and 
    //   then release the last reference to the original NSNetService, the 
    //   streams never finish opening.  This problem is exacerbated under ARC 
    //   because ARC is better about keeping things out of the autorelease pool.
{
    BOOL                result;
    CFReadStreamRef     readStream;
    CFWriteStreamRef    writeStream;

    result = NO;
    
    readStream = NULL;
    writeStream = NULL;
    
    if ( (inputStreamPtr != NULL) || (outputStreamPtr != NULL) ) {
        CFNetServiceRef     netService;

        netService = CFNetServiceCreate(
            NULL, 
            (__bridge CFStringRef) [self domain], 
            (__bridge CFStringRef) [self type], 
            (__bridge CFStringRef) [self name], 
            0
        );
        if (netService != NULL) {
            CFStreamCreatePairWithSocketToNetService(
                NULL, 
                netService, 
                ((inputStreamPtr  != nil) ? &readStream  : NULL), 
                ((outputStreamPtr != nil) ? &writeStream : NULL)
            );
            CFRelease(netService);
        }
        
        // We have failed if the client requested an input stream and didn't 
        // get one, or requested an output stream and didn't get one.  We also 
        // fail if the client requested neither the input nor the output 
        // stream, but we don't get here in that case.
        
        result = ! ((( inputStreamPtr != NULL) && ( readStream == NULL)) || 
                    ((outputStreamPtr != NULL) && (writeStream == NULL)));
    }
    if (inputStreamPtr != NULL) {
        *inputStreamPtr  = CFBridgingRelease(readStream);
    }
    if (outputStreamPtr != NULL) {
        *outputStreamPtr = CFBridgingRelease(writeStream);
    }
    
    return result;
}

@end
