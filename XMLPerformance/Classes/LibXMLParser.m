/*
     File: LibXMLParser.m
 Abstract: Subclass of iTunesRSSParser that uses libxml2 for parsing the XML data.
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

#import "LibXMLParser.h"
#import "Song.h"
#import <libxml/tree.h>

// Function prototypes for SAX callbacks. This sample implements a minimal subset of SAX callbacks.
// Depending on your application's needs, you might want to implement more callbacks.
static void startElementSAX(void *ctx, const xmlChar *localname, const xmlChar *prefix, const xmlChar *URI, int nb_namespaces, const xmlChar **namespaces, int nb_attributes, int nb_defaulted, const xmlChar **attributes);
static void	endElementSAX(void *ctx, const xmlChar *localname, const xmlChar *prefix, const xmlChar *URI);
static void	charactersFoundSAX(void * ctx, const xmlChar * ch, int len);
static void errorEncounteredSAX(void * ctx, const char * msg, ...);

// Forward reference. The structure is defined in full at the end of the file.
static xmlSAXHandler simpleSAXHandlerStruct;

@implementation LibXMLParser

@synthesize rssConnection, done, parsingASong, storingCharacters, currentSong, characterBuffer, parseFormatter;

+ (NSString *)parserName {
    return @"libxml2";
}

+ (XMLParserType)parserType {
    return XMLParserTypeLibXMLParser;
}

/*
This method is called on a secondary thread by the superclass. We have asynchronous work to do here with downloading and parsing data, so we will need a run loop to prevent the thread from exiting before we are finished.
*/
- (void)downloadAndParse:(NSURL *)url {

    done = NO;
    self.parseFormatter = [[NSDateFormatter alloc] init];
    [parseFormatter setDateStyle:NSDateFormatterLongStyle];
    [parseFormatter setTimeStyle:NSDateFormatterNoStyle];
    // necessary because iTunes RSS feed is not localized, so if the device region has been set to other than US
    // the date formatter must be set to US locale in order to parse the dates
    [parseFormatter setLocale:[[NSLocale alloc] initWithLocaleIdentifier:@"US"]];
    self.characterBuffer = [NSMutableData data];
    [[NSURLCache sharedURLCache] removeAllCachedResponses];
    NSURLRequest *theRequest = [NSURLRequest requestWithURL:url];
    // create the connection with the request and start loading the data
    rssConnection = [[NSURLConnection alloc] initWithRequest:theRequest delegate:self];
    // This creates a context for "push" parsing in which chunks of data that are not "well balanced" can be passed
    // to the context for streaming parsing. The handler structure defined above will be used for all the parsing. 
    // The second argument, self, will be passed as user data to each of the SAX handlers. The last three arguments
    // are left blank to avoid creating a tree in memory.
    context = xmlCreatePushParserCtxt(&simpleSAXHandlerStruct, (__bridge void *)(self), NULL, 0, NULL);
    [self performSelectorOnMainThread:@selector(downloadStarted) withObject:nil waitUntilDone:NO];
    if (rssConnection != nil) {
        do {
            [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]];
        } while (!done);
    }
    // Release resources used only in this thread.
    xmlFreeParserCtxt(context);
    self.characterBuffer = nil;
    self.parseFormatter = nil;
    self.rssConnection = nil;
    self.currentSong = nil;
}


#pragma mark - NSURLConnection Delegate methods

/*
Disable caching so that each time we run this app we are starting with a clean slate. You may not want to do this in your application.
*/
- (NSCachedURLResponse *)connection:(NSURLConnection *)connection willCacheResponse:(NSCachedURLResponse *)cachedResponse {
    return nil;
}

// Forward errors to the delegate.
- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    
    done = YES;
    [self performSelectorOnMainThread:@selector(parseError:) withObject:error waitUntilDone:NO];
}

// Called when a chunk of data has been downloaded.
- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    
    NSTimeInterval start = [NSDate timeIntervalSinceReferenceDate];
    // Process the downloaded chunk of data.
    xmlParseChunk(context, (const char *)[data bytes], [data length], 0);
    NSTimeInterval duration = [NSDate timeIntervalSinceReferenceDate] - start;
    [self performSelectorOnMainThread:@selector(addToParseDuration:) withObject:[NSNumber numberWithDouble:duration] waitUntilDone:NO];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    
    [self performSelectorOnMainThread:@selector(downloadEnded) withObject:nil waitUntilDone:NO];
    NSTimeInterval start = [NSDate timeIntervalSinceReferenceDate];
    // Signal the context that parsing is complete by passing "1" as the last parameter.
    xmlParseChunk(context, NULL, 0, 1);
    NSTimeInterval duration = [NSDate timeIntervalSinceReferenceDate] - start;
    [self performSelectorOnMainThread:@selector(addToParseDuration:) withObject:[NSNumber numberWithDouble:duration] waitUntilDone:NO];
    [self performSelectorOnMainThread:@selector(parseEnded) withObject:nil waitUntilDone:NO];
    // Set the condition which ends the run loop.
    done = YES; 
}

