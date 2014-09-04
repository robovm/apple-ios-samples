/*
     File: iTunesRSSImporter.h
 Abstract: Downloads, parses, and imports the iTunes top songs RSS feed into Core Data.
  Version: 1.4
 
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
 
 Copyright (C) 2013 Apple Inc. All Rights Reserved.
 
 */

#import <UIKit/UIKit.h>
#import <libxml/tree.h>

@class iTunesRSSImporter, Song, Category, CategoryCache;

// Protocol for the importer to communicate with its delegate.
@protocol iTunesRSSImporterDelegate <NSObject>

@optional
// Notification posted by NSManagedObjectContext when saved.
- (void)importerDidSave:(NSNotification *)saveNotification;
// Called by the importer when parsing is finished.
- (void)importerDidFinishParsingData:(iTunesRSSImporter *)importer;
// Called by the importer in the case of an error.
- (void)importer:(iTunesRSSImporter *)importer didFailWithError:(NSError *)error;

@end


@interface iTunesRSSImporter : NSOperation {
@private
    id <iTunesRSSImporterDelegate> __unsafe_unretained delegate;
    // Reference to the libxml parser context
    xmlParserCtxtPtr context;
    NSURLConnection *rssConnection;
    // Overall state of the importer, used to exit the run loop.
    BOOL done;
    // State variable used to determine whether or not to ignore a given XML element
    BOOL parsingASong;
    // The following state variables deal with getting character data from XML elements. This is a potentially expensive 
    // operation. The character data in a given element may be delivered over the course of multiple callbacks, so that
    // data must be appended to a buffer. The optimal way of doing this is to use a C string buffer that grows exponentially.
    // When all the characters have been delivered, an NSString is constructed and the buffer is reset.
    BOOL storingCharacters;
    NSMutableData *characterBuffer;
    // A reference to the current song the importer is working with.
    Song *currentSong;
    // The number of parsed songs is tracked so that the autorelease pool for the parsing thread can be periodically
    // emptied to keep the memory footprint under control. 
    NSUInteger countForCurrentBatch;
    NSUInteger rankOfCurrentSong;
    NSDateFormatter *dateFormatter;
    NSManagedObjectContext *insertionContext;
    NSPersistentStoreCoordinator *persistentStoreCoordinator;
    NSEntityDescription *songEntityDescription;
    CategoryCache *theCache;
    NSURL *iTunesURL;
}

@property (nonatomic, retain) NSURL *iTunesURL;
@property (nonatomic, assign) id <iTunesRSSImporterDelegate> delegate;
@property (nonatomic, retain) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property (nonatomic, retain, readonly) NSManagedObjectContext *insertionContext;
@property (nonatomic, retain, readonly) NSEntityDescription *songEntityDescription;
@property (nonatomic, retain, readonly) CategoryCache *theCache;

// Although NSURLConnection is inherently asynchronous, the parsing can be quite CPU intensive on the device, so
// the user interface can be kept responsive by moving that work off the main thread. This does create additional
// complexity, as any code which interacts with the UI must then do so in a thread-safe manner.
- (void)main;


@end
