/*
 Copyright (C) 2016 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 The NSOperation class used to perform the XML parsing of earthquake data.
 */

#import "APLParseOperation.h"
#import "APLEarthquake.h"
#import "APLCoreDataStackManager.h"

@interface APLParseOperation () <NSXMLParserDelegate>

@property (nonatomic) APLEarthquake *currentEarthquakeObject;
@property (nonatomic) NSMutableArray *currentParseBatch;
@property (nonatomic) NSMutableString *currentParsedCharacterData;

@property (nonatomic, strong) NSDateFormatter *dateFormatter;

@property (assign) BOOL accumulatingParsedCharacterData;
@property (assign) BOOL didAbortParsing;

@property (assign) NSUInteger parsedEarthquakesCounter;

@property (assign) BOOL seekDescription;
@property (assign) BOOL seekTime;
@property (assign) BOOL seekLatitude;
@property (assign) BOOL seekLongitude;
@property (assign) BOOL seekMagnitude;

// a stack queue containing  elements as they are being parsed, used to detect malformed XML.
@property (nonatomic, strong) NSMutableArray *elementStack;

@end


#pragma mark -

@implementation APLParseOperation

+ (NSString *)AddEarthQuakesNotificationName
{
    return @"AddEarthquakesNotif";
}

+ (NSString *)EarthquakeResultsKey
{
    return @"EarthquakeResultsKey";
}

+ (NSString *)EarthquakesErrorNotificationName
{
    return @"EarthquakeErrorNotif";
}

+ (NSString *)EarthquakesMessageErrorKey
{
    return @"EarthquakesMsgErrorKey";
}

- (instancetype)init {
    
    NSAssert(NO, @"Invalid use of init; use initWithData to create APLParseOperation");
    return [self init];
}

- (instancetype)initWithData:(NSData *)parseData {
    
    self = [super init];
    if (self != nil && parseData != nil) {
        _earthquakeData = [parseData copy];
        
        _dateFormatter = [[NSDateFormatter alloc] init];
        self.dateFormatter.timeZone = [NSTimeZone timeZoneForSecondsFromGMT:0];
        self.dateFormatter.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
        self.dateFormatter.dateFormat = @"yyyy-MM-dd'T'HH:mm:ss.SSS'Z'";
        
        // 2015-09-24T16:01:00.283Z

        _currentParseBatch = [[NSMutableArray alloc] init];
        _currentParsedCharacterData = [[NSMutableString alloc] init];
        
        _elementStack = [[NSMutableArray alloc] init];
    }
    return self;
}

- (void)addEarthquakesToList:(NSArray *)earthquakes {
    
    // send the earthquakes to APLEarthQuakeSource
    [[NSNotificationCenter defaultCenter] postNotificationName:APLParseOperation.AddEarthQuakesNotificationName
                                                        object:self
                                                      userInfo:@{APLParseOperation.EarthquakeResultsKey: earthquakes}];
}

// The main function for this NSOperation, to start the parsing on a secondary thread
- (void)main {

    /*
     It's also possible to have NSXMLParser download the data, by passing it a URL, but this is not desirable because it gives less control over the network, particularly in responding to connection errors.
     */
    NSXMLParser *parser = [[NSXMLParser alloc] initWithData:self.earthquakeData];
    parser.delegate = self;
    [parser parse];

    /*
     Depending on the total number of earthquakes parsed, the last batch might not have been a "full" batch, and thus not been part of the regular batch transfer. So, we check the count of the array and, if necessary, send it to the main thread.
     */
    if (self.currentParseBatch.count > 0) {
        [self addEarthquakesToList:self.currentParseBatch];
    }
}


#pragma mark - Parser constants

/*
 Limit the number of parsed earthquakes to 50 (a given day may have more than 50 earthquakes around the world, so we only take the first 50).
 */
static const NSUInteger kMaximumNumberOfEarthquakesToParse = 50;

/*
 When an Earthquake object has been fully constructed, it must be passed to the main thread and the table view in RootViewController must be reloaded to display it. It is not efficient to do this for every Earthquake object - the overhead in communicating between the threads and reloading the table exceed the benefit to the user. Instead, we pass the objects in batches, sized by the constant below. In your application, the optimal batch size will vary depending on the amount of data in the object and other factors, as appropriate.
 */
static NSUInteger const kSizeOfEarthquakeBatch = 10;

// Reduce potential parsing errors by using string constants declared in a single place.
static NSString * const kValueKey = @"value";

static NSString * const kEntryElementName = @"event";

static NSString * const kDescriptionElementDesc = @"description";
static NSString * const kDescriptionElementContent = @"text";

static NSString * const kTimeElementName = @"time";

static NSString * const kLatitudeElementName = @"latitude";
static NSString * const kLongitudeElementName = @"longitude";

static NSString * const kMagitudeValueName = @"mag";


