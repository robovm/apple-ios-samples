/*
     File: iTunesRSSImporter.m
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

#import "iTunesRSSImporter.h"
#import "Song.h"
#import "Category.h"
#import "CategoryCache.h"
#import <libxml/tree.h>

// Function prototypes for SAX callbacks. This sample implements a minimal subset of SAX callbacks.
// Depending on your application's needs, you might want to implement more callbacks.
static void startElementSAX(void *context, const xmlChar *localname, const xmlChar *prefix, const xmlChar *URI, int nb_namespaces, const xmlChar **namespaces, int nb_attributes, int nb_defaulted, const xmlChar **attributes);
static void endElementSAX(void *context, const xmlChar *localname, const xmlChar *prefix, const xmlChar *URI);
static void charactersFoundSAX(void *context, const xmlChar *characters, int length);
static void errorEncounteredSAX(void *context, const char *errorMessage, ...);

// Forward reference. The structure is defined in full at the end of the file.
static xmlSAXHandler simpleSAXHandlerStruct;

// Class extension for private properties and methods.
@interface iTunesRSSImporter ()

@property BOOL storingCharacters;
@property (nonatomic, retain) NSMutableData *characterBuffer;
@property BOOL done;
@property BOOL parsingASong;
@property NSUInteger countForCurrentBatch;
@property (nonatomic, retain) Song *currentSong;
@property (nonatomic, retain) NSURLConnection *rssConnection;
@property (nonatomic, retain) NSDateFormatter *dateFormatter;

@end

static double lookuptime = 0;

@implementation iTunesRSSImporter

@synthesize iTunesURL, delegate, persistentStoreCoordinator;
@synthesize rssConnection, done, parsingASong, storingCharacters, currentSong, countForCurrentBatch, characterBuffer, dateFormatter;

- (void)main {

    if (delegate && [delegate respondsToSelector:@selector(importerDidSave:)]) {
        [[NSNotificationCenter defaultCenter] addObserver:delegate selector:@selector(importerDidSave:) name:NSManagedObjectContextDidSaveNotification object:self.insertionContext];
    }
    done = NO;
    self.dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateStyle:NSDateFormatterLongStyle];
    [dateFormatter setTimeStyle:NSDateFormatterNoStyle];
    // necessary because iTunes RSS feed is not localized, so if the device region has been set to other than US
    // the date formatter must be set to US locale in order to parse the dates
    [dateFormatter setLocale:[[NSLocale alloc] initWithLocaleIdentifier:@"US"]];
    self.characterBuffer = [NSMutableData data];
    NSURLRequest *theRequest = [NSURLRequest requestWithURL:iTunesURL];
    // create the connection with the request and start loading the data
    rssConnection = [[NSURLConnection alloc] initWithRequest:theRequest delegate:self];
    // This creates a context for "push" parsing in which chunks of data that are not "well balanced" can be passed
    // to the context for streaming parsing. The handler structure defined above will be used for all the parsing. 
    // The second argument, self, will be passed as user data to each of the SAX handlers. The last three arguments
    // are left blank to avoid creating a tree in memory.
    context = xmlCreatePushParserCtxt(&simpleSAXHandlerStruct, (__bridge void *)(self), NULL, 0, NULL);
    if (rssConnection != nil) {
        do {
            [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]];
        } while (!done);
    }
    // Display the total time spent finding a specific object for a relationship
    NSLog(@"lookup time %f", lookuptime);
    // Release resources used only in this thread.
    xmlFreeParserCtxt(context);
    self.characterBuffer = nil;
    self.dateFormatter = nil;
    self.rssConnection = nil;
    self.currentSong = nil;
    theCache = nil;
    
    NSError *saveError = nil;
    NSAssert1([insertionContext save:&saveError], @"Unhandled error saving managed object context in import thread: %@", [saveError localizedDescription]);
    if (delegate && [delegate respondsToSelector:@selector(importerDidSave:)]) {
        [[NSNotificationCenter defaultCenter] removeObserver:delegate name:NSManagedObjectContextDidSaveNotification object:self.insertionContext];
    }
    if (self.delegate != nil && [self.delegate respondsToSelector:@selector(importerDidFinishParsingData:)]) {
        [self.delegate importerDidFinishParsingData:self];
    }
}

- (NSManagedObjectContext *)insertionContext {
    
    if (insertionContext == nil) {
        insertionContext = [[NSManagedObjectContext alloc] init];
        [insertionContext setPersistentStoreCoordinator:self.persistentStoreCoordinator];
    }
    return insertionContext;
}

- (void)forwardError:(NSError *)error {
    
    if (self.delegate != nil && [self.delegate respondsToSelector:@selector(importer:didFailWithError:)]) {
        [self.delegate importer:self didFailWithError:error];
    }
}

- (NSEntityDescription *)songEntityDescription {
    
    if (songEntityDescription == nil) {
        songEntityDescription = [NSEntityDescription entityForName:@"Song" inManagedObjectContext:self.insertionContext];
    }
    return songEntityDescription;
}

- (CategoryCache *)theCache {
    
    if (theCache == nil) {
        theCache = [[CategoryCache alloc] init];
        theCache.managedObjectContext = self.insertionContext;
    }
    return theCache;
}

- (Song *)currentSong {
    
    if (currentSong == nil) {
        currentSong = [[Song alloc] initWithEntity:self.songEntityDescription insertIntoManagedObjectContext:self.insertionContext];
        currentSong.rank = [NSNumber numberWithUnsignedInteger:++rankOfCurrentSong];
    }
    return currentSong;
}


#pragma mark NSURLConnection Delegate methods

// Forward errors to the delegate.
- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    
    [self performSelectorOnMainThread:@selector(forwardError:) withObject:error waitUntilDone:NO];
    // Set the condition which ends the run loop.
    done = YES;
}

// Called when a chunk of data has been downloaded.
- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    
    // Process the downloaded chunk of data.
    xmlParseChunk(context, (const char *)[data bytes], [data length], 0);
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    
    // Signal the context that parsing is complete by passing "1" as the last parameter.
    xmlParseChunk(context, NULL, 0, 1);
    context = NULL;
    // Set the condition which ends the run loop.
    done = YES; 
}


#pragma mark Parsing support methods

static const NSUInteger kImportBatchSize = 20;

- (void)finishedCurrentSong {
    
    parsingASong = NO;
    self.currentSong = nil;
    countForCurrentBatch++;

    if (countForCurrentBatch == kImportBatchSize) {
        
        NSError *saveError = nil;
        NSAssert1([insertionContext save:&saveError], @"Unhandled error saving managed object context in import thread: %@", [saveError localizedDescription]);
        countForCurrentBatch = 0;
    }
}

/*
 Character data is appended to a buffer until the current element ends.
 */
