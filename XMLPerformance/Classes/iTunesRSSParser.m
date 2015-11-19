/*
 Copyright (C) 2015 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 Base class for the two parsers, this class handles interactions with a delegate object (the SongsViewController in this sample) and provides basic functionality common to both parsers.
 */

#import "iTunesRSSParser.h"
#import "Statistics.h"

static NSUInteger kCountForNotification = 10;


@interface iTunesRSSParser ()

@property (nonatomic, strong) NSMutableArray *parsedSongs;
@property (nonatomic, assign) NSTimeInterval startTimeReference;
@property (nonatomic, assign) NSTimeInterval downloadStartTimeReference;
@property (nonatomic, assign) double parseDuration;
@property (nonatomic, assign) double downloadDuration;
@property (nonatomic, assign) double totalDuration;

@end

@implementation iTunesRSSParser


@synthesize delegate, parsedSongs, startTimeReference, downloadStartTimeReference, parseDuration, downloadDuration; //totalDuration;

+ (NSString *)parserName {
    NSAssert((self != [iTunesRSSParser class]), @"Class method parserName not valid for abstract base class iTunesRSSParser");
    return @"Base Class";
}

+ (XMLParserType)parserType {
    NSAssert((self != [iTunesRSSParser class]), @"Class method parserType not valid for abstract base class iTunesRSSParser");
    return XMLParserTypeAbstract;
}

- (void)start {
    self.startTimeReference = [NSDate timeIntervalSinceReferenceDate];
    [[NSURLCache sharedURLCache] removeAllCachedResponses];
    self.parsedSongs = [NSMutableArray array];
    NSURL *url = [NSURL URLWithString:@"http://ax.phobos.apple.com.edgesuite.net/WebObjects/MZStore.woa/wpa/MRSS/newreleases/limit=300/rss.xml"];
    [NSThread detachNewThreadSelector:@selector(downloadAndParse:) toTarget:self withObject:url];
}


- (void)downloadAndParse:(NSURL *)url {
    NSAssert([self isMemberOfClass:[iTunesRSSParser class]] == NO, @"Object is of abstract base class iTunesRSSParser");
}

- (void)downloadStarted {
    NSAssert2([NSThread isMainThread], @"%s at line %d called on secondary thread", __FUNCTION__, __LINE__);
    self.downloadStartTimeReference = [NSDate timeIntervalSinceReferenceDate];
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
}

- (void)downloadEnded {
    NSAssert2([NSThread isMainThread], @"%s at line %d called on secondary thread", __FUNCTION__, __LINE__);
    NSTimeInterval duration = [NSDate timeIntervalSinceReferenceDate] - self.downloadStartTimeReference;
    downloadDuration += duration;
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
}

- (void)parseEnded {
    NSAssert2([NSThread isMainThread], @"%s at line %d called on secondary thread", __FUNCTION__, __LINE__);
    if (self.delegate != nil && [self.delegate respondsToSelector:@selector(parser:didParseSongs:)] && parsedSongs.count > 0) {
        [self.delegate parser:self didParseSongs:parsedSongs];
    }
    [self.parsedSongs removeAllObjects];
    if (self.delegate != nil && [self.delegate respondsToSelector:@selector(parserDidEndParsingData:)]) {
        [self.delegate parserDidEndParsingData:self];
    }
    NSTimeInterval duration = [NSDate timeIntervalSinceReferenceDate] - self.startTimeReference;
    _totalDuration = duration;
    WriteStatisticToDatabase([[self class] parserType], downloadDuration, parseDuration, _totalDuration);
}

- (void)parsedSong:(Song *)song {
    NSAssert2([NSThread isMainThread], @"%s at line %d called on secondary thread", __FUNCTION__, __LINE__);
    [self.parsedSongs addObject:song];
    if (self.parsedSongs.count > kCountForNotification) {
        if (self.delegate != nil && [self.delegate respondsToSelector:@selector(parser:didParseSongs:)]) {
            [self.delegate parser:self didParseSongs:parsedSongs];
        }
        [self.parsedSongs removeAllObjects];
    }
}

- (void)parseError:(NSError *)error {
    NSAssert2([NSThread isMainThread], @"%s at line %d called on secondary thread", __FUNCTION__, __LINE__);
    if (self.delegate != nil && [self.delegate respondsToSelector:@selector(parser:didFailWithError:)]) {
        [self.delegate parser:self didFailWithError:error];
    }
}

- (void)addToParseDuration:(NSNumber *)duration {
    NSAssert2([NSThread isMainThread], @"%s at line %d called on secondary thread", __FUNCTION__, __LINE__);
    parseDuration += duration.doubleValue;
}

@end
