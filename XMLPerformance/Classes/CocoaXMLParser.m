/*
     File: CocoaXMLParser.m
 Abstract: Subclass of iTunesRSSParser that uses the Foundation framework's NSXMLParser for parsing the XML data.
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

#import "CocoaXMLParser.h"
#import "Song.h"

@implementation CocoaXMLParser

+ (NSString *)parserName {
    return @"NSXMLParser";
}

+ (XMLParserType)parserType {
    return XMLParserTypeNSXMLParser;
}

@synthesize currentString, currentSong, parseFormatter, xmlData, rssConnection;

- (void)downloadAndParse:(NSURL *)url {

    done = NO;
    self.parseFormatter = [[NSDateFormatter alloc] init];
    [parseFormatter setDateStyle:NSDateFormatterLongStyle];
    [parseFormatter setTimeStyle:NSDateFormatterNoStyle];
    // necessary because iTunes RSS feed is not localized, so if the device region has been set to other than US
    // the date formatter must be set to US locale in order to parse the dates
    [parseFormatter setLocale:[[NSLocale alloc] initWithLocaleIdentifier:@"US"]];
    self.xmlData = [NSMutableData data];
    [[NSURLCache sharedURLCache] removeAllCachedResponses];
    NSURLRequest *theRequest = [NSURLRequest requestWithURL:url];
    // create the connection with the request and start loading the data
    rssConnection = [[NSURLConnection alloc] initWithRequest:theRequest delegate:self];
    [self performSelectorOnMainThread:@selector(downloadStarted)
                           withObject:nil
                        waitUntilDone:NO];
    if (rssConnection != nil) {
        do {
            [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]];
        } while (!done);
    }
    self.rssConnection = nil;
    self.parseFormatter = nil;
    self.currentSong = nil;
}


#pragma mark NSURLConnection Delegate methods

/*
 Disable caching so that each time we run this app we are starting with a clean slate.
 You may not want to do this in your application.
 */
- (NSCachedURLResponse *)connection:(NSURLConnection *)connection willCacheResponse:(NSCachedURLResponse *)cachedResponse {
    return nil;
}

// Forward errors to the delegate.
- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    
    done = YES;
    [self performSelectorOnMainThread:@selector(parseError:)
                           withObject:error
                        waitUntilDone:NO];
}

// Called when a chunk of data has been downloaded.
- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    
    // Append the downloaded chunk of data.
    [xmlData appendData:data];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    
    [self performSelectorOnMainThread:@selector(downloadEnded)
                           withObject:nil
                        waitUntilDone:NO];
    NSXMLParser *parser = [[NSXMLParser alloc] initWithData:xmlData];
    parser.delegate = self;
    self.currentString = [NSMutableString string];
    NSTimeInterval start = [NSDate timeIntervalSinceReferenceDate];
    [parser parse];
    NSTimeInterval duration = [NSDate timeIntervalSinceReferenceDate] - start;
    [self performSelectorOnMainThread:@selector(addToParseDuration:)
                           withObject:[NSNumber numberWithDouble:duration]
                        waitUntilDone:NO];
    [self performSelectorOnMainThread:@selector(parseEnded)
                           withObject:nil
                        waitUntilDone:NO];
    self.currentString = nil;
    self.xmlData = nil;
    // Set the condition which ends the run loop.
    done = YES; 
}


#pragma mark Parsing support methods

static const NSUInteger kAutoreleasePoolPurgeFrequency = 20;

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
        storingCharacters = YES;
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
    storingCharacters = NO;
}

- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string {
    if (storingCharacters) [currentString appendString:string];
}

/*
 A production application should include robust error handling as part of its parsing implementation.
 The specifics of how errors are handled depends on the application.
 */
- (void)parser:(NSXMLParser *)parser parseErrorOccurred:(NSError *)parseError {
    // Handle errors as appropriate for your application.
}

@end