#pragma mark - NSXMLParserDelegate

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict {
    
    // add the element to the state stack
    [self.elementStack addObject:elementName];
    
    /*
     If the number of parsed earthquakes is greater than kMaximumNumberOfEarthquakesToParse, abort the parse.
     */
    if (self.parsedEarthquakesCounter >= kMaximumNumberOfEarthquakesToParse) {
        // Use the flag didAbortParsing to distinguish between this deliberate stop and other parser errors
        _didAbortParsing = YES;
        [parser abortParsing];
    }
    
    if ([elementName isEqualToString:kEntryElementName]) {

        NSEntityDescription *ent =
            [NSEntityDescription entityForName:@"APLEarthquake" inManagedObjectContext:[[APLCoreDataStackManager sharedManager] managedObjectContext]];
        
        // create an earthquake managed object, but don't insert it in our moc yet
        APLEarthquake *earthquake = [[APLEarthquake alloc] initWithEntity:ent insertIntoManagedObjectContext:nil];
        self.currentEarthquakeObject = earthquake;
    }
    else if ((self.seekDescription && [elementName isEqualToString:kDescriptionElementContent]) ||  // <description>..<text>
             (self.seekTime && [elementName isEqualToString:kValueKey]) ||                          // <time>..<value>
             (self.seekLatitude && [elementName isEqualToString:kValueKey]) ||              // <latitude>..<value>
             (self.seekLongitude && [elementName isEqualToString:kValueKey]) ||             // <longitude>..<value>
             (self.seekMagnitude && [elementName isEqualToString:kValueKey]))               // <mag>..<value>
    {
        // For elements: <text> and <value>, the contents are collected in parser:foundCharacters:
        _accumulatingParsedCharacterData = YES;
        // The mutable string needs to be reset to empty.
        self.currentParsedCharacterData = [NSMutableString stringWithString:@""];
    }
    else if ([elementName isEqualToString:kDescriptionElementDesc])
        _seekDescription = YES;
    else if ([elementName isEqualToString:kTimeElementName])
        _seekTime = YES;
    else if ([elementName isEqualToString:kLatitudeElementName])
         _seekLatitude = YES;
    else if ([elementName isEqualToString:kLongitudeElementName])
        _seekLongitude = YES;
    else if ([elementName isEqualToString:kMagitudeValueName])
        _seekMagnitude = YES;
}

- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName {
    
    // check if the end element matches what's last on the element stack
    if ([elementName isEqualToString:self.elementStack.lastObject]) {
        // they match, remove it
        [self.elementStack removeLastObject];
    }
    else {
        // they don't match, we have malformed XML
        NSLog(@"could not find end element of \"%@\"", elementName);
        [self.elementStack removeAllObjects];
        [parser abortParsing];
    }
    
    if ([elementName isEqualToString:kEntryElementName]) {
        
        // end earthquake entry, add it to the array
        [self.currentParseBatch addObject:self.currentEarthquakeObject];
        _parsedEarthquakesCounter++;

        if (self.currentParseBatch.count >= kSizeOfEarthquakeBatch) {
            [self addEarthquakesToList:self.currentParseBatch];
            
            [self.currentParseBatch removeAllObjects];
        }
    }
    else if ([elementName isEqualToString:kDescriptionElementContent]) {
        // end description, set the location of the earthquake
        if (self.seekDescription) {
            /*
             The description element contains the following format:
                "14km WNW of Anza, California"
             Extract just the location name
             */
            
            // search the entire string for "of ", and extract that last part of that string
            NSRange searchedRange = NSMakeRange(0, self.currentParsedCharacterData.length);
            NSRegularExpression *regExpression = [[NSRegularExpression alloc] initWithPattern:@"of " options:0 error:nil];
            NSTextCheckingResult *match = [regExpression firstMatchInString:self.currentParsedCharacterData options:0 range:searchedRange];
            NSInteger start = match.range.location + match.range.length;
            NSRange extractRange = NSMakeRange(start, self.currentParsedCharacterData.length - start);
            self.currentEarthquakeObject.location = [self.currentParsedCharacterData substringWithRange:extractRange];
            
            _seekDescription = NO;
        }
    }
    else if ([elementName isEqualToString:kValueKey]) {
        if (self.seekTime) {
            // end earthquake date/time
            self.currentEarthquakeObject.date = [self.dateFormatter dateFromString:self.currentParsedCharacterData];
            _seekTime = NO;
        }
        else if (self.seekLatitude) {
            // end earthquake latitude
            self.currentEarthquakeObject.latitude = [NSNumber numberWithDouble:self.currentParsedCharacterData.doubleValue];
            _seekLatitude = NO;
        }
        else if (self.seekLongitude) {
            // end earthquake longitude
            self.currentEarthquakeObject.longitude = [NSNumber numberWithDouble:self.currentParsedCharacterData.doubleValue];
            _seekLongitude = NO;
        }
        else if (self.seekMagnitude) {
            // end earthquake magnitude
            self.currentEarthquakeObject.magnitude = [NSNumber numberWithDouble:self.currentParsedCharacterData.floatValue];
            _seekMagnitude = NO;
        }
    }
    
    // Stop accumulating parsed character data. We won't start again until specific elements begin.
    _accumulatingParsedCharacterData = NO;
}

/**
 This method is called by the parser when it find parsed character data ("PCDATA") in an element. The parser is not guaranteed to deliver all of the parsed character data for an element in a single invocation, so it is necessary to accumulate character data until the end of the element is reached.
 */
- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string {

    if (self.accumulatingParsedCharacterData) {
        // If the current element is one whose content we care about, append 'string'
        // to the property that holds the content of the current element.
        //
        [self.currentParsedCharacterData appendString:string];
    }
}

/** 
 An error occurred while parsing the earthquake data: post the error as an NSNotification to our app delegate.
 */ 
- (void)handleEarthquakesError:(NSError *)parseError {

    assert([NSThread isMainThread]);
    [[NSNotificationCenter defaultCenter] postNotificationName:APLParseOperation.EarthquakesErrorNotificationName
                                                        object:self
                                                      userInfo:@{APLParseOperation.EarthquakesMessageErrorKey: parseError}];
}

/**
 An error occurred while parsing the earthquake data, pass the error to the main thread for handling.
 (Note: don't report an error if we aborted the parse due to a max limit of earthquakes.)
 */
- (void)parser:(NSXMLParser *)parser parseErrorOccurred:(NSError *)parseError {
     
    if (parseError.code != NSXMLParserDelegateAbortedParseError && !self.didAbortParsing) {
        [self performSelectorOnMainThread:@selector(handleEarthquakesError:) withObject:parseError waitUntilDone:NO];
    }
}

@end
