/*
 Copyright (C) 2015 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 Subclass of iTunesRSSParser that uses libxml2 for parsing the XML data.
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


@interface LibXMLParser ()

// Reference to the libxml parser context
@property (nonatomic, assign) xmlParserCtxtPtr context;
// Overall state of the parser, used to exit the run loop.
@property (nonatomic, assign) BOOL done;
// State variable used to determine whether or not to ignore a given XML element
@property (nonatomic, assign) BOOL parsingASong;
// The following state variables deal with getting character data from XML elements. This is a potentially expensive
// operation. The character data in a given element may be delivered over the course of multiple callbacks, so that
// data must be appended to a buffer. The optimal way of doing this is to use a C string buffer that grows exponentially.
// When all the characters have been delivered, an NSString is constructed and the buffer is reset.
@property (nonatomic, assign) BOOL storingCharacters;
@property (nonatomic, strong) NSMutableData *characterBuffer;
// A reference to the current song the parser is working with.
@property (nonatomic, strong) Song *currentSong;
@property (nonatomic, strong) NSDateFormatter *parseFormatter;
// the queue to run our parse operation
@property (nonatomic, strong) NSOperationQueue *queue;

@end


#pragma mark -

@implementation LibXMLParser

@synthesize currentSong, parseFormatter;

+ (NSString *)parserName {
    return @"libxml2";
}

+ (XMLParserType)parserType {
    return XMLParserTypeLibXMLParser;
}


- (void)startDownload:(NSURL *)url {
    
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    
    // create a session data task to obtain and the XML feed
    NSURLSessionDataTask *sessionTask = [[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        // in case we want to know the response status code
        // NSInteger HTTPStatusCode = [(NSHTTPURLResponse *)response statusCode];
        
        _done = YES;
        
        if (error != nil) {
            [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
                
                if (error.code == NSURLErrorAppTransportSecurityRequiresSecureConnection) {
                    // if you get error NSURLErrorAppTransportSecurityRequiresSecureConnection (-1022),
                    // then your Info.plist has not been properly configured to match the target server.
                    //
                    abort();
                }
                else {
                    NSLog(@"An error occured in '%@': error[%ld] %@",
                          NSStringFromSelector(_cmd), (long)error.code, error.localizedDescription);
                }
            }];
        }
        else {
            
            dispatch_async(dispatch_get_main_queue(), ^(void){
                [self downloadEnded];
            });
            
            NSTimeInterval start = [NSDate timeIntervalSinceReferenceDate];
            // Process the downloaded chunk of data.
            xmlParseChunk(_context, (const char *)data.bytes, (int)data.length, 0);
            // Signal the context that parsing is complete by passing "1" as the last parameter.
            xmlParseChunk(_context, NULL, 0, 1);
            NSTimeInterval duration = [NSDate timeIntervalSinceReferenceDate] - start;
            [self performSelectorOnMainThread:@selector(addToParseDuration:) withObject:@(duration) waitUntilDone:NO];
            
            // this loop runs until the data is downloaded
            // done is set to YES in the completion block once the parsing starts
            dispatch_async(dispatch_get_main_queue(), ^(void) {
                [self parseEnded];
            });
        }
    }];
    
    // start loading the data
    [self downloadStarted];
    
    [sessionTask resume];
}


/*
This method is called on a secondary thread by the superclass. We have asynchronous work to do here with downloading and parsing data, so we will need a run loop to prevent the thread from exiting before we are finished.
*/

- (void)downloadAndParse:(NSURL *)url {
    
    _done = NO;
    self.parseFormatter = [[NSDateFormatter alloc] init];
    parseFormatter.dateStyle = NSDateFormatterLongStyle;
    parseFormatter.timeStyle = NSDateFormatterNoStyle;
    // necessary because iTunes RSS feed is not localized, so if the device region has been set to other than US
    // the date formatter must be set to US locale in order to parse the dates
    parseFormatter.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"US"];
    self.characterBuffer = [NSMutableData data];
    [[NSURLCache sharedURLCache] removeAllCachedResponses];
    
    // This creates a context for "push" parsing in which chunks of data that are not "well balanced" can be passed
    // to the context for streaming parsing. The handler structure defined above will be used for all the parsing.
    // The second argument, self, will be passed as user data to each of the SAX handlers. The last three arguments
    // are left blank to avoid creating a tree in memory.
    _context = xmlCreatePushParserCtxt(&simpleSAXHandlerStruct, (__bridge void *)(self), NULL, 0, NULL);
    
    // call startDownload, which starts downloading the songs
    [self performSelectorOnMainThread:@selector(startDownload:) withObject:url waitUntilDone:NO];
    
    // this loop runs until all the data is downloaded
    // done is set to YES in the completion block once the downloading is finished
    do {
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]];
    }while (!_done);
}


#pragma mark Parsing support methods

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
    
    [_characterBuffer appendBytes:charactersFound length:length];
}

- (NSString *)currentString {
    
    // Create a string with the character data using UTF-8 encoding. UTF-8 is the default XML data encoding.
    NSString *currentString = [[NSString alloc] initWithData:_characterBuffer encoding:NSUTF8StringEncoding];
    _characterBuffer.length = 0;
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
 our parsing needs are relatively modest - we need only match the node name. An "item" node is a record of
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