- (void)appendCharacters:(const char *)charactersFound length:(NSInteger)length {
    
    [characterBuffer appendBytes:charactersFound length:length];
}

- (NSString *)currentString {
    
    // Create a string with the character data using UTF-8 encoding. UTF-8 is the default XML data encoding.
    NSString *currentString = [[NSString alloc] initWithData:characterBuffer encoding:NSUTF8StringEncoding];
    [characterBuffer setLength:0];
    return currentString;
}

@end

#pragma mark SAX Parsing Callbacks

// The following constants are the XML element names and their string lengths for parsing comparison.
// The lengths include the null terminator, to ensure exact matches.
static const char *kName_Item = "item";
static const NSUInteger kLength_Item = 5;
static const char *kName_Title = "title";
static const NSUInteger kLength_Title = 6;
static const char *kName_Category = "category";
static const NSUInteger kLength_Category = 9;
static const char *kName_Itms = "itms";
static const NSUInteger kLength_Itms = 5;
static const char *kName_Artist = "artist";
static const NSUInteger kLength_Artist = 7;
static const char *kName_Album = "album";
static const NSUInteger kLength_Album = 6;
static const char *kName_ReleaseDate = "releasedate";
static const NSUInteger kLength_ReleaseDate = 12;

/*
 This callback is invoked when the importer finds the beginning of a node in the XML. For this application,
 out parsing needs are relatively modest - we need only match the node name. An "item" node is a record of
 data about a song. In that case we create a new Song object. The other nodes of interest are several of the
 child nodes of the Song currently being parsed. For those nodes we want to accumulate the character data
 in a buffer. Some of the child nodes use a namespace prefix. 
 */
static void startElementSAX(void *parsingContext, const xmlChar *localname, const xmlChar *prefix, const xmlChar *URI, 
                            int nb_namespaces, const xmlChar **namespaces, int nb_attributes, int nb_defaulted, const xmlChar **attributes) {
    
    iTunesRSSImporter *importer = (__bridge iTunesRSSImporter *)parsingContext;
    // The second parameter to strncmp is the name of the element, which we known from the XML schema of the feed.
    // The third parameter to strncmp is the number of characters in the element name, plus 1 for the null terminator.
    if (prefix == NULL && !strncmp((const char *)localname, kName_Item, kLength_Item)) {
        importer.parsingASong = YES;
    } else if (importer.parsingASong && ( (prefix == NULL && (!strncmp((const char *)localname, kName_Title, kLength_Title) || !strncmp((const char *)localname, kName_Category, kLength_Category))) || ((prefix != NULL && !strncmp((const char *)prefix, kName_Itms, kLength_Itms)) && (!strncmp((const char *)localname, kName_Artist, kLength_Artist) || !strncmp((const char *)localname, kName_Album, kLength_Album) || !strncmp((const char *)localname, kName_ReleaseDate, kLength_ReleaseDate))) )) {
        importer.storingCharacters = YES;
    }
}

