/*
 Copyright (C) 2015 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 Base class for the two parsers, this class handles interactions with a delegate object (the SongsViewController in this sample) and provides basic functionality common to both parsers.
*/

@import UIKit;

typedef NS_ENUM(int, XMLParserType) {
    XMLParserTypeAbstract = -1,
    XMLParserTypeNSXMLParser = 0,
    XMLParserTypeLibXMLParser
};

@class iTunesRSSParser, Song;

// Protocol for the parser to communicate with its delegate.
@protocol iTunesRSSParserDelegate <NSObject>

@optional
// Called by the parser when parsing is finished.
- (void)parserDidEndParsingData:(iTunesRSSParser *)parser;
// Called by the parser in the case of an error.
- (void)parser:(iTunesRSSParser *)parser didFailWithError:(NSError *)error;
// Called by the parser when one or more songs have been parsed. This method may be called multiple times.
- (void)parser:(iTunesRSSParser *)parser didParseSongs:(NSArray *)parsedSongs;

@end

#pragma mark -

@interface iTunesRSSParser : NSObject

@property (nonatomic, weak) id <iTunesRSSParserDelegate> delegate;

+ (NSString *)parserName;
+ (XMLParserType)parserType;

- (void)start;

// Subclasses must implement this method. It will be invoked on a secondary thread to keep the application responsive.
// The parsing can be quite CPU intensive on the device, so
// the user interface can be kept responsive by moving that work off the main thread. This does create additional
// complexity, as any code which interacts with the UI must then do so in a thread-safe manner.
- (void)downloadAndParse:(NSURL *)url;

// Subclasses should invoke these methods and let the superclass manage communication with the delegate.
// Each of these methods must be invoked on the main thread.
- (void)downloadStarted;
- (void)downloadEnded;
- (void)parseEnded;
- (void)parsedSong:(Song *)song;
- (void)parseError:(NSError *)error;
- (void)addToParseDuration:(NSNumber *)duration;

@end
