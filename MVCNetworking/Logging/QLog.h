/*
    File:       QLog.h

    Contains:   A simplistic logging package.

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

#import <Foundation/Foundation.h>

@interface QLog : NSObject
{
    BOOL                _enabled;                                               // main thread write, any thread read
    int                 _logFile;                                               // main thread write, any thread read
    off_t               _logFileLength;                                         // main thread only, only valid if _logFile != -1
    BOOL                _loggingToStdErr;                                       // main thread write, any thread read
    NSUInteger          _optionsMask;                                           // main thread write, any thread read
    BOOL                _showViewer;                                            // main thread only
    NSMutableArray *    _logEntries;                                            // main thread only
    NSMutableArray *    _pendingEntries;                                        // any thread, protected by @synchronize (self)
}

+ (QLog *)log;                                                                  // any thread
    // Returns the singleton logging object.
    
- (void)flush;                                                                  // main thread only
    // Flushes any pending log entries to the logEntries array and also, if 
    // appropriate, to the log file or stderr.
    
- (void)clear;                                                                  // main thread only
    // Empties the logEntries array and, if appropriate, the log file.  Not 
    // much we can do about stderr (-:

// Preferences

@property (assign, readonly, getter=isEnabled) BOOL         enabled;            // any thread, observable, always changed by main thread
@property (assign, readonly, getter=isLoggingToFile) BOOL   loggingToFile;      // any thread, observable, always changed by main thread
@property (assign, readonly, getter=isLoggingToStdErr) BOOL loggingToStdErr;    // any thread, observable, always changed by main thread
@property (assign, readonly) NSUInteger                     optionsMask;        // any thread, observable, always changed by main thread

@property (assign, readonly) BOOL                           showViewer;         // main thread, observable, always changed by main thread

// User Default         Property
// ------------         --------
// qlogEnabled          enabled
// qlogLoggingToFile    loggingToFile
// qlogLoggingToStdErr  loggingToStdErr
// qlogOption0..31      optionsMask

// Log entry generation

// Some things to note:
// 
// o The -logOptions:xxx methods only log if the specified bit is set in 
//   optionsMask (that is, (optionsMask & (1 << option)) is not zero).
//
// o The format string is as implemented by +[NSString stringWithFormat:].

- (void)logWithFormat:(NSString *)format, ... NS_FORMAT_FUNCTION(1, 2);                             // any thread
- (void)logWithFormat:(NSString *)format arguments:(va_list)argList;                                // any thread
- (void)logOption:(NSUInteger)option withFormat:(NSString *)format, ... NS_FORMAT_FUNCTION(2, 3);   // any thread
- (void)logOption:(NSUInteger)option withFormat:(NSString *)format arguments:(va_list)argList;      // any thread

// In memory log entries

// New entries are added to the end of this array and, as there's an upper limit 
// number of entries that will be held in memory, ald entries are removed from 
// the beginning.

@property (retain, readonly) NSMutableArray *               logEntries;         // observable, always changed by main thread

// In file log entries

- (NSInputStream *)streamForLogValidToLength:(off_t *)lengthPtr;                // main thread only
    // Returns an un-opened stream.  If lengthPtr is not NULL then, on return 
    // *lengthPtr contains the number of bytes in that stream that are 
    // guaranteed to be valid.
    //
    // This can only be called on the main thread but the resulting stream 
    // can be passed to any thread for processing.
    
@end
