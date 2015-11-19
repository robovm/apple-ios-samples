/*
 Copyright (C) 2015 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 Subclass of iTunesRSSParser that uses the Foundation framework's NSXMLParser for parsing the XML data.
 */

#import "CocoaXMLParser.h"
#import "Song.h"


@interface CocoaXMLParser ()

// A string containing the contents of the current song data to be parsed.
@property (nonatomic, strong) NSMutableString *currentString;
// A reference to the current song the parser is working with.
@property (nonatomic, strong) Song *currentSong;
// The following state variable deals with getting character data from XML elements.
@property (nonatomic, assign) BOOL storingCharacters;
@property (nonatomic, strong) NSDateFormatter *parseFormatter;
// Overall state of the parser, used to exit the run loop.
@property (nonatomic, assign) BOOL done;
// the queue to run our parse operation
@property (nonatomic, strong) NSOperationQueue *queue;

@end


#pragma mark -

@implementation CocoaXMLParser

+ (NSString *)parserName {
    return @"NSXMLParser";
}

+ (XMLParserType)parserType {
    return XMLParserTypeNSXMLParser;
}

@synthesize currentString, currentSong, parseFormatter;

- (void)startDownload:(NSURL *)url {
    
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    
    // create a session data task to obtain and the XML feed
    NSURLSessionDataTask *sessionTask = [[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        // in case we want to know the response status code
        //NSInteger HTTPStatusCode = [(NSHTTPURLResponse *)response statusCode];
        
        _done = YES;
        
        if (error != nil)
        {
            [[NSOperationQueue mainQueue] addOperationWithBlock: ^{
                [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
                
                if (error.code == NSURLErrorAppTransportSecurityRequiresSecureConnection)
                {
                    // if you get error NSURLErrorAppTransportSecurityRequiresSecureConnection (-1022),
                    // then your Info.plist has not been properly configured to match the target server.
                    //
                    abort();
                }
                else
                {
                    NSLog(@"An error occured in '%@': error[%ld] %@",
                          NSStringFromSelector(_cmd), (long)error.code, error.localizedDescription);
                }
            }];
        }
        else
        {
            dispatch_async(dispatch_get_main_queue(), ^(void) {
                [self downloadEnded];
            });
            
            // continue our work by pasing the resulting data
            NSXMLParser *parser = [[NSXMLParser alloc] initWithData:data];
            parser.delegate = self;
            self.currentString = [NSMutableString string];
            NSTimeInterval start = [NSDate timeIntervalSinceReferenceDate];
            [parser parse];
            NSTimeInterval duration = [NSDate timeIntervalSinceReferenceDate] - start;
            [self performSelectorOnMainThread:@selector(addToParseDuration:)
                                   withObject:@(duration)
                                waitUntilDone:NO];
            
            dispatch_async(dispatch_get_main_queue(), ^(void) {
                [self parseEnded];
            });
            
            self.currentString = nil;
        }
    }];
    
    // start loading the data
    [self downloadStarted];
    
    [sessionTask resume];
}

- (void)downloadAndParse:(NSURL *)url {
    
    _done = NO;
    self.parseFormatter = [[NSDateFormatter alloc] init];
    parseFormatter.dateStyle = NSDateFormatterLongStyle;
    parseFormatter.timeStyle = NSDateFormatterNoStyle;
    // necessary because iTunes RSS feed is not localized, so if the device region has been set to other than US
    // the date formatter must be set to US locale in order to parse the dates
    parseFormatter.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"US"];
    
    [[NSURLCache sharedURLCache] removeAllCachedResponses];
    
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
    
    // performSelectorOnMainThread: will retain the object until the selector has been performed
    // setting the local reference to nil ensures that the local reference will be released
    //
    [self performSelectorOnMainThread:@selector(parsedSong:)
                           withObject:currentSong
                        waitUntilDone:NO];
    
    self.currentSong = nil;
}


#pragma mark NSXMLParser Parsing Callbacks

// Constants for the XML element names that will be considered during the parse. 
// Declaring these as static constants reduces the number of objects created during the run
// and is less prone to programmer error.
//
static NSString *kName_Item = @"item";
static NSString *kName_Title = @"title";
static NSString *kName_Category = @"category";
static NSString *kName_Artist = @"itms:artist";
static NSString *kName_Album = @"itms:album";
static NSString *kName_ReleaseDate = @"itms:releasedate";

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *) qualifiedName attributes:(NSDictionary *)attributeDict {
    
    if ([elementName isEqualToString:kName_Item]) {
        self.currentSong = [[Song alloc] init];
    } else if ([elementName isEqualToString:kName_Title] || [elementName isEqualToString:kName_Category] || [elementName isEqualToString:kName_Artist] || [elementName isEqualToString:kName_Album] || [elementName isEqualToString:kName_ReleaseDate]) {
        [currentString setString:@""];
        _storingCharacters = YES;
    }
}

- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName {

    if ([elementName isEqualToString:kName_Item]) {
        [self finishedCurrentSong];
    } else if ([elementName isEqualToString:kName_Title]) {
        currentSong.title = currentString;
    } else if ([elementName isEqualToString:kName_Category]) {
        currentSong.category = currentString;
    } else if ([elementName isEqualToString:kName_Artist]) {
        currentSong.artist = currentString;
    } else if ([elementName isEqualToString:kName_Album]) {
        currentSong.album = currentString;
    } else if ([elementName isEqualToString:kName_ReleaseDate]) {
        currentSong.releaseDate = [parseFormatter dateFromString:currentString];
    }
    _storingCharacters = NO;
}

- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string {
    if (_storingCharacters) [currentString appendString:string];
}

/*
 A production application should include robust error handling as part of its parsing implementation.
 The specifics of how errors are handled depends on the application.
 */
- (void)parser:(NSXMLParser *)parser parseErrorOccurred:(NSError *)parseError {
    // Handle errors as appropriate for your application.
}

@end