#pragma mark Parsing support methods

static const NSUInteger kAutoreleasePoolPurgeFrequency = 20;

- (void)finishedCurrentSong {
    
    [self performSelectorOnMainThread:@selector(parsedSong:) withObject:currentSong waitUntilDone:NO];
    // performSelectorOnMainThread: will retain the object until the selector has been performed
    // setting the local reference to nil ensures that the local reference will be released
    self.currentSong = nil;
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
 This callback is invoked when the parser finds the beginning of a node in the XML. For this application,
 out parsing needs are relatively modest - we need only match the node name. An "item" node is a record of
 data about a song. In that case we create a new Song object. The other nodes of interest are several of the
 child nodes of the Song currently being parsed. For those nodes we want to accumulate the character data
 in a buffer. Some of the child nodes use a namespace prefix. 
 */
static void startElementSAX(void *ctx, const xmlChar *localname, const xmlChar *prefix, const xmlChar *URI, 
                            int nb_namespaces, const xmlChar **namespaces, int nb_attributes, int nb_defaulted, const xmlChar **attributes) {
    
    LibXMLParser *parser = (__bridge LibXMLParser *)ctx;
    // The second parameter to strncmp is the name of the element, which we known from the XML schema of the feed.
    // The third parameter to strncmp is the number of characters in the element name, plus 1 for the null terminator.
    if (prefix == NULL && !strncmp((const char *)localname, kName_Item, kLength_Item)) {
        Song *newSong = [[Song alloc] init];
        parser.currentSong = newSong;
        parser.parsingASong = YES;
    } else if (parser.parsingASong && ( (prefix == NULL && (!strncmp((const char *)localname, kName_Title, kLength_Title) || !strncmp((const char *)localname, kName_Category, kLength_Category))) || ((prefix != NULL && !strncmp((const char *)prefix, kName_Itms, kLength_Itms)) && (!strncmp((const char *)localname, kName_Artist, kLength_Artist) || !strncmp((const char *)localname, kName_Album, kLength_Album) || !strncmp((const char *)localname, kName_ReleaseDate, kLength_ReleaseDate))) )) {
        parser.storingCharacters = YES;
    }
}

/*
 This callback is invoked when the parse reaches the end of a node. At that point we finish processing that node,
 if it is of interest to us. For "item" nodes, that means we have completed parsing a Song object. We pass the song
 to a method in the superclass which will eventually deliver it to the delegate. For the other nodes we
 care about, this means we have all the character data. The next step is to create an NSString using the buffer
 contents and store that with the current Song object.
 */
static void	endElementSAX(void *ctx, const xmlChar *localname, const xmlChar *prefix, const xmlChar *URI) {
    
    LibXMLParser *parser = (__bridge LibXMLParser *)ctx;
    if (parser.parsingASong == NO) return;
    if (prefix == NULL) {
        if (!strncmp((const char *)localname, kName_Item, kLength_Item)) {
            [parser finishedCurrentSong];
            parser.parsingASong = NO;
        } else if (!strncmp((const char *)localname, kName_Title, kLength_Title)) {
            parser.currentSong.title = [parser currentString];
        } else if (!strncmp((const char *)localname, kName_Category, kLength_Category)) {
            parser.currentSong.category = [parser currentString];
        }
    } else if (!strncmp((const char *)prefix, kName_Itms, kLength_Itms)) {
        if (!strncmp((const char *)localname, kName_Artist, kLength_Artist)) {
            parser.currentSong.artist = [parser currentString];
        } else if (!strncmp((const char *)localname, kName_Album, kLength_Album)) {
            parser.currentSong.album = [parser currentString];
        } else if (!strncmp((const char *)localname, kName_ReleaseDate, kLength_ReleaseDate)) {
            NSString *dateString = [parser currentString];
            parser.currentSong.releaseDate = [parser.parseFormatter dateFromString:dateString];
        }
    }
    parser.storingCharacters = NO;
}

/*
 This callback is invoked when the parser encounters character data inside a node. The parser class determines how to use the character data.
*/
static void	charactersFoundSAX(void *ctx, const xmlChar *ch, int len) {
    
    LibXMLParser *parser = (__bridge LibXMLParser *)ctx;
    // A state variable, "storingCharacters", is set when nodes of interest begin and end. 
    // This determines whether character data is handled or ignored. 
    if (parser.storingCharacters == NO) return;
    [parser appendCharacters:(const char *)ch length:len];
}

/*
 A production application should include robust error handling as part of its parsing implementation.
 The specifics of how errors are handled depends on the application.
 */
static void errorEncounteredSAX(void *ctx, const char *msg, ...) {
    
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