/*
 This callback is invoked when the parse reaches the end of a node. At that point we finish processing that node,
 if it is of interest to us. For "item" nodes, that means we have completed parsing a Song object. We pass the song
 to a method in the superclass which will eventually deliver it to the delegate. For the other nodes we
 care about, this means we have all the character data. The next step is to create an NSString using the buffer
 contents and store that with the current Song object.
 */
static void endElementSAX(void *parsingContext, const xmlChar *localname, const xmlChar *prefix, const xmlChar *URI) {
    
    iTunesRSSImporter *importer = (__bridge iTunesRSSImporter *)parsingContext;
    if (importer.parsingASong == NO) return;
    if (prefix == NULL) {
        if (!strncmp((const char *)localname, kName_Item, kLength_Item)) {
            [importer finishedCurrentSong];
        } else if (!strncmp((const char *)localname, kName_Title, kLength_Title)) {
            importer.currentSong.title = importer.currentString;
        } else if (!strncmp((const char *)localname, kName_Category, kLength_Category)) {
            double before = [NSDate timeIntervalSinceReferenceDate];
            Category *category = [importer.theCache categoryWithName:importer.currentString];
            double delta = [NSDate timeIntervalSinceReferenceDate] - before;
            lookuptime += delta;
            importer.currentSong.category = category;
        }
    } else if (!strncmp((const char *)prefix, kName_Itms, kLength_Itms)) {
        if (!strncmp((const char *)localname, kName_Artist, kLength_Artist)) {
            importer.currentSong.artist = importer.currentString;
        } else if (!strncmp((const char *)localname, kName_Album, kLength_Album)) {
            importer.currentSong.album = importer.currentString;
        } else if (!strncmp((const char *)localname, kName_ReleaseDate, kLength_ReleaseDate)) {
            NSString *dateString = importer.currentString;
            importer.currentSong.releaseDate = [importer.dateFormatter dateFromString:dateString];
        }
    }
    importer.storingCharacters = NO;
}

/*
 This callback is invoked when the parser encounters character data inside a node. The importer class determines how to use the character data.
 */
static void charactersFoundSAX(void *parsingContext, const xmlChar *characterArray, int numberOfCharacters) {
    
    iTunesRSSImporter *importer = (__bridge iTunesRSSImporter *)parsingContext;
    // A state variable, "storingCharacters", is set when nodes of interest begin and end. 
    // This determines whether character data is handled or ignored. 
    if (importer.storingCharacters == NO) return;
    [importer appendCharacters:(const char *)characterArray length:numberOfCharacters];
}

/*
 A production application should include robust error handling as part of its parsing implementation.
 The specifics of how errors are handled depends on the application.
 */
static void errorEncounteredSAX(void *parsingContext, const char *errorMessage, ...) {
    
    // Handle errors as appropriate for your application.
    NSCAssert(NO, @"Unhandled error encountered during SAX parse.");
}

// The handler struct has positions for a large number of callback functions. If NULL is supplied at a given position,
// that callback functionality won't be used. Refer to libxml documentation at http://www.xmlsoft.org for more information
// about the SAX callbacks.
static xmlSAXHandler simpleSAXHandlerStruct = {
NULL,                       /* internalSubset */
NULL,                       /* isStandalone   */
NULL,                       /* hasInternalSubset */
NULL,                       /* hasExternalSubset */
NULL,                       /* resolveEntity */
NULL,                       /* getEntity */
NULL,                       /* entityDecl */
NULL,                       /* notationDecl */
NULL,                       /* attributeDecl */
NULL,                       /* elementDecl */
NULL,                       /* unparsedEntityDecl */
NULL,                       /* setDocumentLocator */
NULL,                       /* startDocument */
NULL,                       /* endDocument */
NULL,                       /* startElement*/
NULL,                       /* endElement */
NULL,                       /* reference */
charactersFoundSAX,         /* characters */
NULL,                       /* ignorableWhitespace */
NULL,                       /* processingInstruction */
NULL,                       /* comment */
NULL,                       /* warning */
errorEncounteredSAX,        /* error */
NULL,                       /* fatalError //: unused error() get all the errors */
NULL,                       /* getParameterEntity */
NULL,                       /* cdataBlock */
NULL,                       /* externalSubset */
XML_SAX2_MAGIC,             //
NULL,
startElementSAX,            /* startElementNs */
endElementSAX,              /* endElementNs */
NULL,                       /* serror */
};
